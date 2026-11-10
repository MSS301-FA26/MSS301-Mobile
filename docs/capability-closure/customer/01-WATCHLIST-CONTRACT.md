# Watchlist Contract

## Sources

- Backend controller: `MSS301-Backend/cinemaAI/src/main/java/com/sba301/cinemaai/controller/WishlistController.java`
- Request DTO: `.../dto/request/wishlist/WishlistCreateRequest.java`
- Response DTO: `.../dto/response/wishlist/WishlistResponse.java`
- Service: `.../service/WishlistService.java`, `.../service/impl/WishlistServiceImpl.java`
- Gateway: `cinema-services/api-gateway/src/main/resources/application.properties`
- Mobile preview: `lib/features/preview/presentation/pages/preview_feature_page.dart`
- Mobile preview repository: `lib/features/preview/data/provisional_preview_repository.dart`

## Endpoint matrix

| Mobile target | Gateway route | Target service | Controller/method | Auth | DTOs | Result |
|---|---|---|---|---|---|---|
| `GET /api/v1/wishlist` | `booking-service` Path `/api/v1/food-orders...` does **not** include wishlist | No matching Gateway predicate found | `WishlistController.getMyWishlist` | Bearer customer principal | response `List<WishlistResponse>` | **NO** |
| `POST /api/v1/wishlist` | No wishlist predicate | No routed target | `WishlistController.add` | Bearer customer principal | `WishlistCreateRequest { movieId }` → `WishlistResponse` | **NO** |
| `DELETE /api/v1/wishlist/{movieId}` | No wishlist predicate | No routed target | `WishlistController.remove` | Bearer customer principal | no response body | **NO** |

### Important finding

The controller and service contract are implemented, but the current API Gateway predicates do not expose `/api/v1/wishlist`. The booking route exposes `/api/v1/bookings/**` and `/api/v1/food-orders/**`, but not `/api/v1/wishlist/**`.

Therefore Watchlist backend readiness is **PARTIAL**, not READY for production Mobile use. B11-B must first add/verify a Gateway route in a separately approved Backend change. Mobile implementation should not target a direct microservice URL.

## Behavior

- Add: `POST`, request body requires non-null `movieId`; movie existence is validated by the service.
- Duplicate add: unique user/movie constraint and service conflict handling produce a conflict response.
- List: all current-user items, no pagination parameters.
- Remove: `DELETE` by movie ID; missing item produces not-found behavior.
- Authorization: `@AuthenticationPrincipal AuthenticatedUser`; service resolves the current user and scopes every operation to that user.
- Relevant errors: unauthenticated/invalid token (`401`), validation (`400`), movie not found (`404`), duplicate (`409`), missing wishlist item (`404`). Exact envelope is the project `ApiResponse`/exception-handler envelope.

## Movie ID semantics

`movieId` is the backend movie primary key (`Long`), not a slug, title, or external provider ID. The response also carries `movieId`, title, poster URL, wishlist ID, and creation timestamp.

## Mobile findings

Current Mobile has no production wishlist model, data source, repository, provider, or page. Favorites are represented by `ProvisionalPreviewFeature.favorites` and `ProvisionalPreviewRepository`; it is explicitly non-persistent preview behavior. Movie detail, Home, and Discover currently use catalog/movie models and cards but have no production wishlist state integration.

## Minimal architecture after Gateway exposure

Preferred files:

- `lib/features/wishlist/data/models/wishlist_dto.dart`
- `lib/features/wishlist/data/remote_wishlist_data_source.dart`
- `lib/features/wishlist/data/wishlist_repository.dart`
- `lib/features/wishlist/data/remote_wishlist_repository.dart`
- `lib/features/wishlist/application/wishlist_provider.dart`
- `lib/features/wishlist/presentation/pages/wishlist_page.dart`
- movie-detail favorite control and Home/Discover card integration
- routing files only if a dedicated `/wishlist` route is approved

One shared provider should own server-backed membership state. Home, Discover, Movie Detail, and the list page should consume that provider rather than maintain local booleans.

## Dedicated route

**YES**, if parity includes the Web `/watchlist` page. It is not required for the add/remove controls themselves, but a list page is required to replace the current preview favorites destination.

## Gate for B11-B

Backend must first expose and test all three paths through the Gateway. Until then, Mobile watchlist implementation is not integration-safe.
