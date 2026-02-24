---
tags: [integration, project, live, complex]
integration: Exact Online
type: ERP
auth: OAuth2 (token refresh every 10 min)
status: 🟢 Live
updated: 2026-02-24
---

# Exact Online Integration

> Most complex integration. 16+ entity types, bidirectional sync, 30+ config flags.

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board (all every 30 min)
| Entity | Direction | Notes |
|--------|-----------|-------|
| Products | Exact → OP | From Items + StockPositions + SalesItemPrices |
| Product Deletions | Exact → OP | |
| Product Compositions | Exact → OP | From BOM or BillOfMaterialVersions |
| Suppliers | Exact → OP | From CRM/Accounts |
| Supplier Deletions | Exact → OP | Set to ignored |
| Supplier Products | Exact → OP | From SupplierItem + PurchaseItemPrices |
| Stocks | Exact → OP | CurrentStock - PlanningOut |
| **Sell Orders** | Exact → OP | From Sales Orders OR Sales Invoices (configurable) |
| Sell Order Deletions | Exact → OP | Also cancelled (Status=45) |
| **Buy Orders** | Exact ↔ OP | **Bidirectional** — Optiply creates BOs in Exact too |
| Buy Order Lines (CRUD) | Exact → OP | Add, change, delete tracked |
| Assembly Orders | Exact → OP | Optional (use_assembly_orders) |
| **Production Orders** | Exact ↔ OP | ShopOrders, requires Production module |
| Receipt Lines | Exact → OP | From GoodsReceiptLines |
| Returns | Exact → OP | Negative receipt lines |
| Warehouse Transfers | OP → Exact | Converts BOs to transfers |

## Configuration Flags (30+)
### Products
| Flag | Default | Purpose |
|------|---------|---------|
| `map_stockLevel` | true | Sync stock from Exact |
| `map_product_articleCode` | true | Sync SearchCode as articleCode |
| `use_BOM_to_prodAssembled` | false | Use BOM instead of isMakeItem for assembled |
| `map_IsPurchaseItem` | true | Use IsPurchaseItem for status/unlimitedStock |
| `prod_ItemGroupCode_filter` | None | Disable products by ItemGroupCode list |
| `use_IsOnDemandItem` | false | Disable on-demand products |
| `assortments` | None | Custom Class_01/02 mapping to status |
| `use_price_lists` | false | Sync price from specific PriceList |
| `price_list_code` | None | Which PriceListCode to use |
| `sync_stock_montapacking` | false | Add Monta WMS stocks |
| `sync_stock_qls` | false | Add QLS stocks |
| `stock_warehouse_ids` | "" | Filter warehouses for stock |

### Product Compositions
| Flag | Default | Purpose |
|------|---------|---------|
| `use_bill_of_materials_versions` | false | Use BOM Versions (manufacturing) |
| `calc_part_quantity` | false | Calculate partQty / composedQty |

### Suppliers
| Flag | Default | Purpose |
|------|---------|---------|
| `map_supplier_mail` | false | Sync supplier email |
| `sync_leadTime_suppliers` | false | Sync PurchaseLeadDays |

