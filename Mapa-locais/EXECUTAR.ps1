$ErrorActionPreference = 'Stop'
$taskProject = Join-Path $PSScriptRoot 'mapa_locais'
$taskWorkspacePath = Join-Path $taskProject 'Mapa_Locais_LOCAL.code-workspace'
if (Test-Path -LiteralPath $taskWorkspacePath) {
    $taskLocal = Get-Content -LiteralPath $taskWorkspacePath -Raw | ConvertFrom-Json
    $taskSdk = $taskLocal.settings.'dart.flutterSdkPath'
    if (Test-Path -LiteralPath (Join-Path $taskSdk 'bin\flutter.bat')) {
        $env:PATH = (Join-Path $taskSdk 'bin') + ';' + $env:PATH
        if ($taskLocal.settings.'dart.env'.JAVA_HOME) {
            $env:JAVA_HOME = $taskLocal.settings.'dart.env'.JAVA_HOME
        }
    }
}
& (Join-Path $taskProject 'EXECUTAR.ps1') @args
