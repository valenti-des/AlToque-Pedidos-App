$ErrorActionPreference = 'Stop'
$server = $null
$statePath = Join-Path $env:TEMP 'al_toque_local_api.json'

try {
    $healthUri = 'http://127.0.0.1:8080/health'
    $stdoutPath = Join-Path $env:TEMP 'al_toque_local_api.stdout.log'
    $stderrPath = Join-Path $env:TEMP 'al_toque_local_api.stderr.log'

    $client = New-Object System.Net.Sockets.TcpClient
    $apiAlreadyListening = $false
    try {
        $connection = $client.BeginConnect('127.0.0.1', 8080, $null, $null)
        if ($connection.AsyncWaitHandle.WaitOne(2000)) {
            $client.EndConnect($connection)
            $apiAlreadyListening = $true
        }
    }
    catch [System.Net.Sockets.SocketException] {
    }
    finally {
        $client.Dispose()
    }

    if ($apiAlreadyListening) {
        $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 5
        if ($health.status -ne 'ok') {
            throw 'El puerto 8080 ya esta ocupado por una API que no pudo validar MySQL.'
        }
        Write-Output 'La API local ya esta conectada con MySQL.'
        exit 0
    }

    $flutterCommand = Get-Command flutter -ErrorAction Stop
    $flutterBin = Split-Path -Parent $flutterCommand.Source
    $flutterRoot = Split-Path -Parent $flutterBin
    $dartExe = Join-Path $flutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
    if (-not (Test-Path -LiteralPath $dartExe)) {
        throw "No se encontro el ejecutable Dart del SDK Flutter en $dartExe."
    }

    $random = [Security.Cryptography.RandomNumberGenerator]::Create()
    $secretBytes = New-Object byte[] 32
    $random.GetBytes($secretBytes)
    $env:API_TOKEN_SECRET = [Convert]::ToBase64String($secretBytes)
    $random.Dispose()

    $env:DB_HOST = '127.0.0.1'
    $env:DB_PORT = '3306'
    $env:DB_NAME = 'al_toque'
    $env:DB_USER = 'al_toque_api'
    $env:DB_PASSWORD = ''
    $env:ALLOW_EMPTY_DB_PASSWORD = 'true'

    if (Test-Path -LiteralPath $stdoutPath) {
        Remove-Item -LiteralPath $stdoutPath
    }
    if (Test-Path -LiteralPath $stderrPath) {
        Remove-Item -LiteralPath $stderrPath
    }

    $backendPath = Split-Path -Parent $PSScriptRoot
    $server = Start-Process `
        -FilePath $dartExe `
        -ArgumentList @('run', 'bin/server.dart') `
        -WorkingDirectory $backendPath `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath `
        -PassThru

    @{
        processId = $server.Id
        executable = $dartExe
        stdoutPath = $stdoutPath
        stderrPath = $stderrPath
    } | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8

    $apiReady = $false
    for ($attempt = 0; $attempt -lt 45; $attempt++) {
        $server.Refresh()
        if ($server.HasExited) {
            break
        }

        try {
            $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 2
            if ($health.status -eq 'ok') {
                $apiReady = $true
                break
            }
        }
        catch [System.Net.WebException] {
            if ($_.Exception.Response -ne $null) {
                throw
            }
        }

        Start-Sleep -Seconds 1
    }

    if (-not $apiReady) {
        $stdout = ''
        if (Test-Path -LiteralPath $stdoutPath) {
            $stdoutContent = Get-Content -LiteralPath $stdoutPath -Raw
            if ($null -ne $stdoutContent) {
                $stdout = $stdoutContent.Trim()
            }
        }
        $stderr = ''
        if (Test-Path -LiteralPath $stderrPath) {
            $stderrContent = Get-Content -LiteralPath $stderrPath -Raw
            if ($null -ne $stderrContent) {
                $stderr = $stderrContent.Trim()
            }
        }
        throw "La API no pudo conectarse con MySQL o no respondio a tiempo. $stderr $stdout"
    }

    Write-Output 'API y MySQL conectados. Iniciando Flutter.'
}
catch {
    $startupError = $_
    if ($null -ne $server) {
        if (Get-Process -Id $server.Id -ErrorAction SilentlyContinue) {
            Stop-Process -Id $server.Id -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $statePath) {
            Remove-Item -LiteralPath $statePath
        }
    }
    Write-Host "Error: $($startupError.Exception.Message)" -ForegroundColor Red
    exit 1
}
