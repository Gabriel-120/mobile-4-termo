import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/local.dart';

abstract class LocalRepository {
  Stream<List<Local>> listarLocais();
  Stream<Local?> observar(String id);
  Future<String> adicionar(Local local);
  Future<void> atualizar(Local local);
  Future<void> excluir(String id);
  Future<void> alterarFavorito(String id, bool value);
}

class LocalService implements LocalRepository {
  LocalService({FirebaseFirestore? firestore})
    : db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore db;
  CollectionReference<Map<String, dynamic>> get locais =>
      db.collection('locais');
  // Limite explícito para o catálogo didático; nunca fazer uma consulta ilimitada.
  @override
  Stream<List<Local>> listarLocais() => locais
      .orderBy('nome')
      .limit(200)
      .snapshots()
      .map((s) => s.docs.map((d) => Local.fromMap(d.id, d.data())).toList());
  @override
  Stream<Local?> observar(String id) => locais
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Local.fromMap(d.id, d.data()!) : null);
  @override
  Future<String> adicionar(Local local) async =>
      (await locais.add(local.toMap())).id;
  @override
  Future<void> atualizar(Local local) =>
      locais.doc(local.id).update(local.toMap());
  @override
  Future<void> excluir(String id) => locais.doc(id).delete();
  @override
  Future<void> alterarFavorito(String id, bool value) =>
      locais.doc(id).update({'favorito': value});
}

String mensagemErro(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Acesso negado. Confira a conta e as permissões.',
      'unavailable' || 'network-request-failed' =>
        'Sem conexão com o Firebase. Confira a internet e tente novamente.',
      'operation-not-allowed' =>
        'Este tipo de login ainda não foi habilitado no Firebase.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'E-mail ou senha incorretos.',
      'too-many-requests' => 'Muitas tentativas. Aguarde e tente novamente.',
      'not-found' => 'Este local não existe mais.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
  }
  return 'Não foi possível carregar os dados. Tente novamente.';
}

class Session {
  Session({required this.uid, required this.admin});
  final String uid;
  final bool admin;
  static Future<Session> iniciar() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    final role = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
    return Session(uid: user.uid, admin: role.exists);
  }
}
