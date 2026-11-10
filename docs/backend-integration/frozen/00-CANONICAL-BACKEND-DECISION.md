# Canonical Backend Decision

Decision:

```text
CANONICAL = cinema-services
```

Public Mobile Entry Point:

```text
Mobile → API Gateway → identity/catalog/booking/payment/recommendation services
```

Base URL in the current Docker runtime:

```text
http://<host>:${GATEWAY_PORT:-8080}
```

Evidence:

1. `D:/FPTK9/MSS/MSS301-Backend/docker-compose.yml:91-260` builds and health-checks identity, catalog, booking, payment, recommendation, and `api-gateway` services.
2. `docker-compose.yml:233-249` exposes only `api-gateway` externally on port `8080` by default and wires public service URIs behind it.
3. `cinema-services/api-gateway/src/main/resources/application.properties:10-33` defines gateway predicates for auth, catalog, booking, payment, and recommendation paths.
4. Service-to-service URLs in compose use internal Docker names (`identity-service:8081`, `catalog-service:8082`, `booking-service:8083`, `payment-service:8084`), proving these are not Mobile base URLs.

Why `cinemaAI` is not canonical:

`cinemaAI` is a separate monolithic Spring Boot implementation with its own `server.port`, database, controllers, and overlapping `/api/v1` routes. Its source is retained as reference, but no current root runtime wiring connects Mobile to it.

Confidence: HIGH

This is an intended-runtime decision from deployment and gateway evidence, not a claim that `cinemaAI` is deprecated.
