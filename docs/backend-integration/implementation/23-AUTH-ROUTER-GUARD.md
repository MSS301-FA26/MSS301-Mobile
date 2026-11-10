# Authentication router guard

`AuthGuard` observes `authSessionProvider`:

- `initializing`: show a progress state;
- `authenticated`: render the protected page;
- `unauthenticated`: redirect to `/auth/login`.

Protected account, order, profile, wallet, points, checkout, payment, and ticket routes are guarded. Public discovery and catalog routes remain accessible without a session.
