import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapa_locais/firebase_options.dart';
import 'package:mapa_locais/main.dart';
import 'package:mapa_locais/models/local.dart';
import 'package:mapa_locais/models/catalogo.dart';
import 'package:mapa_locais/services/local_service.dart';
import 'package:mapa_locais/screens/mapa_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('T01-T11: avaliação com Firebase real e navegação Android', (
    t,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final user =
        FirebaseAuth.instance.currentUser ??
        (await FirebaseAuth.instance.signInAnonymously()).user!;
    debugPrint('ADMIN_UID:${user.uid}');
    final db = FirebaseFirestore.instance;
    bool admin = false;
    for (var attempt = 0; attempt < 60; attempt++) {
      admin =
          (await db
                  .collection('admins')
                  .doc(user.uid)
                  .get(const GetOptions(source: Source.server)))
              .exists;
      if (admin) break;
      await Future<void>.delayed(const Duration(seconds: 3));
    }
    expect(
      admin,
      true,
      reason: 'O responsável deve conceder o papel pelo Console ou tool/cloud-admin.cjs.',
    );
    final service = LocalService();
    final snapshot = await db
        .collection('locais')
        .limit(200)
        .get(const GetOptions(source: Source.server));
    final data = snapshot.docs
        .map((d) => Local.fromMap(d.id, d.data()))
        .toList();
    expect(data.length, greaterThanOrEqualTo(18));
    debugPrint('PASS T01: leitura de servidor ${data.length} documentos');
    expect(
      filtrarLocais(data, texto: 'Academia').length,
      greaterThanOrEqualTo(9),
    );
    debugPrint('PASS T02: pesquisa Academia');
    expect(filtrarLocais(data, cidade: 'Campinas').length, 6);
    debugPrint('PASS T03: Campinas');
    expect(
      filtrarLocais(data, cidade: 'Campinas', categoria: 'Academia').length,
      3,
    );
    debugPrint('PASS T04: categoria');
    final original = data.first;
    final testLocal = Local.fromMap('', {
      ...original.toMap(),
      'nome': 'TESTE AUTORIZADO SENAI ${DateTime.now().millisecondsSinceEpoch}',
      'favorito': false,
    });
    String? created;
    try {
      created = await service.adicionar(testLocal);
      final ref = db.collection('locais').doc(created);
      expect(
        (await ref.get(const GetOptions(source: Source.server)))
            .data()!['nome'],
        testLocal.nome,
      );
      debugPrint('PASS T05: create servidor');
      expect((await LocalService().observar(created).first)?.id, created);
      debugPrint('PASS T06: nova assinatura lê registro');
      final edited = Local.fromMap(created, {
        ...testLocal.toMap(),
        'nome': 'TESTE EDITADO SENAI',
        'horario': '10:00 - 20:00',
      });
      await service.atualizar(edited);
      expect(
        (await ref.get(const GetOptions(source: Source.server)))
            .data()!['horario'],
        '10:00 - 20:00',
      );
      debugPrint('PASS T07: update servidor');
      await service.alterarFavorito(created, true);
      expect(
        (await ref.get(const GetOptions(source: Source.server)))
            .data()!['favorito'],
        true,
      );
      await service.alterarFavorito(created, false);
      expect(
        (await ref.get(const GetOptions(source: Source.server)))
            .data()!['favorito'],
        false,
      );
      debugPrint('PASS T09: favorito verdadeiro e falso no servidor');
      await service.excluir(created);
      expect(
        (await ref.get(const GetOptions(source: Source.server))).exists,
        false,
      );
      created = null;
      debugPrint('PASS T08: exclusão servidor');
    } finally {
      if (created != null) await service.excluir(created);
    }
    await t.pumpWidget(
      MapaApp(
        home: MapaScreen(
          repository: service,
          session: Session(uid: user.uid, admin: true),
          account: () {},
        ),
      ),
    );
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(finder, findsWidgets);
      await t.pump(const Duration(milliseconds: 800));
    }

    await waitFor(find.byKey(const Key('open-results')));
    await binding.convertFlutterSurfaceToImage();
    await t.pump(const Duration(seconds: 3));
    await binding.takeScreenshot('01-mapa');
    await t.tap(find.byKey(const Key('open-results')));
    await waitFor(find.byKey(const Key('card-sp-03')));
    await binding.takeScreenshot('02-resultados');
    await t.enterText(find.byKey(const Key('results-search')), 'Academia');
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('3 locais'), findsOneWidget);
    await t.enterText(
      find.byKey(const Key('results-search')),
      'zzzzsemresultado',
    );
    await waitFor(find.text('Nenhum local encontrado.'));
    debugPrint(
      'PASS T11: ausência de dados na interface; erro coberto por widget test',
    );
    await t.enterText(find.byKey(const Key('results-search')), '');
    await waitFor(find.byKey(const Key('card-sp-03')));
    await t.tap(find.byKey(const Key('card-sp-03')));
    await waitFor(find.text('Sobre o local'));
    await binding.takeScreenshot('03-detalhes');
    await t.scrollUntilVisible(
      find.byKey(const Key('see-map')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await t.tap(find.byKey(const Key('see-map')));
    await waitFor(find.text('Explore sua cidade'));
    debugPrint('PASS T10: mapa, resultados, detalhes, retorno com foco');
  }, timeout: const Timeout(Duration(minutes: 8)));
}