### Supplier Products
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_leadTime_supProducts` | false | Sync PurchaseLeadTime |
| `useMOQ` | true | Sync MinimumQuantity |
| `useLOT` | true | Sync PurchaseUnitFactor as lotSize |
| `useLOT_PurchaseLotSize` | false | Use PurchaseLotSize instead |
| `map_preferred_supplier` | true | Sync MainSupplier flag |
| `map_purchase_price` | "default" | Options: default/Product Cost/Purchase Prices/none |

### Sell Orders
| Flag | Default | Purpose |
|------|---------|---------|
| `use_sales_orders` | false | Sync Sales Orders |
| `use_sales_invoices` | true | Sync Sales Invoices |
| `pullAllOrders` | true | All statuses or only completed |
| `use_drop_shipments` | true | Include DropShipment orders |
| `sync_sell_orders_only` | false | Only sell orders (no products) |
| `filter_CostCenter_Codes` | None | Exclude lines by CostCenter |
| `filter_sellOrder_CustomerIDs` | None | Exclude by CustomerID |

### Buy Orders
| Flag | Default | Purpose |
|------|---------|---------|
| `use_assembly_orders` | false | Sync AssemblyOrders as BOs |
| `map_buyOrders_AmountFC` | false | Use foreign currency amount |
| `bo_completed_status` | "30","40" | Which statuses = completed |
| `export_BOLine_price` | false | Send line price to Exact |
| `export_stock_transfers` | false | Send BOs as warehouse transfers |
| `stock_transfer_from` | — | Source warehouse for transfers |
| `stock_transfer_to` | — | Dest warehouse for transfers |

### Global
| Flag | Default | Purpose |
|------|---------|---------|
| `unit_filter` | false | Enable unit conversion |
| `unit_factors` | null | Conversion factors (e.g., gal→ml×3750) |
| `use_production_orders` | false | Sync ShopOrders (requires Production module) |

## Product Mapping
| Optiply | Exact | Notes |
|---------|-------|-------|
| remoteId | ID | |
| name | Description | |
| skuCode | Code | |
| articleCode | SearchCode | Configurable |
| price | SalesItemPrices.Price | Max 9999999.99, else 0 |
| unlimitedStock | IsPurchaseItem | false → unlimited |
| stockLevel | CurrentStock - PlanningOut | Warehouse-filterable |
| status | EndDate/IsMakeItem/IsPurchaseItem/IsOnDemandItem | Complex logic |
| eanCode | Barcode | |
| assembled | isMakeItem | Or BOM-based |
| createdAtRemote | ItemCreatedDate | |
| stockMeasurementUnit | Converted unit | Only if unit_filter=true |

## Buy Order Export (OP → Exact)
- ReceiptDate = OrderSyncDateTime + supplier.deliveryTime (in calendar days)
- If no deliveryTime → next working day
- Lines sorted by skuCode ascending
- Creator = user who connected Exact + Optiply
- PurchaseAgent = supplier's account manager

## Key Complexities
1. **Sell orders dual source:** Can come from Sales Orders OR Sales Invoices (or both with dedup)
2. **BOs are bidirectional:** Optiply creates → Exact, Exact creates → Optiply
3. **Assembly/Production Orders:** Separate paths for inventory assembly vs manufacturing
4. **Warehouse Transfers:** BOs can be sent as warehouse transfers instead
5. **Returns:** Mapped as negative receipt lines
6. **Unit conversion:** Factor-based conversion affects stocks, compositions, lotSizes, MOQ
7. **lotSize on export:** QuantityInPurchaseUnits = quantity / lotSize
8. **Receipt lines with lotSize:** quantity = QuantityReceived × lotSize
9. **Product Compositions circular reference protection:** A→B and B→A blocked by DB constraint

## API Reference

| Attribute | Details |
|-----------|---------|
| **Base URL** | `https://start.exactonline.nl/api/v1/{current_division}/` |
| **Auth** | OAuth2 with refresh_token grant (tokens refresh every 10 min) |
| **SDK** | singer_sdk (hotglue fork) |
| **Response Format** | XML (parsed via xmltodict, `d:` prefixes stripped) |

### Endpoints
| Stream | Path | Pagination |
|--------|------|------------|
| items | `logistics/Items` | OData $skiptoken |
| purchase_orders | `purchaseorder/PurchaseOrders` | OData $skiptoken |
| sales_orders | `salesorder/SalesOrders` | OData $skiptoken |
| sales_order_lines | `salesorder/SalesOrderLines` | OData $skiptoken |
| supplier_products | `logistics/SupplierItem` | OData $skiptoken |
| warehouses | `inventory/Warehouses` | OData $skiptoken |
| suppliers | `crm/Accounts` | OData $skiptoken |
| sales_invoices | `salesinvoice/SalesInvoices` | OData $skiptoken |
| sales_invoice_lines | `salesinvoice/SalesInvoiceLines` | OData $skiptoken |
| sales_items_prices | `logistics/SalesItemPrices` | OData $skiptoken |
| stock_positions | `inventory/StockPositions` | OData $skiptoken |
| logistics_stock_positions | `logistics/ItemWarehouses` | OData $skiptoken |
| gl_accounts | `financial/GLAccounts` | OData $skiptoken |
| purchase_invoices | `purchase/PurchaseInvoices` | OData $skiptoken |
| vat_codes | `vat/VATCodes` | OData $skiptoken |
| deleted | `$metadata/deleted` | OData $skiptoken |
| bill_of_materials_versions | `manufacturing/BillOfMaterialVersions` | OData $skiptoken |
| manufacturing_shop_orders | `manufacturing/ShopOrders` | OData $skiptoken |
| goods_receipt_lines | `purchaseorder/GoodsReceiptLines` | OData $skiptoken |
| purchase_entries | `purchaseentry/PurchaseEntries` | OData $skiptoken |
| purchase_items_prices | `logistics/PurchaseItemPrices` | OData $skiptoken |
| purchase_return_lines | `purchaseorder/PurchaseReturnLines` | OData $skiptoken |
| assembly_orders | `manufacturing/AssemblyOrders` | OData $skiptoken |
| bill_of_materials | `manufacturing/BillOfMaterials` | OData $skiptoken |
| exchange_rates | `financial/ExchangeRates` | OData $skiptoken |
| transaction_lines | `financialtransaction/TransactionLines` | OData $skiptoken |
| sales_price_lists | `sales/SalesPriceLists` | OData $skiptoken |

