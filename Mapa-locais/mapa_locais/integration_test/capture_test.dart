import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapa_locais/firebase_options.dart';
import 'package:mapa_locais/main.dart';
import 'package:mapa_locais/screens/mapa_screen.dart';
import 'package:mapa_locais/services/local_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Capturas finais e layout móvel com rede real', (t) async {
    Future<void> capture(String name) async {
      final bytes = await binding.takeScreenshot(name);
      final dir = Directory(
        '/data/user/0/br.com.sage.mapa_locais/cache/senai-evidence',
      );
      await dir.create(recursive: true);
      await File('${dir.path}/$name.png').writeAsBytes(bytes);
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final session = await Session.iniciar();
    expect(session.admin, false, reason: 'Permissão temporária já removida.');
    await t.pumpWidget(
      MapaApp(
        home: MapaScreen(
          repository: LocalService(),
          session: session,
          account: () {},
        ),
      ),
    );
    Future<void> waitFor(Finder finder) async {
      for (var i = 0; i < 80 && finder.evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(finder, findsWidgets);
      await t.pump(const Duration(seconds: 1));
    }

    await waitFor(find.byKey(const Key('open-results')));
    await binding.convertFlutterSurfaceToImage();
    await Future<void>.delayed(const Duration(seconds: 12));
    await t.pump(const Duration(seconds: 1));
    await capture('01-mapa');
    await t.tap(find.byKey(const Key('open-results')));
    await waitFor(find.byKey(const Key('card-sp-03')));
    await capture('02-resultados');
    await t.tap(find.byKey(const Key('card-sp-03')));
    await waitFor(find.text('Sobre o local'));
    await capture('03-detalhes');
    await t.scrollUntilVisible(
      find.byKey(const Key('see-map')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await capture('03b-detalhes-acao');
    await t.tap(find.byKey(const Key('see-map')));
    await waitFor(find.text('Explore sua cidade'));
    expect(t.takeException(), isNull);
  });
}
