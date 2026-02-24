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

## Links
- Tap: [tap-zoho-inventory](https://github.com/hotgluexyz/tap-zoho-inventory)
- Target: [target-zoho-inventory](https://github.com/hotgluexyz/target-zoho-inventory)
- ETL: `optiply-scripts/import/zoho-inventory/`
- API: [API v1](https://www.zoho.com/inventory/api/v1/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2412380174)
