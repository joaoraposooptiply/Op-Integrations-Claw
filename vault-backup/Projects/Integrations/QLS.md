---
tags: [integration, project, live]
integration: QLS
type: Logistics/Fulfillment
status: 🟢 Live
updated: 2026-02-24
---

# QLS Integration

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | QLS → OP | 30 min |
| Product Stock only | QLS → OP | 10 min (if stock-only mode) |
| Suppliers | QLS → OP | 30 min |
| Supplier Products + Deletions | QLS → OP | 30 min |
| Sell Orders | QLS → OP | 30 min |
| Buy Orders (v1 or v2) | QLS ↔ OP | 30 min in / 15 min out |
| Receipt Lines (v1 or v2) | QLS → OP | 30 min |

- Product deletions NOT synced (no way to identify from QLS)
- Has v1 and v2 for Buy Orders / Receipt Lines

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_prod_stock_only` | false | Only pull stock, no other data |
| `use_supplier_products` | true | Sync SPs from QLS |

## Product Mapping
| Optiply | QLS |
|---------|-----|
| name | name |
| skuCode | sku |
| eanCode | ean (**mandatory for BO export**) |
| price | price_store |
| assembled | bundle_product (true if non-empty array) |
| stockLevel | amount_available - amount_backorder + amount_internally_moving |
| createdAtRemote | created |

## Suppliers: name, remoteId=id

## Supplier Products
- Multiple suppliers per product supported
- price=price_cost (same for all SPs of a product)
- lotSize from order_unit or product_master_cartons.amount (min value)
- articleCode=suppliers._joinData.supplier_code

## Sell Orders
- totalValue=sum of line subtotals, placed=createdAt
- No order updates synced

## Buy Orders (bidirectional)
- **v1:** completed when status="completed"
- **v2:** completed when status="archived", BOL changes synced
- Export: customer_reference=buyOrderId, lines sorted by skuCode
- Supplier mapped by name (get ID from name)

## Receipt Lines
- quantity=amount_received, occurred=created
- v2 exists alongside v1

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `https://api.pakketdienstqls.nl/companies/{company_id}` (v2 also available) |
| **Auth Method** | Basic Auth (`username` + `password`) |
| **Pagination** | Page number via `pagination.nextPage` |
| **Rate Limiting** | Backoff, explicit `Retry-After` header handling (429) |

### Endpoints

| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| fulfillment_products | GET | `/fulfillment/products` | Page |
| fulfillment_orders | GET | `/fulfillment/orders` | Page |
| fulfillment_purchase_orders | GET | `/fulfillment/purchase-orders` | Page |
| suppliers | GET | `/suppliers` | Page |
| products_stock | GET | `/fulfillment/products/stock` | Page |
| purchase_orders | GET | `/purchase-orders/` | Page |
| fulfillment_orders_v2 | GET | `/fulfillment-orders` | Page |
| fulfillment_products_v2 | GET | `/fulfillment-products` | Page |

### Error Handling
- Extra retry: 429, 101
- 404/204 gracefully handled
- 400-499 → FatalAPIError (except 404/204)

### Quirks
- Has v2 API variant (`QlsV2Stream`) with different param names
- Date filtering: `modified_less_than`, `modified_greater_than`, `created_less_than`, `created_greater_than`
- For orders: uses date overlap (not replication_key_value), falls back to sort by id
- Replication key subtracts 180 days for full sync date range
- Configurable sync flags: `sync_supplier_products`
- Timeout: 3600s (1 hour)
- QlsV2: handles "Page number out of range" 400 error gracefully

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Old (uses v2 endpoints) |
| **Entities** | Suppliers, Products, SellOrders (v2), SellOrderLines, BuyOrders (v1/v2), BuyOrderLines (v1/v2), ReceiptLines (v2) |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_prod_stock_only` | false | Only pull stock, no other data |
| `use_supplier_products` | true | Sync SPs from QLS |

### Custom Logic
- Has dual version support: v1 and v2 for orders/buy orders
- Orders extracted from `sell_orders_v2`
- Buy orders from multiple streams: `buy_orders`, `buy_orders_v2`, `buy_orders_by_id`, `buy_orders_by_id_v2`
- Receipt lines from `receipt_lines` and `buy_orders_by_id_v2`

---

## Links
- Tap: [tap-qls](https://gitlab.com/hotglue/tap-qls)
- Target: [target-qlsv2](https://github.com/hotgluexyz/target-qlsv2)
- ETL: `optiply-scripts/import/qls/etl.ipynb`
- API: [Swagger](https://api.pakketdienstqls.nl/swagger/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853930)
