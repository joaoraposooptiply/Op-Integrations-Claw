---
tags: [integration, project, live]
integration: Vendit
type: Retail/POS
auth: API Key
status: 🟢 Live (IN PROGRESS docs)
updated: 2026-02-24
---

# Vendit Integration

## Sync Board (all 60 min, BO export 10 min)
| Entity | Direction |
|--------|-----------|
| Products + Stocks | Vendit → OP |
| Suppliers | Vendit → OP |
| Supplier Products | Vendit → OP |
| Sell Orders | Vendit → OP |
| Buy Orders + Lines | Vendit ↔ OP |
| Receipt Lines | Vendit → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sellorders_warehouse_ids` | null | Filter SOs by warehouse |
| `stocks_warehouse_ids` | null | Filter stock by warehouse |

## Product Mapping
- name=productDescription, sku=productSearchCode, ean=productNumber
- articleCode=productGui (GUID)
- stockLevel from GetChangedStockFromDate.availableStock
- status: availabilityStatusId 1/4=enabled, 2/3/5/6/7/8=disabled
- notBeingBought: disabled + stock>0 → true

## Suppliers: name=supplierName, deliveryTime=deliveryDays, email

## Supplier Products
- Custom endpoint: /Optiply/GetProductSuppliersFromDate/{unix}
- price=purchasePriceEx, preferred=preferredDefaultSupplier, MOQ=minOrderQuantity

## Sell Orders
- totalValue=totalPriceIncVat, placed=transactionDatetime

## Buy Orders
- **Export quirk:** Vendit only accepts PrePurchaseOrders (=individual lines)
- Customer must manually convert PrePurchaseOrders → final PurchaseOrder in Vendit
- Import: from HistoryPurchaseOrders, completed=deliveryDateTime
- BOL remoteId=purchaseOrderNumber_productId

## Receipt Lines: quantity=amountDelivered, occurred=deliveryDatetime

## Links
- Tap: [tap-vendit](https://github.com/joaoraposooptiply/tap-vendit.git)
- Target: [target-vendit](https://github.com/joaoraposooptiply/target-vendit.git)
- ETL: `optiply-scripts/import/vendit/etl.ipynb`
- API: [Swagger](https://api.staging.vendit.online/VenditPublicApiSpec/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3170369648)
