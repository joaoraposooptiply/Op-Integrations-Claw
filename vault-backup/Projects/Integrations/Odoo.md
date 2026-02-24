---
tags: [integration, project, live]
integration: Odoo
type: ERP
auth: XML-RPC (url, db, username, password)
status: 🟢 Live
updated: 2026-02-24
---

# Odoo Integration

> Uses XML-RPC API — problematic for debugging. Mostly full syncs.

## Sync Board (all 30 min, BO export 15 min)
| Entity | Direction |
|--------|-----------|
| Products + Deletions + Stocks | Odoo → OP |
| Product Compositions | Odoo → OP |
| Suppliers | Odoo → OP |
| Supplier Products + Deletions | Odoo → OP |
| Sell Orders + Deletions | Odoo → OP |
| Sell Orders POS | Odoo → OP (if flag) |
| Buy Orders + Lines (CRUD) | Odoo ↔ OP |
| Receipt Lines | Odoo → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `use_templates` | — | Create products from templates |
| `sell_price_with_taxes` | false | Include taxes in price |
| `sync_purchase_price` | — | Sync purchase prices |
| `average_purchase_price` | — | Sync avg cost on SP |
| `pullAllOrders` | false | All statuses or only "sale" |
| `map_preferred` | false | Sync preferred supplier |
| `language` | en_US | Language for product names |
| `map_sellOrdersPOS` | false | Sync POS orders |
| `map_stockLevel` | available_quantity | Field for stock |
| `export_BOLine_price` | true | Send line price (required Odoo v18+) |
| `bo_completed_on_receipt` | false | Complete BO on full receipt |

## Product Mapping
| Optiply | Odoo |
|---------|------|
| name | product.name (in configured language) |
| skuCode | default_code |
| articleCode | product.code |
| price | product.price (or tax_string) |
| stockLevel | stock.available_quantity |
| status | active=true → enabled |
| assembled | bom_count > 0 |

- Only syncs Product.Type=Product (+ Consu if is_Storable exists and true)

## Compositions: from MRP BOM lines (production module)
## Suppliers: display_name, email_normalized, ID
## Supplier Products: remoteId = supplierId_productId, deliveryTime=delay, preferred by supplier_id

## Sell Orders (+ POS)
- Regular: amount_untaxed, date_order
- POS: amount_total, date_order
- Default: only status="sale"

## Buy Orders (bidirectional)
- Odoo → OP: status purchase/done, completed on "done"/"closed"
- OP → Odoo: partner_id=supplier, name=buyOrderId

## Receipt Lines: from purchase.order.line (qty + date)

## Links
- Tap: [tap-odoo](https://gitlab.com/hotglue/tap-odoo)
- Target: [target-odoo-v3](https://github.com/hotgluexyz/target-odoo-v3)
- ETL: `optiply-scripts/import/Odoo/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2433482756)
