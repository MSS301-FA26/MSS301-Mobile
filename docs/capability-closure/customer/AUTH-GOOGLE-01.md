# AUTH-GOOGLE-01 — Google Login

## Verified contract

Source audit: Backend `dev` at `3e48f94`, identity-service and API Gateway. Backend and Web are read-only for this task.

`POST /api/v1/auth/google`, through the configured API Gateway:

```json
{"credential":"<Google ID token>"}
```

The credential is an **ID token**, not a Google access token, account ID, email, or authorization code. Backend verifies token-info, the exact audience against `GOOGLE_OAUTH_CLIENT_ID`, and verified email. The success envelope is `success: true`, with `data` containing the existing `AuthResponse`: `accessToken`, `refreshToken`, `tokenType`, `expiresInMs`, `user`, `roles`.

Evidence in Backend: `AuthController.java:50`, `GoogleLoginRequest.java:5`, `GoogleTokenVerifierImpl.java:28`, `AuthServiceImpl.java:209`, `AuthResponse.java:6`, Gateway `application.properties:13`, `TrustedGatewayFilter.java:36`, identity `SecurityConfig.java:124`.

New users receive CUSTOMER; existing same-email accounts retain their existing roles. Mobile does not grant roles or invent an account-linking step. `/auth/google/verify` exists as a separate legacy endpoint but is not required by `/auth/google`. Neither OTP nor password setup is added to this login flow.

Backend responses include 400 for invalid/configuration requests, 401 for invalid audience/credential/unverified email/disabled account, generic 409 constraint failures, and server failures. There is no Google-specific account-conflict resolution contract.

## Web trace

`AuthModal.jsx` button → Google Identity Services (`accounts.google.com/gsi/client`, popup) → callback `credential` → `authService.loginWithGoogle` → Gateway `/api/v1/auth/google` → standard application tokens → `saveAuthSession` (localStorage tokens/user/roles/expiry) → `completeLogin` → existing `useAuthStore.handleLoginSuccess` role/navigation handling → modal close.

Web `VITE_GOOGLE_CLIENT_ID` and Backend `GOOGLE_OAUTH_CLIENT_ID` match in the inspected local configuration; values were not printed. This is configuration evidence, not proof of a successful runtime Google login.

## Mobile integration and boundary

The old button was intentionally disabled (`onPressed: null`). Login now obtains the ID token through the official Flutter `google_sign_in` adapter and calls `AuthRepository.loginWithGoogle`. The remote repository reuses its existing `_save` and secure token storage. `AuthSessionController` produces the same `AuthSession`, and AuthPage observes its existing authenticated-state redirect, including the existing local `continue` destination rules.

The Google exchange skips app-token refresh/retry and stale bearer attachment. It never supplies internal-service secrets or manual Authorization. Malformed session envelopes are rejected before storage. Errors are mapped to recoverable Vietnamese auth feedback without raw SDK/server details. Cancellation sends no request and creates no session. Duplicate Google/password attempts are gated synchronously. Logout invalidates late Google results and waits for any token write/cleanup already underway before clearing storage.

Only the application tokens are persisted. Google tokens are not stored, and no Google API authorization scopes or Firebase authentication/session system are introduced. Each native interactive attempt first signs out the previous SDK account; an unresolved native picker cannot start another SDK authentication. The SDK is initialized once, including when initialization fails; restart the app/browser after fixing configuration or an SDK initialization failure.

Native keeps the existing `[G ĐĂNG NHẬP BẰNG GOOGLE]` design with busy/disabled states and semantics. Flutter Web must use the **visible official Google SDK button**, in the existing auth panel. It is replaced by a loading placeholder during exchange, not hidden beneath a custom button. Closing the browser popup yields no credential and no CinePremier session. Browser SDK cancellation does not require an invented callback.

Normal password payload/validation/redirect, Register, OTP, Forgot Password, guards, app refresh, Booking, Payment, Wallet and Loyalty are otherwise unchanged. The generated macOS plugin registrant changes automatically with the plugin dependency; macOS/Windows/Linux Google login is not enabled by this adapter.

## Required OAuth configuration

Use Dart defines, alongside the existing `APP_ENV` and `API_BASE_URL`. OAuth **client IDs are public identifiers**, not client secrets. Never put OAuth client secrets or service secrets in the application.

| Target | App registration | Required client/configuration |
|---|---|---|
| Android | Current applicationId `com.example.mss301_mobile` | Register Android OAuth client for this exact package and the signing certificate SHA-1. Record SHA-256 as required by the Firebase/project setup. `GOOGLE_SERVER_CLIENT_ID` must be the Backend's Web OAuth client ID. |
| Flutter Web | Authorized JavaScript origins for each deployment origin | `GOOGLE_SERVER_CLIENT_ID` is passed as Web `clientId`, **not** `serverClientId`. Register `http://localhost` and the exact fixed local port, plus actual HTTPS deployment origins. |
| iOS | Current bundle ID `com.example.mss301Mobile` | `GOOGLE_IOS_CLIENT_ID` is the native iOS client; `GOOGLE_SERVER_CLIENT_ID` is the same Backend Web client. Add its reversed-client-ID URL scheme to `ios/Runner/Info.plist`. |

Android uses explicit `serverClientId`, so this implementation does **not** require adding `google-services.json`, a Firebase auth dependency, or the Google Services Gradle plugin. Cloud-side Android package/signature registration is still required. If the team uses Firebase registration instead, follow that project's official setup; do not introduce a default/fake ID.

