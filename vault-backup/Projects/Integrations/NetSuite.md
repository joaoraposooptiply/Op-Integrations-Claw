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

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `https://{account}.suitetalk.api.netsuite.com/services/rest/query/v1/suiteql` |
| **Auth Method** | OAuth 1.0 (consumer_key, consumer_secret, token_key, token_secret) |
| **Pagination** | Offset-based (`offset`, `limit`, page_size 1000). Offset mod 100000 due to NetSuite limit |
| **Rate Limiting** | Dynamic time_jump for large datasets. Backoff on errors |

### Endpoints (SuiteQL Queries)

| Stream | Method | Query |
|--------|--------|-------|
| transaction | POST | SuiteQL |
| vendor | POST | SuiteQL |
| customer | POST | SuiteQL |
| item | POST | SuiteQL |
| sales_transactions | POST | SuiteQL |
| vendor_bill_transactions | POST | SuiteQL |
| pricing | POST | SuiteQL |
| inventory_pricing | POST | SuiteQL |
| locations | POST | SuiteQL |
| classification | POST | SuiteQL |
| inventory_item_locations | POST | SuiteQL |
| profit_loss_report | POST | SuiteQL |
| general_ledger_report | POST | SuiteQL |
| transactions | POST | SuiteQL |
| transaction_lines | POST | SuiteQL |
| currencies | POST | SuiteQL |
| departments | POST | SuiteQL |
| subsidiaries | POST | SuiteQL |
| accounts | POST | SuiteQL |
| accounting_periods | POST | SuiteQL |
| deleted_records | POST | SuiteQL |

### Error Handling
- Adaptive time_jump: months → weeks → days → hours → minutes for >10k records
- Special handling for inventory_item_locations >100k

### Quirks
- Uses SuiteQL (SQL-like) queries via POST
- Adaptive time_jump for transaction streams with >10k results
- Supports `transaction_lines_monthly` config for time-based partitioning
- Custom filter support for bulk queries (e.g., item ranges)
- Date formats: MM/DD/YYYY fallback parsing
- `time_jump` resets based on month/hour boundary crossing

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Old |
| **Entities** | Products (from `item`), ProductCompositions (from `kit_item_members`), Suppliers (from `vendor`), SupplierProducts (from `item_vendors`), SellOrders (from `sales_orders`), SellOrderLines (from `sales_order_lines`), BuyOrders (from `purchase_orders`), BuyOrderLines (from `purchase_order_lines`) |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllOrders` | true | Pull all orders |
| `stock_location_ids` | None | Filter stock by location |

### Custom Logic
- Maps NetSuite's custom fields (e.g., `custitem_cl_external_stock`)
- Handles deleted records via `deleted_records` stream
- Uses `inventory_item_locations` for stock with location filtering
- `item_prices` stream for pricing data

---

## Links
- Tap: [tap-netsuite-rest](https://github.com/hotgluexyz/tap-netsuite-rest.git)
- Target: [target-netsuite-v2](https://github.com/hotgluexyz/target-netsuite-v2)
- ETL: `optiply-scripts/import/netsuite/etl.ipynb`
- API: [REST API](https://system.netsuite.com/help/helpcenter/en_US/APIs/REST_API_Browser/record/v1/2023.1/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3100180481)
