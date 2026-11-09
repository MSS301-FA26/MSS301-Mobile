
param(
    [string]$Device = 'emulator-5554',
    [switch]$SetupOnly
)

$ErrorActionPreference = 'Stop'
$adbCommand = Get-Command adb -ErrorAction SilentlyContinue
if ($adbCommand) {
    $adbPath = $adbCommand.Source
} else {
    $sdkPath = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } elseif ($env:ANDROID_SDK_ROOT) { $env:ANDROID_SDK_ROOT } else { Join-Path $env:LOCALAPPDATA 'Android\Sdk' }
    $adbPath = Join-Path $sdkPath 'platform-tools\adb.exe'
}
if (-not (Test-Path -LiteralPath $adbPath)) {
    throw 'adb not found. Install Android SDK Platform-Tools or add adb to PATH.'
}
& $adbPath -s $Device reverse tcp:8080 tcp:8080
if ($LASTEXITCODE -ne 0) { throw "Cannot forward port 8080 for $Device. Start the emulator first." }
Write-Host 'Mobile localhost:8080 -> host localhost:8080'
if ($SetupOnly) { exit 0 }

Push-Location (Split-Path -Parent $PSScriptRoot)
try {
    & flutter run -d $Device '--dart-define=API_BASE_URL=http://localhost:8080' '--dart-define=UI_PREVIEW=false'
    $runExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $runExitCode
