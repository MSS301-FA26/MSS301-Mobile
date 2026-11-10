# Seat architecture

Seat map: Flutter -> RemoteCatalogRepository -> Gateway -> Catalog Service.

Hold/read/cancel: Flutter -> BookingEntryController -> SeatHoldRepository -> RemoteSeatHoldRepository -> Gateway -> Booking Service. JWT is supplied by AuthInterceptor.
