---
tags: [integration, project, live]
integration: Tilroy
type: Retail/POS
auth: API Key
status: 🟢 Live (target untested)
updated: 2026-02-24
---

# Tilroy Integration

> Belgian fashion/retail POS. Multi-language, multi-shop, SKU-level (colour/size variants).

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]
> ⚠️ Target is NOT tested/done.

## Sync Board (all 30 min)
| Entity | Direction |
|--------|-----------|
| Products + Deletions | Tilroy → OP |
| Suppliers | Tilroy → OP |
| Supplier Products | Tilroy → OP |
| Sell Orders | Tilroy → OP |
| Buy Orders + Lines | Tilroy ↔ OP |
| Receipt Lines | Tilroy → OP |

Not synced: Product Compositions, Supplier Deletions

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `languageCode` | "NL" | Product name language (NL/FR/EN) |
| `shop_ids` | "" (all) | Filter stock/prices/sales by shop IDs |
| `use_product_details` | false | Richer SKU data but only 1 supplier/product |

## Product Mapping
- name = description[lang].standard + " - " + size.code
- skuCode = colours.skus.tilroyId
- eanCode = colours.skus.barcodes.code
- price = best current price (promo if cheaper, else standard)
- stockLevel = qty.available (shop-filterable, summed)
- remoteId = tilroyId + "_" + skuTilroyId

## Suppliers: name, code as remoteId, deliveryTime (0 treated as null)
## Supplier Products: price=costPrice, remoteId=tilroyId+skuCode+supplierId
## Sell Orders: totalValue=vat.amountNet, placed=saleDate, shop-filterable

## Buy Orders (bidirectional)
## Receipt Lines: from Tilroy

## API Reference

### Base URL
`https://api.tilroy.com` (configurable via `api_url`)

### Auth Method
Dual API keys: `Tilroy-Api-Key` + `x-api-key` passed as headers.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| Shops | GET | `/shopapi/production/shops` | Page-based |
| Products | GET | `/products` | Page-based |
| ProductDetails | GET | `/product_details` | Page-based |
| PurchaseOrders | GET | `/purchase_orders` | Page-based |
| Sales | GET | `/sales` | Page-based |
| Stock | GET | `/stock` | Page-based |
| StockChanges | GET | `/stock_changes` | Page-based |
| Prices | GET | `/prices` | Page-based |
| Transfers | GET | `/transfers` | Page-based |
| Suppliers | GET | `/suppliers` | Page-based |

Pagination: `X-Paging-CurrentPage` / `X-Paging-PageCount` headers. Default count=100.

### Rate Limiting
- 429 handled with `Retry-After` header
- Retries 504, 408, 5xx
- Max 8 tries

### Error Handling
- `RetriableAPIError` for 429/504/408/5xx
- `FatalAPIError` for 4xx

### Quirks
- Date-windowed sync for large ranges (default 7-day windows)
- Shop ID/number resolution from `/shops` endpoint
- Integer fields preserved (no .0 floats)
- Nested objects flattened or stringified

## Target Reference

> Writing data FROM Optiply TO Tilroy

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-tilroy](https://github.com/joaoraposooptiply/target-tilroy.git) ⚠️ untested |
| **Auth Method** | Custom header — `Tilroy-Api-Key` |
| **Base URL** | `https://api.tilroy.com` |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| PurchaseOrderSink | `/purchaseapi/production/import/purchaseorders` | POST |

### Error Handling
- Relies on base `HotglueSink` error handling

### Quirks
- Requires `warehouse_id` in config
- Payload structure: `orderDate`, `requestedDeliveryDate`, `supplierReference`, `lines[]`
- Line items contain nested `sku.tilroyId`, `qty.ordered`, `warehouse.number`

---

## ETL Summary

**Pattern:** OLD

**Entities Processed:**
- Products
- Suppliers
- SupplierProducts
- SellOrders (from sales)
- SellOrderLines
- BuyOrders (from purchase_orders)
- BuyOrderLines
- ReceiptLines (from purchase_orders)

**Key Config Flags:**
| Flag | Default | Purpose |
|------|---------|---------|
| `languageCode` | "NL" | Language for processing |
| `shop_ids` | "" | Filter by shop IDs |
| `shop_numbers` | "" | Filter by shop numbers |

**Custom Logic Highlights:**
- Stock extracted via `_extract_stock_like_df()` helper function
- Supports both `stock` and `stock_changes` streams
- Prices from separate `prices` stream
- Language-specific processing via `languageCode`

---

## Links
- Tap: [tap-tilroy](https://github.com/joaoraposooptiply/tap-tilroy.git)
- Target: [target-tilroy](https://github.com/joaoraposooptiply/target-tilroy.git) ⚠️ untested
- ETL: `optiply-scripts/import/tilroy/etl.ipynb`
- API: [API Overview](https://tilroy-dev.atlassian.net/wiki/spaces/TAD/pages/870481921)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3218735105)
