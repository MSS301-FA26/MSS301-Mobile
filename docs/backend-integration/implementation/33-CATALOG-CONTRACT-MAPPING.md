# Catalog contract mapping

| Mobile | Backend | Status | Notes |
|---|---|---|---|
| `MovieDto` | `MovieResponse` | Done | Direct numeric ID; nullable presentation fields remain nullable. |
| `CinemaDto` | `CinemaResponse` | Done | Maps ACTIVE status to `active`. |
| `ShowtimeSlot` | `ShowtimeResponse` | Done | Uses exact movie/cinema/room IDs and start/end timestamps. |
| `GenreDto` | movie `genres` | Done | Name list is rendered when present. |
| `ActorDto` | movie `actors` | Done | No fake cast fallback. |
| `List<MovieDto>` | `ApiResponse<PageResponse<MovieResponse>>.data.items` | Done | Page zero, size 100; no UI load-next yet. |
