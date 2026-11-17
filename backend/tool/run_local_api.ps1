$ErrorActionPreference = 'Stop'

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
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 5
    if ($health.status -eq 'ok') {
        Write-Output 'API local disponible en http://0.0.0.0:8080'
        exit 0
    }
    throw 'El puerto 8080 ya esta ocupado por una API que no pudo validar MySQL.'
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

Set-Location (Split-Path -Parent $PSScriptRoot)
& dart run bin/server.dart
exit $LASTEXITCODE
