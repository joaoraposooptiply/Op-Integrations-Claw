---
tags: [integration, project, live, complex]
integration: NetSuite
type: ERP
auth: OAuth1 HMAC (Token-Based Auth)
status: 🟢 Live (ONGOING)
updated: 2026-02-24
---

# NetSuite Integration

## Sync Board (all 60 min, BO export 10 min)
| Entity | Direction |
|--------|-----------|
| Products + Stocks | NS → OP |
| Product Compositions (Kit) | NS → OP |
| Suppliers (Vendors) | NS → OP |
| Supplier Products + Deletions | NS → OP |
| Sell Orders | NS → OP |
| Buy Orders + Lines | NS ↔ OP |
| Receipt Lines | NS → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `stock_location_ids` | null | Filter stock by locations |
| `send_locationId` | null | Send BOs to specific location |

## Product Mapping
- Only syncs itemtype=InvtPart or Kit
- name=fullname, skuCode=custitem_cl_sku, eanCode=upccode
- price from Inventory_Item_Locations.price
- status: "Prepare" → disabled
- notBeingBought: "Ending"/"Ending (Supplier)"/"Offline/Order Item" → true
- assembled: Kit items + "Warranty/Part" status
- Stock filterable by location

## Compositions: Kit item members (parentitem → composedProduct, item → partProduct)
## Suppliers: Vendors only (active=true), fixedCosts=custentity_cl_shipping_amount, deliveryTime=custentity_cl_lead_time
## Supplier Products: remoteId=Concat(item+vendor), price=purchaseprice, lotSize=reordermultiple, preferred=preferredvendor

## Sell Orders: type=SalesOrd only, totalValue=foreigntotal, completed=closedate
## Buy Orders: type=PurchOrd, completed on "Fully Billed"/"Pending Bill"/"Closed"
## BO Export: memo=buyOrderId, dueDate=expectedDeliveryTime
## Receipt Lines: from item_receipt_lines, remoteId=uniquekey

## Links
- Tap: [tap-netsuite-rest](https://github.com/hotgluexyz/tap-netsuite-rest.git)
- Target: [target-netsuite-v2](https://github.com/hotgluexyz/target-netsuite-v2)
- ETL: `optiply-scripts/import/netsuite/etl.ipynb`
- API: [REST API](https://system.netsuite.com/help/helpcenter/en_US/APIs/REST_API_Browser/record/v1/2023.1/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3100180481)
