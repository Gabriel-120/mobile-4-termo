import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapa_locais/main.dart';
import 'package:mapa_locais/models/catalogo.dart';
import 'package:mapa_locais/screens/mapa_screen.dart';
import 'package:mapa_locais/screens/resultados_screen.dart';
import 'package:mapa_locais/screens/detalhes_screen.dart';
import 'package:mapa_locais/services/local_service.dart';
import 'package:mapa_locais/widgets/local_form.dart';

import 'support.dart';

void main() {
  testWidgets(
    'T05-T08 interface: cadastrar, reabrir, editar e confirmar exclusão',
    (t) async {
      final r = TestRepository();
      addTearDown(r.close);
      Future<void> showResults() async {
        await t.pumpWidget(
          MapaApp(
            home: ResultadosScreen(
              repository: r,
              admin: true,
              cidade: 'São Paulo',
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      Future<void> input(String key, String value) async {
        final field = find.byKey(Key('field-$key'));
        await t.ensureVisible(field);
        await t.enterText(field, value);
        await t.pump();
      }

      await showResults();
      await t.tap(find.byKey(const Key('create-local')));
      await t.pumpAndSettle();
      await input('nome', 'AAA Academia Teste SENAI');
      await input('endereco', 'Endereço didático');
      await input('horario', '09:00 - 18:00');
      await input('avaliacao', '6');
      await input('descricao', 'Registro temporário de teste.');
      await t.tap(find.byKey(const Key('save-local')));
      await t.pumpAndSettle();
      expect(r.data.length, 18);
      expect(find.text('Informe um número entre 0.0 e 5.0.'), findsOneWidget);
      await input('avaliacao', '4,5');
      await t.tap(find.byKey(const Key('save-local')));
      await t.pumpAndSettle();
      expect(r.data.length, 19);
      final created = r.data.last.id;
      await t.pumpWidget(const SizedBox());
      await t.pump();
      await showResults();
      expect(find.text('AAA Academia Teste SENAI'), findsOneWidget);
      await t.tap(find.byTooltip('Ações de AAA Academia Teste SENAI'));
      await t.pumpAndSettle();
      await t.tap(find.text('Editar'));
      await t.pumpAndSettle();
      await input('nome', 'AAA Academia Editada SENAI');
      await t.tap(find.byKey(const Key('save-local')));
      await t.pumpAndSettle();
      expect(
        r.data.firstWhere((l) => l.id == created).nome,
        'AAA Academia Editada SENAI',
      );
      await t.tap(find.byTooltip('Ações de AAA Academia Editada SENAI'));
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(r.data.length, 19);
      await t.tap(find.byTooltip('Ações de AAA Academia Editada SENAI'));
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('confirm-delete')));
      await t.pumpAndSettle();
      expect(r.data.length, 18);
      expect(find.text('AAA Academia Editada SENAI'), findsNothing);
    },
  );
  test('Catálogo: 18 locais, 6 por cidade e todos os campos preservados', () {
    final data = fixture();
    expect(data.length, 18);
    for (final c in cidades) {
      expect(filtrarLocais(data, cidade: c).length, 6);
    }
    expect(data.first.toMap()['favorito'], false);
    expect(data.first.latitude, inInclusiveRange(-90, 90));
  });
  test('T02 lógica: busca sem acentos por nome ou categoria', () {
    expect(filtrarLocais(fixture(), texto: 'ACADEMIA').length, 9);
    expect(filtrarLocais(fixture(), texto: '  horizonte ').length, 3);
    expect(filtrarLocais(fixture(), texto: 'jundiai').length, 6);
  });
  test('T03/T04 lógica: combinação de cidade, categoria e favoritos', () {
    expect(
      filtrarLocais(
        fixture(),
        cidade: 'Campinas',
        categoria: 'Academia',
      ).length,
      3,
    );
    expect(filtrarLocais(fixture(), favoritos: true), isEmpty);
  });
  testWidgets('T01 interface: mapa recebe dados e mostra 6 marcadores', (
    t,
  ) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: MapaScreen(
          repository: r,
          session: Session(uid: 'test', admin: true),
          account: () {},
          tiles: false,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('6 locais em São Paulo'), findsOneWidget);
    expect(find.byTooltip('Academia Horizonte — São Paulo'), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
  });
  testWidgets('T02 interface: pesquisar Academia', (t) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: ResultadosScreen(repository: r, admin: true, cidade: 'Todas'),
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('results-search')), 'Academia');
    await t.pumpAndSettle();
    expect(find.text('9 locais'), findsOneWidget);
  });
  testWidgets('T03 interface: selecionar Campinas', (t) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: ResultadosScreen(repository: r, admin: true, cidade: 'São Paulo'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('results-city')));
    await t.pumpAndSettle();
    await t.tap(find.text('Campinas').last);
    await t.pumpAndSettle();
    expect(find.text('6 locais'), findsOneWidget);
  });
  testWidgets('T04 interface: filtrar categoria', (t) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: ResultadosScreen(repository: r, admin: true, cidade: 'Campinas'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('results-category')));
    await t.pumpAndSettle();
    await t.tap(find.text('Academia').last);
    await t.pumpAndSettle();
    expect(find.text('3 locais'), findsOneWidget);
  });
  testWidgets('T05: validação impede cadastro incompleto e fora da faixa', (
    t,
  ) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => showLocalForm(c, r),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Abrir'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('save-local')));
    await t.pumpAndSettle();
    expect(find.text('Preencha este campo.'), findsWidgets);
    expect(r.data.length, 18);
  });
  testWidgets('T09: favorito muda e desmuda na tela de detalhes', (t) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: DetalhesScreen(repository: r, id: 'sp-01'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('favorite')));
    await t.pumpAndSettle();
    expect(r.data.first.favorito, true);
    await t.tap(find.byKey(const Key('favorite')));
    await t.pumpAndSettle();
    expect(r.data.first.favorito, false);
  });
  testWidgets('T10: mapa, resultados, detalhes e Ver no mapa', (t) async {
    final r = TestRepository();
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: MapaScreen(
          repository: r,
          session: Session(uid: 'test', admin: true),
          account: () {},
          tiles: false,
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('open-results')));
    await t.pumpAndSettle();
    expect(find.text('Resultados'), findsOneWidget);
    await t.tap(find.byKey(const Key('card-sp-03')));
    await t.pumpAndSettle();
    expect(find.text('Detalhes'), findsOneWidget);
    await t.scrollUntilVisible(
      find.byKey(const Key('see-map')),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await t.tap(find.byKey(const Key('see-map')));
    await t.pumpAndSettle();
    expect(find.text('Explore sua cidade'), findsOneWidget);
  });
  testWidgets('T11: ausência de dados e erro exibem mensagens', (t) async {
    final r = TestRepository([]);
    addTearDown(r.close);
    await t.pumpWidget(
      MapaApp(
        home: ResultadosScreen(repository: r, admin: false, cidade: 'Todas'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Nenhum local encontrado.'), findsOneWidget);
    final e = TestRepository()..error = Exception('simulado');
    addTearDown(e.close);
    await t.pumpWidget(
      MapaApp(
        home: ResultadosScreen(
          key: const Key('error'),
          repository: e,
          admin: false,
          cidade: 'Todas',
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar os dados. Tente novamente.'),
      findsOneWidget,
    );
  });
}
