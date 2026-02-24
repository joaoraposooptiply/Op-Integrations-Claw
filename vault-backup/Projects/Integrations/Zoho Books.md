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

## Links
- Tap: [tap-zoho](https://gitlab.com/hotglue/tap-zoho)
- Target: [target-zohobooks-v2](https://gitlab.com/hotglue/target-zohobooks-v2)
- ETL: `optiply-scripts/import/zohobooks/etl.ipynb`
- API: [API v3](https://www.zoho.com/books/api/v3/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2299428865)
