# Seat map

`GET /api/v1/showtimes/{showtimeId}/seat-map` preserves backend showtime and seat IDs. A seat is selectable only when `seatStatus == AVAILABLE` and `runtimeStatus == AVAILABLE`.
