# Token storage

Access and refresh tokens are stored through `TokenStorage`, implemented by `SecureTokenStorage` with `flutter_secure_storage`.

The UI and repositories never access platform storage directly. This keeps storage replaceable in tests and ensures logout clears both token keys.

Keys:

- `auth.access_token`
- `auth.refresh_token`

Tokens are not written to logs or included in user-facing error messages.
