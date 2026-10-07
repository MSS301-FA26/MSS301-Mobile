# Batch 03 status

Implemented:

- real login, registration, email verification, password reset, refresh, and logout data paths;
- secure access/refresh token storage;
- Dio bearer injection and single-flight refresh;
- Riverpod auth bootstrap/session state;
- production AuthPage and AuthGuard wiring;
- auth architecture documentation.

Validation:

- `flutter analyze`: PASS.
- `flutter test`: NOT GREEN yet. Existing widget tests still assume the old `mockAuthSessionProvider` controls AuthPage and protected routes. They currently fail in mock booking/account navigation after the production auth switch.

Catalog, booking, payment, and account domain repositories remain mock as explicitly scoped for this batch.

## Test Migration

Legacy auth provider: `mockAuthSessionProvider`

Production auth provider: `authSessionProvider`

Migration:

- added a test-only `FakeAuthSessionController` with deterministic authenticated CUSTOMER and unauthenticated states;
- centralized widget setup in `test/support/pump_test_app.dart`, overriding the same `authSessionProvider` read by production UI and `AuthGuard`;
- migrated booking, payment, account, and navigation widget tests to the authenticated CUSTOMER fixture;
- added guard coverage for public access, protected-route redirect, authenticated access, authenticated-login redirect, and logout;
- removed the runtime `ShowtimesPage` dependency on mock auth and preserved the requested route through the real login flow.

Final test status:

- `flutter analyze`: PASS;
- `flutter test`: PASS.
