---
tags: [integration, project, live, gold-standard]
integration: Sherpaan
type: WMS/Logistics
auth: SOAP/asmx
status: 🟢 Live (IN PROGRESS docs)
updated: 2026-02-24
---

# Sherpaan Integration

> ★ **Gold standard** — most recent, uses new Generic ETL template patterns.
> API is SOAP/XML (asmx endpoints), not REST.

## Sync Board (all 60 min)
| Entity | Direction |
|--------|-----------|
| Products + Compositions | Sherpaan → OP |
| Suppliers | Sherpaan → OP |
| Supplier Products | Sherpaan → OP |
| Sell Orders (+ deletions) | Sherpaan → OP |
| Buy Orders + Lines | Sherpaan ↔ OP |
| Receipt Lines | Sherpaan → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `stock_warehouse_codes` | all | Filter stock by warehouse codes |
| `warehouse_group_code` | None | Single warehouse group for stock |
| `not_sync_suppliers_attributes` | None | Skip specific supplier fields |
| `not_sync_supProds_attributes` | None | Skip specific SP fields |
| `pullAllOrders` | true | All or only "Processed" |
| `sellOrders_warehouse_codes` | all | Filter SOs by warehouse |
| `buyOrders_warehouse_codes` | all | Filter BOs by warehouse |

## Product Mapping (SOAP: ChangedItemsInformation + ChangedStock)
- Only ItemType=Stock or Assembly
- name=Description, skuCode=ItemCode, eanCode=EanCodes[0]
- status: Active → enabled
- assembled: Assembly → true
- remoteId=ItemCode (not numeric ID)

## Compositions: from ItemAssemblies, remoteId=CONCAT(parent+part ItemCode)

## Suppliers (SOAP: ChangedSuppliers + SupplierInfo)
- name=CONCAT(Company, Name), remoteId=SupplierCode
- deliveryTime=DeliveryPeriod, userReplenishmentPeriod=OrderPeriod, emails=Email

## Supplier Products (SOAP: ChangedItemSuppliersWithDefaults)
- price=SupplierPrice, skuCode=SupplierItemCode
- deliveryTime=DeliveryPeriod, minimumPurchaseQuantity=MinPurchaseQty

## Sell Orders
- Cancelled status → delete
- No SO line deletions

## Buy Orders (bidirectional)
- Warehouse-filterable

## Links
- Tap: [tap-sherpaan](https://github.com/Optiply/tap-sherpaan.git)
- Target: [target-sherpaan](https://github.com/joaoraposooptiply/target-sherpaan.git)
- ETL: `optiply-scripts/import/sherpaan/etl.ipynb`
- API: [SOAP/asmx](https://sherpaservices-prd.sherpacloud.eu/406/Sherpa.asmx)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3170369561)
