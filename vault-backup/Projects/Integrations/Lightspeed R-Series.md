---
tags: [integration, project, live]
integration: Lightspeed R-Series
type: Retail/POS
auth: OAuth2
status: 🟢 Live
updated: 2026-02-24
---

# Lightspeed R-Series Integration

> Retail POS. Multi-location, bidirectional, supports compositions.

## Sync Board (all 30 min)
| Entity | Direction |
|--------|-----------|
| Products + Compositions | LS-R → OP |
| Suppliers | LS-R → OP |
| Supplier Products | LS-R → OP |
| Sell Orders | LS-R → OP |
| Buy Orders + Lines | LS-R ↔ OP |
| Receipt Lines | LS-R → OP |

## Config
| Setting | Notes |
|---------|-------|
| Account ID | Unique admin account ID |
| Default Location Code | Main location for BO export (case-sensitive) |
| Get Data From | All Locations / Multiple (comma-separated) / One (default) |
| Sync All Sales Orders | Default: only completed. Enable for all statuses. |

## Product Mapping
- name=description, skuCode=customSku (fallback systemSku)
- price=Prices.Default.amount, stockLevel=qoh per shop
- status: archived=true → disabled
- assembled: itemType "assembly" or "box"
- minimumStock=reorderPoint
- Item types: default, non_inventory (filtered out), assembly, box

## Compositions: assemblyItemID → composedProduct, componentItemID → partProduct

## Suppliers: Vendor.json, name+vendorID

## Supplier Products: from vendor items

## Sell Orders: by location, completed or all statuses

## Buy Orders (bidirectional)
- Export to specific location (Default Location Code)

## Troubleshooting (from Confluence)
- Products not syncing → check item type isn't non_inventory
- Sales orders missing → check Sync All Sales Orders flag
- BO not creating in LS → verify location code (case-sensitive)
- Stock incorrect → verify location selection

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `https://api.lightspeedapp.com/API/V3` |
| **Auth Method** | OAuth 2.0 (refresh_token grant) with auto-refresh on 401 |
| **Pagination** | Cursor-based via `@attributes.next` URL (if present) |
| **Rate Limiting** | Backoff on connection errors (ChunkedEncodingError, ProtocolError, ReadTimeoutError) |

### Endpoints

| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| Account | GET | `/Account.json` | — |
| Item | GET | `/Account/{accountID}/Item.json` | Cursor |
| Vendor | GET | `/Account/{accountID}/Vendor.json` | Cursor |
| Order | GET | `/Account/{accountID}/Order.json` | Cursor |
| Sale | GET | `/Account/{accountID}/Sale.json` | Cursor |
| Shipment | GET | `/Account/{accountID}/Shipment.json` | Cursor |
| Shop | GET | `/Account/{accountID}/Shop.json` | Cursor |

### Error Handling
- 401 → force token refresh + retry
- 400 with "Please try again later" → RetriableAPIError
- 5xx + 401 → RetriableAPIError

### Quirks
- OAuth token refresh writes new tokens to config file automatically
- Supports configurable relations for items/vendors/orders/sales/shipments
- Supports `account_id` filter to sync specific account only
- Replication uses `timeStamp>=,YYYY-MM-DDTHH:MM:SS-00:00` filter

## Target Reference

> Writing data FROM Optiply TO Lightspeed R-Series

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-lightspeed-r-series](https://gitlab.com/mariocosta_opt/target-lightspeed-r-series.git) |
| **Auth Method** | OAuth2 — `refresh_token`, `client_id`, `client_secret` → `/auth/oauth/token` |
| **Base URL** | `https://api.lightspeedapp.com/API/V3/Account/{account_ids}` |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| BuyOrders | (not specified) | POST |

### Error Handling
- `backoff.expo` with max 5 tries, max 300s total
- 429 handled with `Retry-After` header parsing (defaults to 60s)
- Rate limiting: max 3 req/s enforced via `_rate_limit()`

### Quirks
- **Rate limiting is critical** — class-level `_last_request_time` tracking
- Explicit `MIN_REQUEST_INTERVAL = 0.5s` (2 req/s conservative)
- Supports `full_url` override in config

---

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Generic ETL (uses `utils.payloads` + `utils.actions`) |
| **Entities** | Products, ProductCompositions (BOM/assemblies), Suppliers, SupplierProducts, SellOrders, SellOrderLines, BuyOrders, BuyOrderLines, ReceiptLines |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `stock_warehouse_option` | "one_warehouse" | Warehouse selection mode |
| `stock_warehouse_ids` | — | Comma-separated shop IDs |
| `default_shop_name` | — | Warehouse code |
| `sync_all_orders` | false | Sync all statuses (not just completed) |
| `buyorders_shop_id` | — | Auto-populated from default shop |

### Custom Logic
- **Warehouse filtering**: `parse_warehouse_codes()` function (one/multiple/all)
- **Force patch flags** from state.json: `force_patch_supplier_products`, `force_patch_products`
- **Product compositions** (BOM): Handles assembly/box item types, marks parent as `assembled=True`
- **Supplier products**: Complex concat_ids = `productId_supplierId`, handles supplier changes (delete + recreate), 409 conflict handling

---

## Links
- Tap: [tap-lightspeed-rseries](https://github.com/mariocostaoptiply/tap-lightspeed-rseries.git)
- Target: [target-lightspeed-r-series](https://gitlab.com/mariocosta_opt/target-lightspeed-r-series.git)
- ETL: `optiply-scripts/import/LightSpeed_r_series/etl.ipynb`
- API: [Retail API](https://developers.lightspeedhq.com/retail/introduction/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3422748673)
