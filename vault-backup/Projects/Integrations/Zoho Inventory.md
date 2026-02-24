---
tags: [integration, project, live]
integration: Zoho Inventory
type: ERP/Inventory
auth: OAuth2 (region-specific)
status: 🟢 Live
updated: 2026-02-24
---

# Zoho Inventory Integration

> Full ERP integration with Product Compositions, Assembly/Production Orders support.

## Sync Board (all 60 min, BO export 15 min)
| Entity | Direction |
|--------|-----------|
| Products + Deletions | Zoho → OP |
| Product Compositions | Zoho → OP |
| Suppliers | Zoho → OP |
| Supplier Products | Zoho → OP |
| Sell Orders | Zoho → OP |
| Buy Orders + Lines + Deletions | Zoho ↔ OP |
| Receipt Lines | Zoho → OP |
| Assembly/Production Orders | Zoho ↔ OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `Sync_Stock` | true | Disable stock sync |
| `warehouse_ids` | allWarehouses | Filter stock by warehouse |
| `Sync_Assembled` | false | Sync composed products |
| `pullAllOrders` | true | All except draft, or only "closed" |
| `export_warehouse_id` | null | Send assemblies to specific warehouse |

## Product Mapping
- name, sku, rate, purchase_description as articleCode
- status: goods + inventory + active → enabled
- stockLevel=actual_available_for_sale_stock
- assembled=is_combo_product
- Compositions from /compositeitems

## Suppliers: contact_type="vendor" only, name=contact_name
## Supplier Products: price=purchase_rate, vendor_id, item_id

## Sell Orders: total, date, salesorder_id
## Buy Orders (bidirectional): completed on "closed" status
## Assembly Orders: bidirectional, export to specific warehouse

## API Reference

### Base URL
`https://www.zohoapis.{domain}/inventory/v1` (domain: com, eu, in, au, ca)

### Auth Method
OAuth2 with refresh_token. Domain derived from accounts-server config. Token auto-refreshed via authenticator.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| Products | GET | `/Products` | Page-based |
| SalesOrders | GET | `/SalesOrders` | Page-based |
| PurchaseOrders | GET | `/PurchaseOrders` | Page-based |
| Suppliers | GET | `/Suppliers` | Page-based |
| PurchaseReceives | GET | `/PurchaseReceives` | Page-based |
| CompositeItems | GET | `/CompositeItems` | Page-based |
| AssemblyOrders | GET | `/AssemblyOrders` | Page-based |

Detail variants: each endpoint has a corresponding `/.../...` detail endpoint (e.g., `/salesorders/{salesorder_id}`)

### Rate Limiting
- 429 handling with `Retry-After` header parsing (supports seconds or HTTP-date)
- Sleeps for specified time
- Backoff via `backoff.expo(base=3, factor=6)`

### Error Handling
- 429 → `RetriableAPIError` + backoff
- 5xx → `RetriableAPIError`
- 4xx → `FatalAPIError`

### Quirks
- Custom fields fetched from `/settings/preferences/` and moved to root level
- 1s sleep between detail requests
- NA/empty string replacement
- Domain-based URL selection

---

## ETL Summary

**Pattern:** OLD

**Entities Processed:**
- Products
- ProductCompositions
- Suppliers
- SupplierProducts
- SellOrders
- BuyOrders
- BuyOrderLines
- ReceiptLines
- AssemblyOrders

**Key Config Flags:**
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllSellOrders` | false | Pull all sell orders |
| `Sync_Stock` | true | Disable stock sync |
| `warehouse_ids` | allWarehouses | Filter stock by warehouse |
| `Sync_Assembled` | false | Sync composed products |
| `export_warehouse_id` | null | Send assemblies to specific warehouse |

**Custom Logic Highlights:**
- Different flag naming: `pullAllSellOrders` (not `pullAllOrders`)
- Assembly/Production Orders support
- Product compositions from `/compositeitems` endpoint

---

## Links
- Tap: [tap-zoho-inventory](https://github.com/hotgluexyz/tap-zoho-inventory)
- Target: [target-zoho-inventory](https://github.com/hotgluexyz/target-zoho-inventory)
- ETL: `optiply-scripts/import/zoho-inventory/`
- API: [API v1](https://www.zoho.com/inventory/api/v1/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2412380174)
