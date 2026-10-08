# Environment Configuration

Mechanism: `--dart-define`.

Required values:

```text
APP_ENV=development|staging|production
API_BASE_URL=https://...
```

`API_BASE_URL` must be a non-empty absolute HTTP(S) URL. Invalid or missing values fail fast; there is no silent production fallback.

## Commands

PowerShell:

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Staging:

```powershell
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://<staging-gateway-host>
```

Production:

```powershell
flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://<production-gateway-host>
```

## Host guidance

- Android emulator with gateway on host PC: `http://10.0.2.2:8080`.
- Physical Android device: use a reachable LAN IP/hostname such as `http://192.168.x.x:8080`; do not hardcode it.
- Desktop/web: use the host/URL reachable from that platform.

Development HTTP may require platform cleartext configuration when using a local gateway. Production should use HTTPS.
