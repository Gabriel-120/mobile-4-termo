// Executar somente no PC do responsável, após firebase login. Nunca empacotar tokens.
const fs = require('node:fs');
const path = require('node:path');
const cliRoot = process.env.FIREBASE_CLI_ROOT;
if (!cliRoot) throw Error('Defina FIREBASE_CLI_ROOT para a pasta instalada de firebase-tools.');
const { configstore } = require(path.join(cliRoot, 'lib/configstore'));
const auth = require(path.join(cliRoot, 'lib/auth'));
const project = 'sage-mapa-senai-20261013';
async function api(url, method = 'GET', body) {
  const tokens = await auth.getAccessToken(configstore.get('tokens').refresh_token, ['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
  const response = await fetch(url, {method, headers:{Authorization:`Bearer ${tokens.access_token}`, 'Content-Type':'application/json'}, body:body ? JSON.stringify(body) : undefined});
  const data = await response.json();
  if (!response.ok) throw Error(`${response.status}: ${data.error?.message ?? 'Falha na API'}`);
  return data;
}
const base = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
function value(v) { return typeof v === 'boolean' ? {booleanValue:v} : typeof v === 'number' ? {doubleValue:v} : {stringValue:v}; }
function fields(data) { return Object.fromEntries(Object.entries(data).map(([k,v]) => [k,value(v)])); }
async function main() {
  const command = process.argv[2];
  if (command === 'setup-apis') {
    await api(`https://serviceusage.googleapis.com/v1/projects/180355769764/services:batchEnable`, 'POST', {serviceIds:['firestore.googleapis.com','identitytoolkit.googleapis.com']});
    console.log('Ativação das APIs Firestore e Authentication solicitada.');
  } else if (command === 'setup-auth') {
    await api(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config?updateMask=signIn.anonymous.enabled,signIn.email.enabled,signIn.email.passwordRequired`, 'PATCH', {signIn:{anonymous:{enabled:true},email:{enabled:true,passwordRequired:true}}});
    console.log('Login anônimo e e-mail/senha habilitados.');
  } else if (command === 'seed') {
    const rows = JSON.parse(fs.readFileSync(path.join(__dirname,'seed.json'),'utf8'));
    for (const {id,...data} of rows) {
      try {
        await api(`${base}/locais?documentId=${id}`, 'POST', {fields:fields(data)});
      } catch(e) { if (!e.message.startsWith('409:')) throw e; }
    }
    console.log(`${rows.length} locais preparados; documentos existentes preservados.`);
  } else if (command === 'grant-admin') {
    const uid = process.argv[3];
    if (!uid || !/^[a-zA-Z0-9_-]{1,128}$/.test(uid)) throw Error('UID inválido.');
    await api(`${base}/admins/${uid}`, 'PATCH', {fields:fields({role:'admin'})});
    console.log('Permissão de administrador aplicada ao UID informado.');
  } else if (command === 'revoke-admin') {
    const uid = process.argv[3];
    if (!uid || !/^[a-zA-Z0-9_-]{1,128}$/.test(uid)) throw Error('UID inválido.');
    await api(`${base}/admins/${uid}`, 'DELETE');
    console.log('Permissão administrativa removida do UID informado.');
  } else if (command === 'audit') {
    const data = await api(`https://firebase.googleapis.com/v1beta1/projects/${project}`);
    const billing = await api(`https://cloudbilling.googleapis.com/v1/projects/${project}/billingInfo`);
    const db = await api(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)`);
    const documents = await api(`${base}/locais?pageSize=200`);
    const evidence = {project:data.projectId,billingEnabled:billing.billingEnabled,location:db.locationId,count:documents.documents?.length ?? 0,documents:documents.documents?.map(d=>({id:d.name.split('/').pop(),nome:d.fields.nome.stringValue,cidade:d.fields.cidade.stringValue})),checkedAt:new Date().toISOString()};
    fs.mkdirSync(path.join(__dirname,'../docs/evidence'),{recursive:true});
    fs.writeFileSync(path.join(__dirname,'../docs/evidence/cloud-audit.json'),JSON.stringify(evidence,null,2));
    console.log(JSON.stringify({project:evidence.project,billingEnabled:evidence.billingEnabled,count:evidence.count,location:evidence.location}));
  } else throw Error('Use setup-auth | seed | grant-admin UID | audit.');
}
main().catch(e=>{ console.error(e.message); process.exitCode=1; });
