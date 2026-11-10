# Checkout lifecycle

The hold response supplies the authoritative booking ID and `holdExpiresAt`. Checkout refuses to request a quote when the injected app clock is at or after that expiry. Backend expired/invalid responses remain errors and do not create a fake success.
