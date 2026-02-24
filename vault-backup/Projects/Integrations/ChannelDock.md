---
tags: [integration, project, live]
integration: ChannelDock
type: Marketplace/Channel
auth: Custom headers (api_key + api_secret)
status: 🟢 Live
updated: 2026-02-24
---

# ChannelDock Integration

> Marketplace channel integration for buy order synchronization.

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Buy Orders | OP → ChannelDock | 15 min |

## Configuration
| Setting | Notes |
|---------|-------|
| api_key | Custom headers |
| api_secret | Custom headers |
| url_base | Default: `https://channeldock.com/portal/api/v2` |

## Notes
- ChannelDock is a marketplace channel that receives buy orders from Optiply
- Simple integration focused on order export

---

## Target Reference

> Writing data FROM Optiply TO ChannelDock

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-channeldock](https://github.com/hotgluexyz/target-channeldock) |
| **Auth Method** | Custom headers — `api_key`, `api_secret` |
| **Base URL** | `https://channeldock.com/portal/api/v2` (configurable via `url_base`) |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| BuyOrdersSink | (not specified) | POST |

### Error Handling
- `backoff.expo` with max 5 tries on `RetriableAPIError`, `ReadTimeout`
- 429, 500-504 → `RetriableAPIError`
- All others → `raise_for_status()`

### Quirks
- Logs both request payload and response for debugging
- Simple header-based auth (non-standard)

---

## Links
- Target: [target-channeldock](https://github.com/hotgluexyz/target-channeldock)
