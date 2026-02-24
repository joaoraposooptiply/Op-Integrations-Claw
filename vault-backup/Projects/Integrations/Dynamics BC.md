---
tags: [integration, project, live]
integration: Dynamics BC
type: ERP
auth: OAuth2
status: 🟢 Live
updated: 2026-02-24
---

# Dynamics BC Integration

> Microsoft Dynamics 365 Business Central ERP integration.

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Dynamics BC → OP | 30 min |
| Suppliers | Dynamics BC → OP | 30 min |
| Sell Orders | Dynamics BC → OP | 30 min |
| Buy Orders | Dynamics BC ↔ OP | 30 min |
| Receipt Lines | Dynamics BC → OP | 30 min |

## Configuration
| Setting | Notes |
|---------|-------|
| client_id | OAuth2 |
| client_secret | OAuth2 |
| redirect_uri | OAuth2 |
| refresh_token | OAuth2 |

## Notes
- Full ERP integration with bidirectional buy order support
- Supports dimension mapping for financial entries
- Requires dimension validation against config company

---

## Target Reference

> Writing data FROM Optiply TO Dynamics BC

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-dynamics-bc](https://github.com/hotgluexyz/target-dynamics-bc) |
| **Auth Method** | OAuth2 — `client_id`, `client_secret`, `redirect_uri`, `refresh_token` |
| **Base URL** | Dynamics 365 Business Central API (OAuth2) |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| CustomerSink | `customers` | POST |
| VendorSink | `vendors` | POST |
| BillSink | `purchaseInvoices` | POST |
| BillPaymentSink | `vendorPayments` | POST |
| JournalEntrySink | `generalJournalLines` | POST |

### Error Handling
- Custom `DynamicsClient` with reference data loading

### Quirks
- Loads `tenant-config.json` from `snapshot_dir` for dimension mappings
- Requires dimension validation against config company
- Supports dimension mapping: `class` → `CLASS`, `department` → `DEPARTMENT`

---

## Links
- Target: [target-dynamics-bc](https://github.com/hotgluexyz/target-dynamics-bc)
