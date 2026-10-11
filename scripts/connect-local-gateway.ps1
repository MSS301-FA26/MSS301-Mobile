param(
    [string]$DeviceId = 'emulator-5554',
    [int]$RelayPort = 18080,
    [int]$GatewayPort = 8080,
    [int]$DevicePort = 8080
)

$ErrorActionPreference = 'Stop'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adbPath)) {
    throw "ADB not found at $adbPath."
}

# The host's IPv4 port 8080 is occupied by Apache. Use the Docker
# gateway on IPv6 loopback, while keeping the APK's local URL unchanged.
if (-not ('MobileLocalGatewayRelay' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;
public static class MobileLocalGatewayRelay {
    private static TcpListener listener;
    public static async Task Run(int relayPort, int gatewayPort) {
        listener = new TcpListener(IPAddress.Loopback, relayPort);
        listener.Start();
        try {
            while (true) {
                var client = await listener.AcceptTcpClientAsync();
                var forwarding = Forward(client, gatewayPort);
            }
        } finally { listener.Stop(); }
    }
    public static void Stop() {
        if (listener != null) listener.Stop();
    }
    private static async Task Forward(TcpClient client, int gatewayPort) {
        using (client)
        using (var upstream = new TcpClient(AddressFamily.InterNetworkV6)) {
            try {
                await upstream.ConnectAsync(IPAddress.IPv6Loopback, gatewayPort);
                var source = client.GetStream();
                var target = upstream.GetStream();
                await Task.WhenAny(source.CopyToAsync(target), target.CopyToAsync(source));
            } catch { }
        }
    }
}
'@
}

$reverseConfigured = $false
try {
    $relayTask = [MobileLocalGatewayRelay]::Run($RelayPort, $GatewayPort)
    if ($relayTask.IsFaulted) { $relayTask.GetAwaiter().GetResult() }
    & $adbPath -s $DeviceId reverse "tcp:$DevicePort" "tcp:$RelayPort"
    if ($LASTEXITCODE -ne 0) { throw 'ADB reverse failed. Check the emulator connection.' }
    $reverseConfigured = $true
    Write-Host "Mobile http://127.0.0.1:$DevicePort -> host relay $RelayPort -> Docker [::1]:$GatewayPort"
    Write-Host 'Keep this terminal running. Press Ctrl+C to disconnect. APK requires --dart-define=API_BASE_URL=http://127.0.0.1:8080.'
    while (-not $relayTask.IsCompleted) { Start-Sleep -Milliseconds 500 }
    $relayTask.GetAwaiter().GetResult()
} finally {
    [MobileLocalGatewayRelay]::Stop()
    if ($reverseConfigured) {
        & $adbPath -s $DeviceId reverse --remove "tcp:$DevicePort"
    }
}
