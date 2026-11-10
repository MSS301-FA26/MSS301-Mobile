# Catalog architecture

Production browse flow is `Home / Discover / Movie detail / Showtime` -> Riverpod -> `CatalogRepository` -> `RemoteCatalogRepository` -> Dio -> Gateway `:8080` -> Catalog Service.

`catalogRepositoryProvider` is remote by default. `mockCatalogRepositoryProvider` remains an explicit boundary for seat, booking, checkout, and deterministic widget tests; `pumpTestApp` overrides the production provider to that mock.

The remote repository deliberately leaves seat maps, food, and checkout quotes out of scope until Batch 05.
