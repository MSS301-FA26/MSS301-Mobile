# POST-GOOGLE-LOGIN-01 — Account Wallet failure isolation

## Scope and evidence limits

2026-10-11. Backend `dev` at `3e48f94` is read-only. Web, Google authentication, session persistence, logout protection and business APIs are unchanged by this task. Existing Home and Google Login working-tree changes are preserved; no staging, commit or push.

The user reports Google login reaching `/account`, followed by Gateway `GET http://localhost:8080/api/v1/wallet` returning HTTP 500 and a 12 px right-side RenderFlex overflow. That authenticated browser is not connected to this session. Chrome DevTools is not configured and Computer Use inventory has no browser. No browser token, localStorage credential or real account was inspected. Runtime Google success, persisted runtime tokens and the original Wallet request's bearer header therefore remain **NOT_PROVEN** independently.

The real Mobile Google controller/repository/interceptor flow is exercised through test-only SDK/HTTP/storage doubles: it saves application access/refresh tokens, redirects to the actual Account page, attaches bearer Authorization to Gateway Wallet GET, and preserves the session on HTTP 500. This is executable client-contract evidence, not a successful live Google sign-in or a Backend runtime trace.

## Wallet request trace

- `RemoteWalletRepository.getWallet` in `lib/features/account/data/repositories/remote_account_repositories.dart` calls `/api/v1/wallet`, without an ID query, manual Authorization, service secret or internal-service URL. Its legacy method argument does not alter that route.
- `dioProvider` uses the configured Gateway base URL. `AuthInterceptor.onRequest` obtains the application's access token from the existing storage and attaches bearer Authorization. Only 401 enters the existing refresh mechanism; Wallet 500 does not clear credentials or refresh/logout.
- Successful envelopes are parsed into `WalletDto`; mapped API errors remain failures.
- Account previously awaited Profile, Wallet and Loyalty sequentially inside `accountSummaryProvider`. Wallet failure rejected the entire aggregate and selected the whole-page error pane.

## Backend source audit

Paths below are relative to `cinema-services/` in the Backend repository.

| Source | Evidence |
|---|---|
| `payment-service/.../controller/WalletController.java:19,26–30` | GET `/api/v1/wallet` passes authenticated principal ID to `WalletService.getWallet`. An inherited null-principal fallback exists, but there is no evidence it caused this failure. |
| `payment-service/.../service/impl/WalletServiceImpl.java:43–46,277–282` | `getWallet` is marked `@Transactional(readOnly = true)` but calls lazy `getOrCreateWallet`, whose absent-wallet branch calls repository `save`. This read-only/write contradiction is the main source-backed candidate, **not the proven cause of the observed 500**. |
| `payment-service/.../repository/CineWalletRepository.java:9–10` | `findByUserId` returns Optional; missing wallet is handled through `orElseGet`, not `Optional.get`. |
| `payment-service/.../entity/CineWallet.java:16–25` | Wallet has generated ID, unique internal user ID and server-owned initial balance. Mobile does not create a wallet or invent an ID/balance. |
| `payment-service/.../exception/GlobalExceptionHandler.java:85–88` | Unexpected exceptions are logged and returned as HTTP 500. Mobile's section does not display raw server exception text. |
| `api-gateway/src/main/resources/application.properties:26–28` | Existing payment route exposes singular/plural Wallet paths. |
| `identity-service/.../service/impl/AuthServiceImpl.java:191–221,292–303` | Password login and Google login call the same `createAuthResponse(User)`. |
| `identity-service/.../security/JwtService.java:34–40` | App JWT has `sub = user.email`, numeric `userId = internal User.id`, email and roles; no `accountId`. Google external subject is not forwarded as the application's user ID. |
| `payment-service/.../security/SecurityConfig.java:114–140` | Wallet resolves numeric `userId` first, with numeric subject fallback. Valid Google and password application tokens use the same mapping. |

Normal registration and Google user creation do not eagerly provision a wallet; this Backend uses lazy creation. An absent wallet alone is not proof of a Google-specific data initialization failure. Runtime schema, deployment/configuration and exception details were not inspected through database mutations or new authenticated requests.

**Wallet 500 classification: INSUFFICIENT_EVIDENCE.**

**BACKEND_RUNTIME_TRACE: NOT_AVAILABLE.** Services are IntelliJ-launched Java processes on local ports 8080–8084, with native PostgreSQL on 5432. Docker daemon was unavailable. No saved service log files or configured console-output files were found in the inspected workspace. The actual exception type and failing runtime line remain unknown.

Required evidence to close diagnosis: sanitized original Wallet 500 stack trace from the Payment Service Run console, plus the RenderFlex diagnostic creator/file/line for the original 12 px right-side overflow. Do not share bearer tokens, Google credentials, email or personal IDs. If the trace confirms read-only transaction insertion, the Backend owner must resolve that transaction/lazy-creation defect; this task does not change Backend code or database data.

## Safe Mobile changes

