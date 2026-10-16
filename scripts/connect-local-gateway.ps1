param(
    [string]$DeviceId = 'emulator-5554',
    [int]$GatewayPort = 0,
    [int]$DevicePort = 0,
    [string]$BackendEnvPath = (Join-Path $PSScriptRoot '..\..\..\BE\MSS301-Backend\.env')
)
$ErrorActionPreference = 'Stop'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adbPath)) { throw "ADB not found at $adbPath." }
if ($GatewayPort -eq 0) {
    if (-not (Test-Path -LiteralPath $BackendEnvPath)) { throw "Missing root BE env: $BackendEnvPath" }
    $portLines = @(Get-Content -Encoding UTF8 -LiteralPath $BackendEnvPath | Where-Object { $_ -match '^\s*GATEWAY_PORT\s*=' })
    if ($portLines.Count -ne 1) { throw 'Set exactly one GATEWAY_PORT in the root BE .env.' }
    $rawPort = ($portLines[0] -split '=',2)[1].Trim().Trim('"').Trim("'")
    if (-not [int]::TryParse($rawPort, [ref]$GatewayPort)) { throw 'GATEWAY_PORT must be numeric.' }
}
if ($GatewayPort -lt 1 -or $GatewayPort -gt 65535) { throw 'Invalid gateway port.' }
if ($DevicePort -eq 0) { $DevicePort = $GatewayPort }
if ($DevicePort -lt 1 -or $DevicePort -gt 65535) { throw 'Invalid device port.' }
# adb reverse forwards directly to Docker's dedicated host port.
# No intermediate listener or background PowerShell relay is needed.
& $adbPath -s $DeviceId reverse "tcp:$DevicePort" "tcp:$GatewayPort"
if ($LASTEXITCODE -ne 0) { throw 'ADB reverse failed. Check the emulator connection.' }
Write-Output "Mobile http://127.0.0.1:$DevicePort -> ADB -> Docker host port $GatewayPort"
Write-Output "Build/run with --dart-define=API_BASE_URL=http://127.0.0.1:$DevicePort"
