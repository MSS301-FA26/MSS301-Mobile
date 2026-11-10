# B11 Mobile Implementation Plan

## B11-B — Watchlist production flow

Precondition: Backend adds and tests Gateway predicates for `/api/v1/wishlist`.

Scope:

- Add DTO, remote data source, repository, and Riverpod state.
- Add a production watchlist page for the Web-equivalent list.
- Add server-backed favorite state to Movie Detail, Home cards, and Discover cards.
- Preserve catalog movie IDs and existing catalog repository behavior.
- Replace only the preview favorites destination; do not convert preview features generally.

Likely files:

- new `lib/features/wishlist/data/...`
- new `lib/features/wishlist/application/...`
- new `lib/features/wishlist/presentation/...`
- `lib/features/movie/presentation/pages/movie_detail_page.dart`
- Home/Discover movie-card widgets
- routing files only for the approved production list route

Acceptance:

- list/add/remove use Gateway endpoints;
- duplicate and not-found errors are mapped explicitly;
- state is refreshed after mutations and survives restart;
- unauthenticated behavior follows existing auth guards;
- no direct service URL and no preview repository.

## B11-C — Standalone food-order history

Scope:

- Add a production food-order DTO/data source/repository/provider.
- Implement read-only `GET /api/v1/food-orders/my` history.
- Add a dedicated history page and reusable food-order card.
- Add Account navigation and a production route.
- Keep booking concessions, checkout quote, payment, and ticket flows unchanged.

Likely files:

- new `lib/features/food/data/...`
- new `lib/features/food/application/...`
- new `lib/features/food/presentation/...`
- `lib/features/account/presentation/pages/account_page.dart`
- routing files for the new production route

Defer create/cancel/payment actions until a separate contract and integration review.

## Google password setup

No implementation batch is authorized. Re-open only after the identity service exposes an explicit setup-required state or the product explicitly classifies this as Web-only.