No configured Mobile OAuth Dart define was found during the audit. No Android debug keystore exists at `C:/Users/quyet/.android/debug.keystore`, so the actual signing SHA-1/SHA-256 could not be determined and no key was created. Obtain the SHA from the signing certificate actually used for each debug/release build (Android `gradlew.bat signingReport` with a configured Android SDK), and register those exact values. Release currently uses the project's existing debug signing configuration; production signing is a separate team-owned setup requirement.

Example commands (replace client-ID placeholders with the verified project identifiers):

```powershell
flutter run -d <android-device> --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=GOOGLE_SERVER_CLIENT_ID=<backend-web-client-id>
flutter run -d chrome --web-hostname localhost --web-port 7357 --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://localhost:8080 --dart-define=GOOGLE_SERVER_CLIENT_ID=<backend-web-client-id>
```

The Android URL above is for the standard Android emulator only. Physical devices must use a reachable Gateway URL, not an internal service URL. Web additionally requires the existing Gateway CORS policy to allow the chosen origin. iOS URL-scheme setup cannot be completed without the team's actual iOS OAuth registration; no placeholder is installed into Info.plist.

Official integration guidance: [Flutter Google Sign-In](https://pub.dev/packages/google_sign_in), [Android configuration](https://pub.dev/packages/google_sign_in_android), [Web SDK button/origins](https://pub.dev/packages/google_sign_in_web), [iOS client and URL scheme](https://pub.dev/packages/google_sign_in_ios).

## Verification and limits

### Files changed by this task

Existing files:

- `lib/core/network/auth_interceptor.dart`
- `lib/features/auth/application/auth_session.dart`
- `lib/features/auth/data/auth_repository.dart`
- `lib/features/auth/data/auth_remote_data_source.dart`
- `lib/features/auth/data/remote_auth_repository.dart`
- `lib/features/auth/presentation/pages/auth_page.dart`
- `lib/features/auth/presentation/widgets/auth_form_layout.dart`
- `test/ui_r08_auth_test.dart`
- `pubspec.yaml`
- `pubspec.lock`
- `macos/Flutter/GeneratedPluginRegistrant.swift` (generated)
- `README.md`

New files:

- `lib/features/auth/application/google_auth_provider.dart`
- `lib/features/auth/data/google_auth_adapter.dart`
- `lib/features/auth/presentation/widgets/google_login_button.dart`
- `lib/features/auth/presentation/widgets/google_web_button.dart`
- `lib/features/auth/presentation/widgets/google_web_button_stub.dart`
- `test/google_auth_adapter_test.dart`
- `test/google_auth_session_test.dart`
- `test/google_login_test.dart`
- `test/remote_google_auth_test.dart`
- `test/support/google_auth_test_support.dart`
- `docs/capability-closure/customer/AUTH-GOOGLE-01.md`

### Test coverage

Tests use doubles only at SDK/HTTP/storage boundaries, never real Google login. They exercise the real controller/repository, exact credential exchange, app token persistence, malformed envelopes, mapped failures, cancellation, pending Completer duplicate submits, cross-login races, logout/cleanup races, initialization, missing ID token, existing continue navigation, password regression, and narrow/large-text layouts.

Run:

```powershell
flutter test test/remote_google_auth_test.dart test/google_auth_adapter_test.dart test/google_auth_session_test.dart test/google_login_test.dart test/ui_r08_auth_test.dart
flutter analyze
flutter test
git diff --check
```

A mutation of the revoked-generation check was rejected by the late-response/logout test (it detected stale application tokens). The condition was restored. Independent fresh-context design and code reviews were performed; the user declined an additional cross-model review.

### Final validation results (2026-10-11)

| Check | Result |
|---|---|
| Focused Google adapter/repository/controller/UI and existing Auth tests | PASS |
| `flutter analyze` | PASS, no issues |
| Full `flutter test --reporter expanded` | PASS, 557 tests |
| `flutter build web` with development Gateway URL and the inspected public Web OAuth client ID supplied through a Dart define | PASS |
| `git diff --check` | PASS; existing line-ending conversion warnings only |
| `git status --short`, `git diff --stat`, `git diff --name-only` | Inspected; no staging, commit or push |

Google Login widget renders at 320, 430 and 768 px were inspected; narrow/large-text tests passed. Capture artifacts are under ignored `build/google-login/`. These are widget-test renders, not an authenticated browser or device session.

The Web build emits pre-existing `flutter_secure_storage_web` WebAssembly dry-run incompatibilities and a missing Cupertino font-family warning; the standard Web build succeeds. WebAssembly migration is outside this task. Chrome DevTools is not configured in this session, so real browser SDK/network/console verification could not be performed; SDK-boundary tests and a Web compile were used instead. Manual Google sign-in remains required after OAuth configuration.

Gateway `GET http://localhost:8080/actuator/health` returned HTTP 200/UP. This proves health reachability only, not Google endpoint deployment or a verified user sign-in. Real device/browser Google login, signing registration, running Backend audience, and cloud-project ownership still require configured manual verification. No Google account login or Backend user/session creation was performed by the tests.

Inherited Backend security concern for the Backend owner: `AuthServiceImpl.java:254` derives a new Google user's password hash from Google `sub`. This is existing team-owned business logic and was not modified. It requires a separate Backend security review; this integration must not be interpreted as production security approval for that logic.

No git add, commit, or push. Existing Home working-tree changes are preserved and are not part of AUTH-GOOGLE-01.
