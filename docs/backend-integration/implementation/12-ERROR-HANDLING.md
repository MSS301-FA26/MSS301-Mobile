# Error Handling

| Condition | `ApiException.type` |
|---|---|
| 400 | `badRequest` |
| 401 | `unauthorized` |
| 403 | `forbidden` |
| 404 | `notFound` |
| 409 | `conflict` |
| 422 | `validation` |
| 429 | `tooManyRequests` |
| 500–599 | `server` |
| connect/send/receive timeout | `timeout` |
| connection error | `network` |
| cancelled request | `cancelled` |
| other/unclassified | `unknown` |

`ApiException` preserves status code, backend code, message, validation errors, and original cause. Backend envelopes are parsed defensively from either the response root or an `error` object; missing fields do not crash the mapper.