### Rate Limiting
- **1.01s sleep** between ALL requests (hard-coded)
- 429 → reads `X-RateLimit-Reset` header → RetriableAPIError
- 429 with remaining=0 → FatalAPIError (daily limit hit)
- 500-599 → RetriableAPIError with exponential backoff

### Error Handling
| Code | Action |
|------|--------|
| 408 | RetriableAPIError (timeout) |
| 429 | RetriableAPIError or FatalAPIError (daily limit) |
| 400-499 | FatalAPIError |
| 500+ | RetriableAPIError |

### Quirks
- XML responses parsed via `xmltodict` — `d:` prefix stripping in post-processing
- `_write_state_message` fix for partition cleanup
- `dont_use_current_division` option for warehouse lookups
- Supports multiple warehouses with config options

## Target Reference

> Writing data FROM Optiply TO Exact Online

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-exact](https://github.com/hotgluexyz/target-exact) |
| **Auth Method** | OAuth2 — `auth_url`, `client_id`, `client_secret` → token endpoint |
| **Base URL** | `https://start.exactonline.nl/api/v1/{division}` (division from config) |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| BuyOrdersSink | `/purchaseorder/PurchaseOrders` | POST |
| UpdateInventory | `UpdateInventory` | POST |
| ItemsSink | `/logistics/Items` | POST |
| PurchaseInvoicesSink | `/purchase/PurchaseInvoices` | POST |
| SuppliersSink | `/crm/Accounts` | POST |
| PurchaseEntriesSink | `/purchaseentry/PurchaseEntries` | POST |
| SalesOrdersSink | `/salesorder/SalesOrders` | POST |
| ShopOrdersSink | `/manufacturing/ShopOrders` | POST |
| WarehouseTransfersSink | `/inventory/WarehouseTransfers` | POST |

### Error Handling
- `backoff.expo` with max 5 tries on `RetriableAPIError`, `ReadTimeout`
- 429, 500-599 → `RetriableAPIError`
- 400-499 → `FatalAPIError`

### Quirks
- Returns XML (not JSON) from API — responses parsed via `xmltodict`
- Supports `default_warehouse_id` → resolves to `warehouse_uuid`
- Division can be overridden per record via `division` field

---

## ETL Summary

| Attribute | Details |
|-----------|---------|
| **Pattern** | OLD (most complex in the fleet) |
| **Entities** | Products, ProductCompositions, Suppliers, SupplierProducts, SellOrders, BuyOrders, ReceiptLines — all 7 core entities |

### Key Config Flags
30+ flags — see Configuration Flags section above for full list. Highlights:
- `use_sales_orders` / `use_sales_invoices` — dual sell order source
- `sync_stock_montapacking` / `sync_stock_qls` — external WMS stock merging
- `use_bill_of_materials_versions` — manufacturing BOM path
- `use_assembly_orders` / `use_production_orders` — assembly/manufacturing flows
- `export_stock_transfers` — converts BOs to warehouse transfers
- `unit_filter` / `unit_factors` — unit conversion affecting stocks, compositions, lot sizes

### Custom Logic Highlights
- **Dual stock sources**: Can merge stock from Montapacking + QLS on top of Exact stock
- **BOM/Assembly**: Two paths for product compositions (BOM vs BillOfMaterialVersions)
- **10 product classes**: Complex status mapping using IsMakeItem, IsPurchaseItem, IsOnDemandItem, EndDate
- **Volume discounts**: Price list support with PriceListCode filtering
- **Bidirectional BOs**: Full CRUD with receipt date calculation, lot size conversion, PurchaseAgent assignment

See also: [[ETL Patterns]], [[Generic ETL Template]]

## Related Pages
- [Buy Orders Common Errors](https://optiply.atlassian.net/wiki/spaces/IN/pages/2429059077)
- [Unit Factor Conversion](https://optiply.atlassian.net/wiki/spaces/IN/pages/2626846725)
- [Register New App](https://optiply.atlassian.net/wiki/spaces/IN/pages/3000008719)
- [Exact FAQs](https://optiply.atlassian.net/wiki/spaces/IN/pages/3220963329)
- [Revoke Access](https://optiply.atlassian.net/wiki/spaces/IN/pages/3266805763)

## Links
- Tap: [tap-exact](https://gitlab.com/hotglue/tap-exact)
- Target: [target-exact](https://github.com/hotgluexyz/target-exact)
- ETL: `optiply-scripts/import/exact/etl.ipynb`
- API: [REST API](https://start.exactonline.nl/docs/HlpRestAPIResources.aspx)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2391113740)
