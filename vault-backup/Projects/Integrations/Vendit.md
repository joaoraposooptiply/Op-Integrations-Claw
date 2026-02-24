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

## API Reference

### Base URL
`https://api2.vendit.online` (configurable via `api_url`)

### Auth Method
Token-based auth via OAuth endpoint. Requires `username`, `password`, `vendit_api_key`. Token stored in config file with `token_expire` timestamp. Valid if >120s until expiry.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| Products | GET | `/Products` | Page-based |
| Suppliers | GET | `/Suppliers` | Page-based |
| Orders | GET | `/Orders` | Page-based |
| PurchaseOrders | GET | `/PurchaseOrders` | Page-based |
| SupplierProducts | GET | `/SupplierProducts` | Page-based |
| StockChanges | GET | `/StockChanges` | Page-based |
| PrePurchaseOrders | GET | `/PrePurchaseOrders` | Page-based |
| HistoryPurchaseOrders | GET | `/HistoryPurchaseOrders` | Page-based |
| Transactions | GET | `/Transactions` | Page-based |

Pagination: `page` param, `next_page_token_jsonpath`: `$.pagination.next_page`

### Rate Limiting
- Connection pooling (configurable pool size)
- Max retries configurable

### Error Handling
- Custom exceptions: `EmptyResponseError`, `TokenRefreshError`
- Backoff on these + `RequestException` (max 5 tries, factor 2)

### Quirks
- Token storage via `TokenStorage` class
- SSL verification configurable
- Two stream variants: `_OptiplyStream` (custom output format), `_FindGet*Stream` (standard)

---

## ETL Summary

**Pattern:** OLD

**Entities Processed:**
- Products
- ProductCompositions
- Suppliers
- SupplierProducts
- SellOrders (from transactions)
- SellOrderLines
- BuyOrders (history + pending)
- BuyOrderLines
- ReceiptLines

**Key Config Flags:**
| Flag | Default | Purpose |
|------|---------|---------|
| `tap_name` | None | Tap name for config backup |
| `sellorders_warehouse_ids` | None | Filter sell orders by warehouse |
| `stocks_warehouse_ids` | None | Filter stocks by warehouse |

**Custom Logic Highlights:**
- Stock from `stock_changes` stream
- Sell orders from `transactions` stream with `saleHeaderId`, `officeId`
- Buy orders have two sources: `history_purchase_orders` and `purchase_orders_optiply`
- Warehouse filtering for both stock and sell orders

---

## Links
- Tap: [tap-vendit](https://github.com/joaoraposooptiply/tap-vendit.git)
- Target: [target-vendit](https://github.com/joaoraposooptiply/target-vendit.git)
- ETL: `optiply-scripts/import/vendit/etl.ipynb`
- API: [Swagger](https://api.staging.vendit.online/VenditPublicApiSpec/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3170369648)
