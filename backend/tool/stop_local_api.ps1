$ErrorActionPreference = 'Stop'

$statePath = Join-Path $env:TEMP 'al_toque_local_api.json'
if (-not (Test-Path -LiteralPath $statePath)) {
    exit 0
}

$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$processId = [int]$state.processId
$processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $processId"
if ($null -ne $processInfo) {
    if ($processInfo.ExecutablePath -ne $state.executable) {
        throw 'El PID guardado ahora corresponde a otro proceso; no se detuvo.'
    }
    Stop-Process -Id $processId
}

Remove-Item -LiteralPath $statePath
foreach ($logPath in @($state.stdoutPath, $state.stderrPath)) {
    if (Test-Path -LiteralPath $logPath) {
        Remove-Item -LiteralPath $logPath
    }
}
