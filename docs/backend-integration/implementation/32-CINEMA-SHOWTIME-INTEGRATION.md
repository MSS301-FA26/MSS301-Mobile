# Cinema and showtime integration

- Cinemas: `GET /api/v1/cinemas` maps `id`, `name`, `address`, `city`, `phone`, and `status == ACTIVE`.
- Showtimes: `GET /api/v1/showtimes?movieId=&date=YYYY-MM-DD&page=0&size=100`.

The app formats a selected local calendar day as `YYYY-MM-DD`; it does not convert that date to UTC. Backend `startTime` and `endTime` are parsed as returned by the JSON datetime parser and displayed as local calendar/time values.

Backend status is authoritative: `OPEN` is bookable; `SCHEDULED`, `CANCELLED`, and `COMPLETED` are disabled. The response does not expose room projection format, so mobile does not infer IMAX/VIP metadata from room IDs.

## REAL_SHOWTIME_TO_MOCK_SEAT_TRANSITION_GAP

This is a gap, not a mapping rule. A real showtime ID is passed unchanged to the seat route, while `MockCatalogRepository.getSeatMap` only resolves known fixture showtime IDs. A real ID therefore has no matching mock seat map. Batch 05 must replace this boundary with the real seat flow; no fallback or ID remapping is used.
