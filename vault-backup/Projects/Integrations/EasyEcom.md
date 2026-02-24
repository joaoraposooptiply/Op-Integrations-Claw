---
tags: [integration, project, live]
integration: EasyEcom
type: E-commerce/WMS
auth: API Key
status: 🟢 Live
updated: 2026-02-24
---

# EasyEcom Integration

## Sync Board (all 30 min, BO export 10 min)
| Entity | Direction |
|--------|-----------|
| Products (no deletions) | EasyEcom → OP |
| Product Compositions | EasyEcom → OP |
| Suppliers | EasyEcom → OP |
| Supplier Products | EasyEcom → OP |
| Sell Orders | EasyEcom → OP |
| Buy Orders + Lines | EasyEcom ↔ OP |
| Receipt Lines (GRN) | EasyEcom → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `send_tax_rate` | false | Add tax to BO line prices on export |

## Product Mapping
- name=product_name, sku=sku, price=mrp, stockLevel=inventory
- assembled=cp_sub_products_count>0, remoteId=cp_id
- Compositions: from sub_products array

## Suppliers
- **Vendors** from getVendors endpoint
- **Locations** also mapped as suppliers (from products.company)

## Supplier Products: price=cost, supplierId=vendor_code

## Sell Orders
- All statuses except Canceled (id=9)
- totalValue=total_amount, placed=order_date

## Buy Orders (bidirectional)
- Completed when po_status_id in [4, 5, 7]
- Export: referenceCode=buyOrderId, vendorId=supplier_remoteId
- Lines: unitPrice can include tax if flag set

## Receipt Lines: from GRN (Goods Receipt Notes)
- quantity=received_quantity, occurred=grn_created_at

## Links
- Tap: [tap-easyecom](https://github.com/hotgluexyz/tap-easyecom)
- Target: [target-easyecom](https://github.com/hotgluexyz/target-easyecom)
- ETL: `optiply-scripts/import/EasyEcom/etl.ipynb`
- API: [API Docs](https://api-docs.easyecom.io/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2928476161)
