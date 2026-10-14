// Valida as regras PUBLICADAS usando Firebase Client SDK. Tokens somente em memória.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase/app');
const {getAuth,signInAnonymously,deleteUser}=require('firebase/auth');
const {getFirestore,doc,setDoc,getDocFromServer,updateDoc,deleteDoc,terminate}=require('firebase/firestore');
const cliRoot=process.env.FIREBASE_CLI_ROOT;
const {configstore}=require(path.join(cliRoot,'lib/configstore'));
const cliAuth=require(path.join(cliRoot,'lib/auth'));
const android=JSON.parse(fs.readFileSync('android/app/google-services.json','utf8'));
const project=android.project_info.project_id;
const config={apiKey:android.client[0].api_key[0].current_key,projectId:project,appId:android.client[0].client_info.mobilesdk_app_id};
const base=`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
async function trusted(method,uid) {
  const token=await cliAuth.getAccessToken(configstore.get('tokens').refresh_token,['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
  const r=await fetch(`${base}/admins/${uid}`,{method,headers:{Authorization:`Bearer ${token.access_token}`,'Content-Type':'application/json'},body:method==='PATCH'?JSON.stringify({fields:{role:{stringValue:'admin'}}}):undefined});
  if(!r.ok) throw Error(`Falha administrativa ${r.status}`);
}
async function denied(operation) { await assert.rejects(operation,e=>e.code==='permission-denied'); }
async function main() {
  const adminApp=initializeApp(config,'live-admin'),readerApp=initializeApp(config,'live-reader');
  const adminAuth=getAuth(adminApp),readerAuth=getAuth(readerApp);
  const admin=(await signInAnonymously(adminAuth)).user;
  const reader=(await signInAnonymously(readerAuth)).user;
  const db=getFirestore(adminApp),rdb=getFirestore(readerApp);
  const testId=`assessment-live-${Date.now()}`,ref=doc(db,'locais',testId),readerRef=doc(rdb,'locais',testId);
  const {id,...local}=JSON.parse(fs.readFileSync('tool/seed.json','utf8'))[0];
  try {
    await trusted('PATCH',admin.uid);
    await setDoc(ref,{...local,nome:'TESTE TEMPORÁRIO REGRAS PUBLICADAS'});
    assert.equal((await getDocFromServer(readerRef)).data().favorito,false);
    await denied(()=>setDoc(doc(rdb,'locais',`${testId}-denied`),local));
    await denied(()=>updateDoc(readerRef,{nome:'invasor'}));
    await denied(()=>deleteDoc(readerRef));
    await denied(()=>setDoc(doc(rdb,'admins',reader.uid),{role:'admin'}));
    await updateDoc(readerRef,{favorito:true}); assert.equal((await getDocFromServer(ref)).data().favorito,true);
    await updateDoc(readerRef,{favorito:false}); assert.equal((await getDocFromServer(ref)).data().favorito,false);
    fs.writeFileSync('docs/evidence/live-rules.json',JSON.stringify({project,checkedAt:new Date().toISOString(),status:'passed',checks:['leitura autenticada','CRUD administrativo','CRUD negado a leitor','autopromoção negada','favorito true/false'],temporaryDocument:testId,cleanup:'documento e contas temporárias removidos ao terminar'},null,2));
    console.log('Regras publicadas: leitura e favorito permitidos; CRUD de leitor e autopromoção recusados.');
  } finally {
    await deleteDoc(ref); await trusted('DELETE',admin.uid);
    await deleteUser(admin); await deleteUser(reader); await terminate(db); await terminate(rdb); await deleteApp(adminApp); await deleteApp(readerApp);
  }
}
main().catch(e=>{console.error(e.code ?? e.message);process.exitCode=1;});
