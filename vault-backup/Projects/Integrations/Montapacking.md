---
tags: [integration, project, live]
integration: Montapacking
type: WMS/Fulfillment
status: 🟢 Live
updated: 2026-02-24
---

# Montapacking Integration

> Two flavours: **Simple** (BO + Receipts only) and **Full** (all entities).

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board
### Simple (1st flavour)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Buy Orders | OP → Monta | 15 min |
| Buy Orders | Monta → OP | 30 min |
| Receipt Lines | Monta → OP | 30 min |

### Full (2nd flavour — adds these)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Monta → OP | 30 min |
| Suppliers | Monta → OP | 30 min |
| Supplier Products | Monta → OP | 30 min |
| Sell Orders | Monta → OP | 30 min |

**Important (Simple):** Customer must put Optiply supplier IDs into Monta Supplier Codes manually.

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `use_StockInTransit` | false | Add transit stock to stockLevel |
| `sync_minimum_stock` | false | Map MinimumStock |
| `use_return_forecasts` | false | Add return forecast to stock |
| CustomField1 for SP name | off | Alternative name mapping |
| `sync_leadTime_supProducts` | false | Sync LeadTime |
| `del_bol_completed` | false | Delete approved-but-unreceived BOLs |

## Product Mapping
| Optiply | Monta |
|---------|-------|
| name | Description |
| skuCode | Sku |
| eanCode | Barcodes[0] |
| price | SellingPrice |
| stockLevel | StockAvailable (+StockInTransit if flag) (+returns if flag) |
| minimumStock | MinimumStock (if flag) |
| remoteId | productId |

**Note:** Inactive products on Monta stop syncing — status change NOT reflected on OP automatically.

## Suppliers: name=Title, email=AddressEmail, remoteId=Code

## Supplier Products
- **Only 1 supplier per product** in Monta
- If supplier changes → delete old SP + create new
- price=PurchasePrice, lotSize=PurchaseStepQty
- weight=WeightGrammes, volume=(L×W×H)/1000
- deliveryTime=LeadTime

## Sell Orders
- totalValue=0, placed=Received, completed=Shipped (or Received if no Shipped)
- Monta max 1 year pull per job
- Deletions synced (Deleted:true)
- subtotalValue=0 on lines

## Buy Orders (OP → Monta)
- Maps as InboundForecastGroup
- DeliveryDate = placed + supplier.deliveryTime
- Lines sorted by skuCode ascending

## Receipt Lines
- Mapped from InboundForecast.ReceivedQuantity
- Only quantities > 0

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `https://api-v6.monta.nl` |
| **Auth Method** | Basic Auth (`username` + `password`) |
| **Pagination** | Page number (`?page=N`) |
| **Rate Limiting** | Backoff expo (base 2, factor 3, max 7 tries), explicit timeout 300s |

### Endpoints

| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| products | GET | `/products` | Page |
| products_stock | GET | `/products_stock` | Page |
| inbounds | GET | `/inbounds` | Page |
| inboundforecast | GET | `/inboundforecast/group` | Page |
| productrule | GET | `/productrule` | Page |
| supplier | GET | `/supplier` | Page |
| order | GET | `/order` | Page |
| returnforecast | GET | `/returnforecast` | Page |
| product_events | GET | `/product/events/since_id/{last_eventId}` | Cursor |
| inbound_events | GET | `/inboundforecast/events/since_id/{last_eventId}` | Cursor |

### Error Handling
- Extra retry: 429, 401
- 404 returns empty (not fatal)
- 5xx → RetriableAPIError

### Quirks
- Subtracts 1 hour from replication_key value (timezone workaround)
- Configurable sync flags: `sync_products`, `sync_suppliers`, `sync_sell_orders`, `sync_buy_orders`, `sync_receipts`, `use_return_forecast`
- Handles "No groups found for these filters" gracefully (terminates pagination)
- `_write_state_message` clears partitions for non-replication-key streams

## Target Reference

> Writing data FROM Optiply TO Montapacking

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-montapacking-v2](https://github.com/hotgluexyz/target-montapacking-v2) |
| **Auth Method** | Basic Auth — `username`:`password` base64 encoded |
| **Base URL** | `https://api-v6.monta.nl/` |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| InboundForecastSink | (not specified) | POST |
| UpdateInventory | (not specified) | POST |

### Error Handling
- 429 + 500-599 → `RetriableAPIError`
- 400 with "InvalidReasons" → `InvalidPayloadError`
- 401 with "Unauthorized" → `InvalidCredentialsError`
- 400-499 → `FatalAPIError`

### Quirks
- Uses `hotglue_singer_sdk` with `AlertingLevel.WARNING`
- Custom exception types from `hotglue_etl_exceptions`

---

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Old (most full-featured old-pattern ETL) |
| **Entities** | Products, Suppliers, SupplierProducts, SellOrders, BuyOrders, ReceiptLines |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `second_flavor` | — | Full product/supplier sync vs buy orders only |
| `sync_prod_stock_only` | false | Stock-only sync mode |
| `upload_stocks_to_parent` | false | Subtenant stock upload |
| `use_StockInTransit` | false | Include in-transit stock |
| `use_return_forecast` | false | Adjust for returns |
| `sync_minimum_stock` | false | Sync minimum stock |
| `map_stockLevel` | true | Include stock in diff check |
| `sp_name_customField1` | — | Custom field mapping |
| `sync_leadTime_supProducts` | false | Lead time sync |
| `del_bol_completed` | false | Delete BOL for completed |
| `force_patch_products` | false | Force patch all products |
| `force_patch_supplier_products` | false | Force patch all SPs |

### Custom Logic
- **Two flavors**: First flavor (buy orders only) vs second flavor (full sync)
- **Stock-only mode**: Only sync stock changes, not full products
- **Stock in transit**: Includes StockInTransit in stockLevel
- **Return forecast**: Adjusts stock with return forecasts
- **Inbound forecast**: Maps `inboundforecast` and `inbounds` to buy orders and receipt lines
- Supplier product 409 handling (duplicate detection)

---

## Links
- Tap: [tap-montapacking](https://gitlab.com/hotglue/tap-montapacking)
- Target: [target-montapacking-v2](https://github.com/hotgluexyz/target-montapacking-v2)
- ETL: `optiply-scripts/import/montapacking/etl.ipynb`
- API: [API v6](https://api-v6.monta.nl/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301886535)
