$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$localFlutter = Join-Path $PSScriptRoot '..\..\work\sdk\flutter\bin\flutter.bat'
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCommand) { $taskFlutter = $flutterCommand.Source }
elseif (Test-Path -LiteralPath $localFlutter) { $taskFlutter = (Resolve-Path -LiteralPath $localFlutter).Path }
else { throw 'Instale Flutter e adicione flutter/bin ao PATH. Veja README.md.' }
$localJava = Join-Path $PSScriptRoot '..\..\work\toolchains\jdk-21.0.12.1+1'
if (Test-Path -LiteralPath $localJava) { $env:JAVA_HOME = (Resolve-Path -LiteralPath $localJava).Path }
$taskTempPath = Join-Path $env:LOCALAPPDATA 'Temp\mapa-senai-java'
New-Item -ItemType Directory -Force -Path $taskTempPath | Out-Null
$env:JAVA_TOOL_OPTIONS = ('-Djdk.net.unixdomain.tmpdir="' + $taskTempPath + '"')
& $taskFlutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Falha ao obter dependências.' }
& $taskFlutter run @args
