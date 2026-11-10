# Movie integration

- List: `GET /api/v1/movies?keyword=&status=&page=0&size=100`
- Detail: `GET /api/v1/movies/{id}`
- Envelope: `ApiResponse<PageResponse<MovieResponse>>`; mobile reads `data.items`.

Search mode is `SERVER_SIDE_SEARCH`: Discover debounces typing for 300 ms and sends the backend's exact `keyword` parameter. Empty input uses the normal movie provider. Loading, error/retry, and empty states use the existing repository-state UI.

The current browse UI consumes the first page only; it has no infinite-scroll/load-next control. Null poster, trailer, actors, genres, rating, description, age rating, or release date are rendered as empty/neutral UI values, never fixture data.
