---
tags: [integration, project, live]
integration: QLS
type: Logistics/Fulfillment
status: 🟢 Live
updated: 2026-02-24
---

# QLS Integration

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

## Links
- Tap: [tap-qls](https://gitlab.com/hotglue/tap-qls)
- Target: [target-qlsv2](https://github.com/hotgluexyz/target-qlsv2)
- ETL: `optiply-scripts/import/qls/etl.ipynb`
- API: [Swagger](https://api.pakketdienstqls.nl/swagger/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853930)