- Account summary now loads Profile only. Wallet and Loyalty have independent, session-keyed, auto-disposed FutureProviders and independent loading/error/data states.
- Wallet failure shows `Ví CinePremier`, `Không thể tải thông tin ví.` and `Thử lại` inside its section. Missing wallet balance is not represented by zero, stale data or a fake wallet.
- Wallet retry invalidates only Wallet. Automatic retries are disabled for these two Account section providers; the retry callback starts loading synchronously to gate a second tap before rebuild. Profile, Loyalty and authenticated session remain intact.
- Loyalty has its own equivalent state and retry. Successful point redemption invalidates the new remote section providers as well as the existing refresh targets; redemption requests and rules are unchanged.
- `WalletTile` receives a real balance; `MembershipCard` receives real points. Account's profile-only summary holds absent remote fields as null, not invented values.
- Existing Profile repository wiring is still the inherited `MockAccountStore`/`DemoIds` implementation. It was not migrated in this presentation task and must not be cited as proof of a live customer Profile API. No new production mock or fallback is added.

[Riverpod automatic retry](https://riverpod.dev/docs/concepts2/retry#disabling-retry) documents per-provider retry configuration; returning null disables automatic retry. The project uses Riverpod 3.4.3. This setting is local to Account remote sections, not a global retry-policy change.

## Responsive diagnosis

The original 12 px **right-side** overflow did not reproduce in the current working tree's faithful-font Account error/header probes at 320, 390, 400, 430 and 768 px, including 400 × 856 and 200% text scale. Its exact RenderFlex source remains **NOT_PROVEN**; it must not be reported as fixed solely because tests pass.

A separate accessibility defect did reproduce: noncompact header targets were 40 px. They now provide at least 44 px targets without removing navigation or changing Home's compact header behavior. Existing location flex/ellipsis is retained, and only the decorative CP mark scales down.

Opening the header's cinema information sheet at 320 px with 200% text scale also reproduced a **52 px bottom-side** overflow in `CinemaInfoSheet`'s Column under the default modal height. The sheet is made scrollable without hiding fields or changing content. This is a distinct, proven defect, not evidence identifying the reported 12 px overflow.

## Files changed by this task

Existing:

- `lib/features/account/presentation/models/account_summary.dart`
- `lib/features/account/presentation/providers/account_summary_provider.dart`
- `lib/features/account/presentation/pages/account_page.dart`
- `lib/features/account/presentation/widgets/account_menu.dart`
- `lib/features/account/presentation/widgets/membership_card.dart`
- `lib/shared/widgets/cinema_header.dart`
- `lib/shared/widgets/cinema_info_sheet.dart`
- `test/ui_r08_account_test.dart`
- `test/support/pump_test_app.dart`

New:

- `lib/features/account/presentation/widgets/account_remote_sections.dart`
- `test/post_google_account_test.dart`
- `test/post_google_responsive_test.dart`
- `docs/capability-closure/customer/POST-GOOGLE-LOGIN-01.md`

## Validation

Focused Wallet isolation tests first failed on the original aggregate: profile/navigation disappeared on Wallet 500 and retries affected the aggregate. The initial six tests passed after separation. Existing Account/Profile/Loyalty/repository/completion regression tests passed (59 tests). The original layout baseline passed 30 faithful-font probes; target-size regression failed at 40 px before the header change.

The final focused run passed **62 tests** (8 Account/session tests and 54 responsive tests), including fresh PNG captures. A temporary inversion of the Wallet retry guard made the exact retry-count assertion fail; the correct guard was restored and the focused suite rerun successfully. This mutation was not left in the working tree.

Visual inspection of the fresh Account success/Wallet-error and shared-header renders at 320, 400, 430 and 768 px confirmed readable wrapping, location ellipsis and no horizontal overflow. Images are test-fixture captures in ignored `build/post-google-responsive/`, not live Backend data or Google runtime screenshots. Header-only error-shell probes deliberately simulate a **core Profile failure**; those are not the Wallet-500 Account captures.

| Validation | Result |
|---|---|
| Focused Account/session/responsive tests with PNG captures | PASS — 62 tests |
| Existing Account/Profile/Loyalty/repository/completion regression run | PASS — 59 tests |
| `flutter analyze` | PASS — no issues found |
| Full `flutter test --reporter expanded` | PASS — 619 tests, 4m05s, exit 0 |
| `flutter build web` | PASS — `build/web`, 111.5s, exit 0 |
| `git diff --check` | PASS — no whitespace errors |

The validation Web build used Gateway `http://localhost:8080`, development configuration and the existing public Google client ID read without printing it. No configuration file was changed. The build retained existing WebAssembly dry-run warnings from `flutter_secure_storage_web` (`dart:html`/`dart:js_util`) and a Cupertino font warning; the normal Web build succeeded. This is not a live sign-in verification and does not claim WebAssembly compatibility.

Final `git status --short`, `git diff --stat` and `git diff --name-only` were inspected. Backend remains clean. Web retains only its pre-existing `AuthModal.jsx` and `test/` changes. Mobile's full diff also includes the earlier Home/Google working-tree work; only the 13 paths above belong to this task. No files were staged, committed or pushed.

Real Backend/authenticated-browser closure still depends on the runtime evidence described above.

**Final diagnostic status: BLOCKED_BY_INSUFFICIENT_EVIDENCE.** This status does not mean the safe Mobile isolation work is unimplemented; it means the reported runtime 500 and original 12 px overflow are not yet conclusively diagnosed.
