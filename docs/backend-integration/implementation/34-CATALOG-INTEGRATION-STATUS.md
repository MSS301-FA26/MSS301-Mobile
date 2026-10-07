# Catalog integration status

| Capability | Status |
|---|---|
| RemoteCatalogRepository | Done |
| Movie list | Real |
| Movie detail | Real |
| Search | Server-side (`keyword`) |
| Pagination | First-page content mapped; UI pagination not implemented |
| Cinema | Real repository mapping |
| Showtime | Real repository mapping and movie/date provider query |
| Status mapping | OPEN only is bookable |
| Production binding | Remote |
| Test override | Mock |
| Live verification | `GATEWAY_LOCAL_DEPLOYMENT_ISSUE`: source contract and mobile endpoint are correct; localhost:8080 returned HTML 404 because the local Gateway runtime/routing deployment is not serving Catalog routes |
| Showtime -> Seat boundary | `REAL_SHOWTIME_TO_MOCK_SEAT_TRANSITION_GAP` |
