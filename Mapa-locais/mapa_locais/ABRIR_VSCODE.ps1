$ErrorActionPreference = 'Stop'
$taskFlutterRoot = Join-Path $PSScriptRoot '..\..\work\sdk\flutter'
$taskFlutterOnPath = Get-Command flutter -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath (Join-Path $taskFlutterRoot 'bin\flutter.bat')) {
    $taskFlutterRoot = (Resolve-Path -LiteralPath $taskFlutterRoot).Path
} elseif ($taskFlutterOnPath) {
    $taskFlutterRoot = Split-Path (Split-Path $taskFlutterOnPath.Source)
} else {
    throw 'Instale Flutter e adicione flutter/bin ao PATH. Consulte README.md.'
}
$taskCode = Get-Command code -ErrorAction SilentlyContinue
if (!$taskCode) { throw 'Instale o VS Code com a opção de adicionar ao PATH.' }
$taskEnvironment = @{}
$taskJavaRoot = Join-Path $PSScriptRoot '..\..\work\toolchains\jdk-21.0.12.1+1'
if (Test-Path -LiteralPath $taskJavaRoot) {
    $taskEnvironment['JAVA_HOME'] = (Resolve-Path -LiteralPath $taskJavaRoot).Path
}
# Caminhos desta máquina ficam somente no workspace local, ignorado pelo Git.
$taskWorkspace = @{
    folders = @(@{ path = '.' })
    settings = @{
        'dart.flutterSdkPath' = $taskFlutterRoot
        'dart.env' = $taskEnvironment
    }
}
$taskWorkspacePath = Join-Path $PSScriptRoot 'Mapa_Locais_LOCAL.code-workspace'
$taskWorkspace | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $taskWorkspacePath -Encoding utf8
& $taskCode.Source --new-window $taskWorkspacePath (Join-Path $PSScriptRoot 'lib\main.dart')
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível abrir o VS Code.' }
