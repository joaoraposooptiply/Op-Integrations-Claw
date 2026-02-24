---
tags: [integration, project, live]
integration: Logic4
type: ERP
auth: Token per request
status: 🟢 Live
updated: 2026-02-24
---

# Logic4 Integration

## Sync Board (all every 2 hours)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Logic4 → OP | 2h |
| Suppliers | Logic4 → OP | 2h |
| Supplier Products | Logic4 → OP | 2h (bulk, detects deletions) |
| Stocks | Logic4 → OP | 2h |
| Sell Orders | Logic4 → OP | 2h |
| Buy Orders | Logic4 ↔ OP | 2h in / every 10min out |
| Receipt Lines | Logic4 → OP | 2h |

**Rate limits:** 200k calls/month per customer — may need to increase interval for big shops.

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `prod_disabled_statusIds` | null | Disable products by StatusId list |
| `IsVisibleOnWebShop` | true | Map status from visibility |
| `stock_warehouse_ids` | null | Filter stock by warehouses |
| `map_notBeingBought` | false | Sync notBeingBought from L4 |
| `notBeingBought_statusIds` | null | Set notBeingBought by StatusId |
| `map_purchase_price` | (must select) | BuyPrice or CreditorBuyPrice |
| `map_MOQ` | true | Sync MinBuyAmount |
| `map_lotSize` | true | Sync BuyCountIncrement |
| `sync_invoices` | false | Sync invoices as sell orders |
| `sellorders_create_statusIds` | null | Only create orders with these statuses |
| `sellorders_delete_statusIds` | null | Delete orders with these statuses |
| `export_BranchId` | null | Send BOs to specific branch |
| `send_OrderedOnDateByDistributor` | true | false = BOs appear as drafts |

## Product Mapping
| Optiply | Logic4 |
|---------|--------|
| name | Concat(ProductName1, ProductName2) |
| skuCode | ProductCode |
| articleCode | ProductId |
| price | SellPriceGross |
| unlimitedStock | always false |
| stockLevel | FreeStock (warehouse-filterable) |
| eanCode | BarCode1 |
| createdAtRemote | DateTimeAdded |
| assembled | IsComposedProduct OR IsAssembledProduct |

## Suppliers: name=CompanyName, remoteId=Id

## Supplier Products
| Optiply | Logic4 |
|---------|--------|
| name | Concat(ProductName1, ProductName2) |
| price | BuyPrice or CreditorBuyPrice (configurable) |
| skuCode | CreditorProductCode |
| preferred | IsActive (GetSuppliersForProduct) |
| lotSize | BuyCountIncrement |
| minimumPurchaseQuantity | MinBuyAmount |
| status | StatusId 1,10 → disabled |

## Sell Orders
- Can also sync Invoices without associated orders (`sync_invoices`)
- totalValue=AmountEx, placed=CreationDate
- Customer can filter by StatusId for create/delete

## Buy Orders (bidirectional)
- **OP → Logic4:** placed=CreatedAt, supplierId=CreditorId, remarks="op-{buyOrderId}"
- **Logic4 → OP:** BuyOrderClosed:true → completed=now()
- Lines: quantity=QtyToOrder, subtotalValue=QtyToOrder×Price

## Receipt Lines
- **No receipt lines in Logic4** — calculated from BuyOrderLines
- quantity = QtyToOrder - QtyToDeliver
- Only one receipt per BOL, updated as QtyToDeliver decreases
- remoteId auto-generated: BuyOrderId_BuyOrderRowId_ProductId

## Links
- Tap: [tap-logic4](https://github.com/hotgluexyz/tap-logic4)
- Target: [target-logic4](https://github.com/hotgluexyz/target-logic4)
- ETL: `optiply-scripts/import/logic4/etl.ipynb`
- API: [Swagger](https://api.logic4server.nl/swagger/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2745597953)
