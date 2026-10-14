# Mapa de Locais — SENAI

Aplicação Flutter/Dart da avaliação `Avaliacao_Tutorial_Flutter_Firebase_Mapa.pdf`: mapa OpenStreetMap, busca, filtros, CRUD e favoritos em Cloud Firestore. Três telas principais: mapa, resultados e detalhes. Cadastro, edição e autenticação aparecem em diálogos.

## Estado verificável

RF01–RF10 implementados e T01–T11 aprovados no conjunto de testes Android/Firebase real e interface isolada. Catálogo com 18 locais didáticos, seis por cidade; mapa OpenStreetMap real validado no APK release. Consulte `docs/ENTREGA.md` para evidências e escopo preciso dos testes.

## Abrir e executar no VS Code

O projeto fonte já é Flutter/Dart, com a estrutura `lib/main.dart`, `lib/models/`, `lib/screens/`, `lib/services/`, `lib/widgets/`, `test/` e `pubspec.yaml`. O APK entregue é apenas uma compilação adicional; você pode desenvolver e apresentar diretamente pelo VS Code.

Neste PC, execute `./ABRIR_VSCODE.ps1` no PowerShell. Ele abre o código no VS Code e configura o SDK somente para este projeto, sem alterar suas configurações globais. As extensões Dart e Flutter já estão instaladas. O workspace `Mapa_Locais_LOCAL.code-workspace` é gerado com caminhos locais e não vai para o Git.

1. No VS Code, abra **Executar e Depurar** (`Ctrl+Shift+D`).
2. Selecione **Mapa de Locais — Chrome** e pressione **F5**. O navegador executa o código Dart com Firebase e mapa real; não exige instalação de APK. A porta local é 7357.
3. Para Android, selecione **Mapa de Locais — Android**, escolha o emulador/aparelho na barra inferior e pressione **F5**. Salvar alterações permite hot reload. Android compila uma versão de desenvolvimento automaticamente.
4. Use **Shift+F5** para encerrar a sessão.

Não execute `dart lib/main.dart` nem use Live Server/Code Runner: este código depende do Flutter. Não é necessário refazer o login da Firebase CLI para executar o app com a configuração já presente. O acesso ao CRUD segue as permissões documentadas em `docs/ENTREGA.md`.

### Levar ao PC do SENAI

1. Copie/clone este projeto para uma pasta sua. Instale Flutter stable, JDK 21 e Android SDK pelas fontes oficiais.
2. Execute `flutter pub get` e `flutter doctor -v`.
3. Instale as CLIs: `npm install -g firebase-tools` e `dart pub global activate flutterfire_cli`.
4. Faça `firebase login` com uma conta autorizada. Nunca compartilhe códigos, tokens ou senhas.
5. Execute `flutterfire configure --project=ID_DO_PROJETO --platforms=android,web` para gerar a configuração real. Não invente valores em `firebase_options.dart`.
6. Abra a pasta que contém `pubspec.yaml` no VS Code, instale as extensões Dart/Flutter e use as opções de F5 acima. Se o SDK não estiver no PATH, use **Flutter: Change SDK** para selecioná-lo. Também é possível usar `flutter run -d chrome` ou `flutter run` no terminal.

No PC desta sessão, `EXECUTAR.ps1` encontra o Flutter/JDK local automaticamente. No celular de apresentação, consulte a seção “Preparação do celular para demonstrar CRUD” em `docs/ENTREGA.md`: o proprietário precisa liberar o UID do aparelho; visitantes não recebem acesso administrativo automaticamente.

Não há Google Maps, cartão, Firebase Storage ou Functions. Mantenha Spark; não ative faturamento. O mapa exige internet e obedece à política de tiles OSM. Favoritos seguem o campo global `favorito` solicitado pelo exercício.

## Segurança e custos

CRUD reservado a administradores cadastrados em `admins/{uid}` por ferramenta administrativa confiável. Clientes não podem conceder a si próprios esse papel. Leitura e favorito exigem autenticação; leitores só podem modificar o campo booleano `favorito`. As regras validam campos e faixas. Login é feito em um diálogo.

Dados de demonstração são didáticos: horários, avaliações e distâncias não são informações comerciais atualizadas nem localização GPS. Não use essas informações para decidir visitas.

## Validação

`flutter analyze`, `flutter test`, testes das regras com Firebase Emulator e roteiro T01–T11. Detalhes em `docs/ENTREGA.md`.

## Referências

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/firestore/security/rules-conditions
- https://operations.osmfoundation.org/policies/tiles/
- https://docs.flutter.dev/install/manual
