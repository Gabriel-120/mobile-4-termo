# Guia rápido — executar o Mapa de Locais

Projeto Flutter/Dart com Firebase e OpenStreetMap. Para apresentar no navegador, não é necessário instalar o APK. É necessário ter internet para carregar o mapa e acessar o Firebase.

## 1. Abrir no VS Code neste PC

Abra o PowerShell e execute:

```powershell
cd 'C:\Users\Administrador\Desktop\tudo\Gabriel Gomes\mobile-4-termo\Mapa-locais'
.\ABRIR_VSCODE.ps1
```

O script abre o VS Code e encontra o Flutter instalado para este projeto. Os atalhos desta cópia usam o Flutter da pasta original em Documents\Codex. Preserve essa pasta de ferramentas. Em outro PC, instale Flutter e siga a seção 5.

## 2. Rodar pelo VS Code

1. Se aparecer **Restricted Mode**, clique em **Manage** e confirme a confiança na pasta do projeto, se concordar. Neste PC, esse passo já foi realizado.
2. Abra **Executar e Depurar** com **Ctrl+Shift+D**.
3. Selecione **Mapa de Locais — Chrome**.
4. Pressione **F5** e aguarde o Chrome abrir o aplicativo.
5. Para parar, pressione **Shift+F5** no VS Code.

O app usa a porta local **7357**. Deixe apenas uma execução usando essa porta.

Para alterar o app, edite os arquivos em `lib/` e salve. Para aplicar alterações durante a execução, use **Flutter: Hot Reload** na paleta de comandos (**Ctrl+Shift+P**). Se necessário, reinicie a sessão com **Ctrl+Shift+F5**.

## 3. Alternativa: rodar pelo terminal neste PC

Na pasta `Mapa-locais` desta cópia, execute:

```powershell
.\EXECUTAR.ps1 -d chrome --web-port 7357
```

Esse script encontra as ferramentas e obtém as dependências antes de iniciar. No terminal em que o app está rodando:

- **r**: aplicar alterações com hot reload.
- **R**: reiniciar o app com hot restart.
- **q**: encerrar a execução.

## 4. Rodar no Android pelo VS Code

1. Abra um emulador Android pelo Android Studio, ou conecte um aparelho com depuração USB habilitada.
2. No VS Code, escolha esse dispositivo na barra inferior.
3. Selecione **Mapa de Locais — Android** em Executar e Depurar.
4. Pressione **F5**. O Flutter compila e instala a versão de desenvolvimento automaticamente.

O Android Studio fornece o emulador; o código continua sendo editado no VS Code.

## 5. Executar em outro PC

1. Extraia o ZIP do projeto.
2. Instale Flutter e configure `flutter/bin` no PATH. Instale VS Code, Chrome e as extensões **Dart** e **Flutter**. Para Android, instale também Android SDK e JDK compatível; neste projeto foi usado JDK 21.
3. No VS Code, abra a pasta **mapa_locais**, que contém `pubspec.yaml`.
4. Abra um terminal nessa pasta e execute:

```powershell
flutter --version
flutter doctor -v
flutter pub get
flutter run -d chrome --web-port 7357
```

Também é possível executar pelo F5, como na seção 2. Para Chrome, avisos do `flutter doctor` sobre ferramentas Android ou Windows não impedem a execução web.

A configuração Firebase já acompanha o código. Para usar o projeto existente, não é necessário repetir `firebase login` ou `flutterfire configure`. Essas ferramentas são usadas ao administrar ou reconfigurar o Firebase.

## 6. Cadastro, edição e exclusão

O app abre como visitante autenticado: permite consultar locais e favoritar. Para demonstrar cadastro, edição e exclusão:

1. Abra **Conta** no app e copie o UID da sessão.
2. O proprietário do projeto deve abrir o [Console Firestore](https://console.firebase.google.com/project/sage-mapa-senai-20261013/firestore).
3. Na coleção `admins`, crie um documento com esse UID como ID e o campo `role`, do tipo **String**, com valor `admin`.
4. Volte ao app, abra **Conta** e selecione **Atualizar permissões**.

Chrome e Android podem ter UIDs diferentes. Ao terminar a apresentação, o proprietário pode remover o documento de `admins` para revogar o acesso. Mantenha o plano gratuito Spark.

## Se algo não abrir

- **Flutter não encontrado:** no VS Code, use **Flutter: Change SDK** para selecionar o SDK, ou configure `flutter/bin` no PATH. Neste PC, prefira `ABRIR_VSCODE.ps1`.
- **Porta 7357 ocupada:** encerre a execução anterior com Shift+F5 ou `q` no terminal correspondente.
- **Dependências ausentes:** execute `flutter pub get`; neste PC, `EXECUTAR.ps1` já faz isso.
- **Mapa ou dados não carregam:** confira a internet e a mensagem exibida pelo app.
- **Botões de CRUD indisponíveis:** confira a permissão do UID, conforme a seção 6.

Use a execução Flutter. **Live Server, Code Runner e `dart lib/main.dart` não iniciam este aplicativo.**

