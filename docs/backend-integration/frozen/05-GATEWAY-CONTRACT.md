# Gateway Contract

Status: `FROZEN for current Docker/gateway configuration`

Public base URL:

```text
API_BASE_URL = http://<host>:8080
```

The port is configurable through `GATEWAY_PORT`; the default is 8080 in root `docker-compose.yml`.

| Domain | Public path family | Owner service | Customer auth |
|---|---|---|---|
| Auth/profile | `/api/v1/auth/**`, `/api/v1/users/**` | identity-service | Public/authenticated by endpoint |
| Movies/catalog | `/api/v1/movies/**`, `/api/v1/genres/**`, `/api/v1/actors/**`, `/api/v1/cinema/**`, `/api/v1/cinemas/**` | catalog-service | Public |
| Showtime/seat | `/api/v1/showtimes/**`, `/api/v1/seats/**`, `/api/v1/ticket-pricing/**` | catalog-service | Public / booking auth where applicable |
| Food/quote | `/api/v1/foods/**`, `/api/v1/catalog/**` | catalog-service | Public/authenticated by endpoint |
| Booking | `/api/v1/bookings/**` | booking-service | CUSTOMER |
| Payment | `/api/v1/payments/**` | payment-service | CUSTOMER except provider callbacks |
| Wallet/loyalty | `/api/v1/wallet/**`, `/api/v1/wallets/**`, `/api/v1/loyalty/**` | payment-service | CUSTOMER |
| Recommendation | `/api/v1/recommendation/**`, `/api/v1/recommendations/**`, `/api/v1/ai-recommendation/**` | catalog/recommendation route | Endpoint-specific |
| Reviews | `/api/v1/reviews/**` | catalog-service | Public/customer by endpoint |
| Notifications | No route proven in current gateway properties | — | GATEWAY_ROUTE_MISSING |

Evidence: `cinema-services/api-gateway/src/main/resources/application.properties:10-33` and root `docker-compose.yml:233-257`.

Mobile must not call `internal/v1` service paths. Those are service-to-service contracts.
