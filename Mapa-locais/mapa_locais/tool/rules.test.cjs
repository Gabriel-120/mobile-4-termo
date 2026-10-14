const {test,before,after,beforeEach} = require('node:test');
const fs = require('node:fs');
const {initializeTestEnvironment,assertFails,assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc,setDoc,getDoc,getDocs,collection,updateDoc,deleteDoc} = require('firebase/firestore');
let env;
const {id,...valid} = JSON.parse(fs.readFileSync('tool/seed.json','utf8'))[0];
before(async()=> { env=await initializeTestEnvironment({projectId:'demo-mapa-senai',firestore:{host:'127.0.0.1',port:8180,rules:fs.readFileSync('firestore.rules','utf8')}}); });
after(async()=>{await env?.cleanup();});
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c=>{await setDoc(doc(c.firestore(),'admins','administrator'),{role:'admin'});await setDoc(doc(c.firestore(),'locais','seed'),valid);});
});
const admin=()=>env.authenticatedContext('administrator').firestore();
const reader=()=>env.authenticatedContext('reader').firestore();
test('sem autenticação: leitura e escrita negadas',async()=>{const db=env.unauthenticatedContext().firestore();await assertFails(getDoc(doc(db,'locais','seed')));await assertFails(setDoc(doc(db,'locais','x'),valid));});
test('leitor autenticado: leitura e favorito permitidos',async()=>{const db=reader();await assertSucceeds(getDoc(doc(db,'locais','seed')));await assertSucceeds(updateDoc(doc(db,'locais','seed'),{favorito:true}));await assertSucceeds(updateDoc(doc(db,'locais','seed'),{favorito:false}));});
test('leitor: CRUD e modificação combinada negados',async()=>{const db=reader();await assertFails(setDoc(doc(db,'locais','x'),valid));await assertFails(updateDoc(doc(db,'locais','seed'),{nome:'intruso'}));await assertFails(updateDoc(doc(db,'locais','seed'),{favorito:true,cidade:'Campinas'}));await assertFails(deleteDoc(doc(db,'locais','seed')));});
test('administrador: create read update delete permitidos',async()=>{const db=admin(),ref=doc(db,'locais','new');await assertSucceeds(setDoc(ref,valid));await assertSucceeds(getDoc(ref));await assertSucceeds(updateDoc(ref,{nome:'Academia editada'}));await assertSucceeds(deleteDoc(ref));});
test('nenhum cliente pode escalar papel ou listar administradores',async()=>{for(const db of [reader(),admin()]){await assertFails(setDoc(doc(db,'admins','reader'),{role:'admin'}));await assertFails(getDocs(collection(db,'admins')));}await assertSucceeds(getDoc(doc(reader(),'admins','reader')));});
for(const [name,change] of Object.entries({nomeVazio:{nome:''},campoExtra:{secret:'x'},cidadeInvalida:{cidade:'Rio'},categoriaInvalida:{categoria:'Outro'},avaliacaoAlta:{avaliacao:6},avaliacaoTexto:{avaliacao:'5'},distanciaNegativa:{distancia:-1},favoritoTexto:{favorito:'true'},latitudeAlta:{latitude:91},longitudeAlta:{longitude:181},descricaoLonga:{descricao:'x'.repeat(2001)},horarioVazio:{horario:''}})) {
  test(`validação: rejeita ${name}`,async()=>{await assertFails(setDoc(doc(admin(),'locais','bad'),{...valid,...change}));});
}
test('validação: campos obrigatórios e coleção desconhecida negados',async()=>{const db=admin(),bad={...valid};delete bad.latitude;await assertFails(setDoc(doc(db,'locais','bad'),bad));await assertFails(setDoc(doc(db,'other','bad'),valid));});
