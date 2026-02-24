---
tags: [integration, project, live]
integration: Zoho Books
type: ERP
auth: OAuth2 (region-specific)
status: 🟢 Live
updated: 2026-02-24
---

# Zoho Books Integration

> Two flavours: **Simple** (Products + SO) and **Full** (+ Suppliers + SP + BO bidirectional).

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board (all hourly, BO export 15 min)
### Simple
Products + Sell Orders only

### Full (adds)
Suppliers, Supplier Products, Buy Orders (bidirectional)

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| Zoho Region | — | Company's Zoho region |
| `sync_stock` | true | Disable stock sync |
| `warehouse_ids` | null | Filter stock by warehouse IDs |
| Salesperson ID exclusion | null | Exclude SOs by salesperson (e.g., AMZN,WLMT) |

## Product Mapping
| Optiply | Zoho Books |
|---------|------------|
| name | name |
| skuCode | sku |
| price | rate |
| remoteId | item_id |
| stockLevel | available_for_sale_stock |
| status | product_type=goods AND active → enabled |
| unlimitedStock | digital/service → true |

## Suppliers: vendor_name, email, remoteId=contact_id
## Supplier Products: price=purchase_rate, supplierId=vendor_id

## Sell Orders
- Default: only invoiced/partially invoiced/closed
- totalValue=total, placed=date
- Can exclude by salesperson ID

## Buy Orders (bidirectional)
- Zoho → OP: filter not billed/cancelled, totalValue=total×exchange_rate
- OP → Zoho: reference_number=buyOrderId

## API Reference

### Base URL
`www.zohoapis.com` (default) — domain-based: `zohoapis.eu`, `zohoapis.in`, `zohoapis.com.au`, `zohoapis.com.cn` (based on `location` config)

### Auth Method
OAuth2 with refresh token using Zoho SDK (`ZohoOAuthClient`). Token persisted in `.pkl` file. Supports sandbox mode.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| Products | GET | Dynamic (CRM modules) | Modified_Time (incremental) |
| Sales_Orders | GET | Dynamic | Modified_Time or BULK API |
| Purchase_Orders | GET | Dynamic | Modified_Time or BULK API |
| Vendors | GET | Dynamic | Modified_Time |
| Invoices | GET | Dynamic | Modified_Time |
| Accounts | GET | Dynamic | Modified_Time |
| Contacts | GET | Dynamic | Modified_Time |

Full modules: Activities, Accounts, Leads, Contacts, Deals, Tasks, Calls, Products, Quotes, Sales_Orders, Purchase_Orders, Invoices, Vendors, Price_Books, Cases, Solutions, Users. Plus custom views.

### Rate Limiting
- Checks `X-Rate-Limit-Remaining` / `X-API-CREDITS-REMAINING` headers
- Raises `RetriableAPIException` when limit hits 0

### Error Handling
- Custom exceptions: `TapZohoException`, `TapZohoQuotaExceededException`, `RetriableAPIException`
- Backoff on `ConnectionError` (max 10 tries, factor 2)

### Quirks
- Uses `zcrmsdk` (Zoho CRM SDK)
- Supports both REST and BULK API modes
- Schema dynamically built from field definitions
- Lookup fields handled specially (`__id`, `__name` suffix)

---

## ETL Summary

**Pattern:** OLD

**Entities Processed:**
- Products
- Suppliers
- SupplierProducts
- SellOrders
- BuyOrders

**Key Config Flags:**
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllOrders` | true | Pull all orders |

**Custom Logic Highlights:**
- Minimal custom logic visible
- `pullAllOrders` flag controls order filtering
- Two flavors: Simple (Products + SO) and Full (+ Suppliers + SP + BO bidirectional)

---

## Links
- Tap: [tap-zoho](https://gitlab.com/hotglue/tap-zoho)
- Target: [target-zohobooks-v2](https://gitlab.com/hotglue/target-zohobooks-v2)
- ETL: `optiply-scripts/import/zohobooks/etl.ipynb`
- API: [API v3](https://www.zoho.com/books/api/v3/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2299428865)
