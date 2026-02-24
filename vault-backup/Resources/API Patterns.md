---
tags: [patterns, api, reference]
updated: 2026-02-24
---

# API Patterns

> Auth, pagination, and rate limiting patterns encountered across integrations.
> Populated as we build each integration.

## Auth Patterns
| Pattern | Example Platforms | Notes |
|---------|-------------------|-------|
| OAuth2 Refresh | | Token refresh flow |
| OAuth2 Client Credentials | | Machine-to-machine |
| API Key (header) | | `Authorization: Bearer <key>` |
| API Key (query string) | | `?api_key=<key>` |
| Basic Auth | | `Authorization: Basic base64(user:pass)` |
| OAuth1 HMAC | | Signature-based |
| XML-RPC | | SOAP/XML based |

## Pagination Patterns
| Pattern | Example Platforms | Notes |
|---------|-------------------|-------|
| Offset/Limit | Optiply | `page[offset]=X&page[limit]=Y` |
| Cursor-based | | `next_cursor` in response |
| Link header | | `Link: <url>; rel="next"` |
| Page number | | `?page=2` |

## Rate Limiting Patterns
| Pattern | Example Platforms | Notes |
|---------|-------------------|-------|
| Retry-After header | | Respect the header value |
| X-RateLimit-* headers | | Track remaining quota |
| Fixed delay | | e.g., 1 req/sec |
| Leaky bucket | | Token bucket algorithm |

---

*Updated as each integration is built.*
