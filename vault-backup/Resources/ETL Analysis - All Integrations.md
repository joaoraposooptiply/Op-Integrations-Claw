---
tags: [etl, analysis, reference, critical]
source: Sub-agent analysis of all 25 ETL notebooks
updated: 2026-02-24
---

# ETL Analysis - Batch 1

## Summary Comparison

| ETL | Products | Suppliers | SupplierProducts | SellOrders | BuyOrders | ReceiptLines | ProductCompositions |
|-----|----------|-----------|-----------------|------------|-----------|--------------|---------------------|
| **Generic (new template)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Shopify | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| WooCommerce | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Exact | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Logic4 | ✅ | ✅ | ❌ | ✅ | ✅ | ✅ | ❌ |
| Bol.com | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| Montapacking | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |

---

## 1. Shopify (`shopify/etl.ipynb`)

**Template Pattern:** OLD

### Entities
- Products
- Suppliers (Vendors)
- SupplierProducts

### Custom Mapping Logic
- Products: Explodes `variants` JSON, maps `variants.sku` → `skuCode`, `variants.price` → `price`, `variants.barcode` → `eanCode`
- Vendor extraction: Extracts unique vendors from products for supplier creation
- Variant-level inventory: Uses `variants.inventory_quantity` for stockLevel

### Special Config Flags
- `sync_product_deletions` - Full sync flag for product deletions

### Edge Cases
- Uses `is_subTenant` check for parent snapshot directories
- Decimal handling for price/inventory values

---

## 2. WooCommerce (`woocommerce/etl.ipynb`)

**Template Pattern:** OLD

### Entities
- Products only

### Custom Mapping Logic
- Simpler product mapping than Shopify
- Handles product status (enabled/disabled)
- Webhook support for product deletions

### Special Config Flags
- `sync_product_deletions` - Full sync flag

### Edge Cases
- Most minimal ETL in this batch
- No snapshot-based change detection (compares full input)

---

## 3. Exact (`exact/etl.ipynb`)

**Template Pattern:** OLD (most complex in batch)

### Entities
- Products
- Suppliers
- SupplierProducts
- SellOrders
- BuyOrders
- ReceiptLines
- ProductCompositions (BOM/Assembly)

### Custom Mapping Logic
- **Stock sync flags:** `sync_stock_montapacking`, `sync_stock_qls` - dual stock source support
- **Lead time sync:** `sync_leadTime_suppliers`, `sync_leadTime_supProducts`
- **Sales items prices:** Volume discounts, price lists with date periods
- **Purchase prices:** Supplier-specific pricing
- **Product classes:** Maps 10 custom classification fields (Class_01-Class_10)
- **Bill of Materials:** Handles `bill_of_materials_versions` and `assembly_bill_of_material_materials`
- **Sales invoices:** Maps as alternative to sell orders
- **Deleted records:** Handles soft deletes via `deleted` input

### Special Config Flags
- `sync_endpoints` - Enable/disable all sync
- `sync_stock_montapacking` - Use Montapacking stock
- `sync_stock_qls` - Use QLS stock  
- `sync_leadTime_suppliers` - Sync supplier lead times
- `sync_leadTime_supProducts` - Sync supplier product lead times
- `sync_sell_orders_only` - Only sync sell orders
- `full_sync_sales_items_prices` - Force full price sync

### Edge Cases
- Multiple stock sources (Montapacking + QLS)
- Date period handling for prices
- Net weight mapping
- Item group codes

---

## 4. Logic4 (`logic4/etl.ipynb`)

**Template Pattern:** OLD

### Entities
- Products
- Suppliers
- SellOrders
- BuyOrders
- ReceiptLines

### Custom Mapping Logic
- **Dual order sync:** `sync_sales_orders` and `sync_invoices` - can sync either or both
- **Global vs Logic4 mapping:** Two mapping paths (Logic4-specific + global fallback)
- Invoice date handling: Maps `DeliveryDate` for order timing
- Warehouse filtering in orders

### Special Config Flags
- `sync_sales_orders` - Enable sales order sync
- `sync_invoices` - Enable invoice sync

### Edge Cases
- Sales orders vs invoices distinction
- Warehouse-based filtering
- Buy order delivery (receipt) tracking

---

## 5. Bol.com (`bol.com/etl.ipynb`)

**Template Pattern:** OLD (simplest order ETL)

### Entities
- Products
- SellOrders (via orders + shipments)

### Custom Mapping Logic
- **Order merging:** Combines `order_details` and `shipment_details` into unified sell orders
- **FBB method filter:** `sell_order_method` config to filter by fulfillment method (e.g., "FBB")
- **Shipment sync:** Optional `sync_shipments` flag - auto-disables if sellOrders snapshot exists
- **EAN-based matching:** Maps products via EAN code (`eanCode`)

### Special Config Flags
- `optiply_key` - Which field to match products (default: "eanCode")
- `sell_order_method` - Filter orders by fulfillment method ("all" or specific method)
- `sync_shipments` - Enable shipment-based order creation

### Edge Cases
- Ships orders separately if no products matched (404 handling)
- Creates orders without lines, then posts lines separately
- Handles `cancellationRequested` flag

---

## 6. Montapacking (`montapacking/etl.ipynb`)

**Template Pattern:** OLD (most full-featured old-pattern ETL)

### Entities
- Products
- Suppliers
- SupplierProducts
- SellOrders
- BuyOrders
- ReceiptLines

### Custom Mapping Logic
- **Two flavors:** First flavor (buy orders only) vs second flavor (full sync)
- **Stock-only mode:** `sync_prod_stock_only` - only sync stock changes, not full products
- **Stock in transit:** `use_StockInTransit` - includes StockInTransit in stockLevel
- **Parent upload:** `upload_stocks_to_parent` - subtenant uploads stocks to parent
- **Return forecast:** `use_return_forecast` - adjusts stock with return forecasts
- **Minimum stock:** `sync_minimum_stock` - syncs minimum stock levels
- **Custom field 1:** `sp_name_customField1` - uses CustomField1 as supplier product name
- **Lead time sync:** `sync_leadTime_supProducts`
- **Delete completed BOL:** `del_bol_completed` - delete buy order lines for completed orders
- **Inbound forecast:** Maps `inboundforecast` and `inbounds` to buy orders and receipt lines

### Special Config Flags
- `second_flavor` - Full product/supplier sync vs buy orders only
- `sync_prod_stock_only` - Stock-only sync mode
- `upload_stocks_to_parent` - Subtenant stock upload
- `use_StockInTransit` - Include in-transit stock
- `use_return_forecast` - Adjust for returns
- `sync_minimum_stock` - Sync minimum stock
- `map_stockLevel` - Whether to include stock in diff check
- `sp_name_customField1` - Custom field mapping
- `sync_leadTime_supProducts` - Lead time sync
- `del_bol_completed` - Delete BOL for completed
- `force_patch_products` - Force patch all products
- `force_patch_supplier_products` - Force patch all supplier products

### Edge Cases
- Supplier product 409 handling (duplicate detection)
- Buy order line quantity received tracking
- Exploded JSON columns for nested data
- Integer conversion preserving leading zeros

---

## Key Differences from Generic Template

| Feature | Generic Template | Old Pattern ETLs |
|---------|-----------------|------------------|
| Payload generation | `utils.payloads` module | Inline custom functions |
| Entity sync flags | Config-driven per-entity | Often hardcoded or missing |
| Snapshot naming | Standardized (`products`, `suppliers`) | Custom names (`products_monta`, `products_optiply`) |
| Change detection | `concat_columns` for all fields | Often partial field comparison |
| Error handling | Generic 404/409 handling | Custom per-integration |
| Subtenant support | Standard | Custom (`is_subTenant`, `PARENT_SNAPSHOT_DIR`) |

### Most Unique Integrations

1. **Exact** - Most complex: dual stock sources, BOM, multiple price types, classes
2. **Montapacking** - Most config flags, two flavors, stock-only mode
3. **Bol.com** - Simplest order ETL, shipment-based order creation
4. **Logic4** - Dual invoice/sales order sync

---

*Analysis generated: 2026-02-24*
# ETL Analysis - Batch 2

## 1. Amazon ETL

**Template:** Old pattern (custom payload construction, no utils.payloads)

**Entities:**
- Products (from `products_inventory`, `warehouse_inventory`, `product_catalog_details`)

**Custom Logic:**
- Multi-marketplace support with `marketplaceId` concatenation: `remoteId = articleCode_marketplaceId`
- `second_flavour` flag - switches between FBA inventory vs marketplace inventory
- Extracts EAN/SKU from `product_catalog_details` identifiers JSON
- Merges stock from `warehouse_inventory` (multiple warehouses summed)
- Pulls existing products from Optiply API if no snapshot exists (filter by `status=ENABLED`)

**Config Flags:**
- `optiply_key`: "eanCode" (default) or skuCode
- `second_flavour`: False (default) - uses FBA inventory
- `marketplaces`: comma-separated warehouse IDs
- `uri`: marketplace URL (extracts country code via regex)

**Edge Cases:**
- Main warehouse extraction via regex on URI (`.amazon.<country>/`)
- Stock fallback: uses `quantity` if `stockLevel` is 0
- Disabled product handling: excludes inactive products

---

## 2. Amazon Vendor ETL

**Template:** Generic ETL (uses `utils.payloads` + `utils.actions`)

**Entities:**
- Products, Suppliers, SupplierProducts, SellOrders, BuyOrders, BuyOrderLines, ReceiptLines

**Custom Logic:**
- `sync_sell_orders_only` flag - if True + is_subTenant, pulls products from Optiply API (not from tap)
- SubTenant pattern via `parent-snapshots` directory detection
- Products: uses eanCode as remoteId (not itemID like standard)
- Same payload structure as generic but simpler

**Config Flags:**
- `sync_sell_orders_only`: False (default)

**Edge Cases:**
- When syncing sell orders only + subtenant: reads from Optiply API using `products_optiply` snapshot key
- Filters products by `remoteId` not null/nan

---

## 3. BigCommerce ETL

**Template:** Old pattern (custom, no utils.payloads)

**Entities:**
- Products (with variants), Orders

**Custom Logic:**
- **Product variant handling**: Merges `products` + `variants` tables
- remoteId = Variant ID (not Product ID)
- articleCode = Parent Product ID
- Option values extraction: parses `option_values` JSON, concatenates labels to variant name
- Inventory tracking: if 'variant' level, uses variant stock; otherwise product stock
- Price fallback: uses `calculated_price` if `price` is null

**Config Flags:**
- `pullAllOrders`: False (default) - only completed orders

**Edge Cases:**
- State.json webhook handling for restore operations
- Date filtering on updates via `date_modified`
- Inventory tracking export column preserved for stock updates back to BC

---

## 4. LightSpeed (Standard) ETL

**Template:** Generic ETL (uses `utils.payloads` + `utils.actions`)

**Entities:**
- Products (with variants), Suppliers, SupplierProducts, SellOrders, BuyOrders, BuyOrderLines, ReceiptLines

**Custom Logic:**
- Parent-snapshot pattern for subtenants (`parent-snapshots` directory)
- **Variant handling**: Similar to BigCommerce - merges products + variants
- Products have `visibility` field → status (hidden → disabled)
- SubTenant sync: can sync sell orders only, copying products from parent snapshot

**Config Flags:**
- `sync_lot_size`: False
- `sync_sell_orders_only`: False
- `sync_products_hidden`: False
- `sellorders_delete_statuses`: ["cancelled"]

**Edge Cases:**
- Hidden products can be synced as enabled via `sync_products_hidden`
- Multiple sell order delete statuses supported

---

## 5. LightSpeed R Series ETL

**Template:** Generic ETL (uses `utils.payloads` + `utils.actions`)

**Entities:**
- Products, ProductCompositions (BOM/assemblies), Suppliers, SupplierProducts, SellOrders, SellOrderLines, BuyOrders, BuyOrderLines, ReceiptLines

**Custom Logic:**
- **Warehouse filtering**: `parse_warehouse_codes()` function with options:
  - `one_warehouse`: Single shop by name
  - `multiple_warehouses`: Comma-separated shop names
  - `all_warehouses`: All shops
- **Force patch flags** from state.json:
  - `force_patch_supplier_products`: Forces PATCH to all SPs
  - `force_patch_products`: Forces PATCH to all products
- **Product compositions** (BOM): Handles assembly/box item types
  - Parent product marked as `assembled=True` after composition sync
- **Supplier products**: Complex concat_ids = `productId_supplierId`
  - Handles supplier changes (delete + recreate)
  - 409 conflict handling: fetches existing SP by supplierId/productId

**Config Flags:**
- `stock_warehouse_option`: "one_warehouse" (default)
- `stock_warehouse_ids`: comma-separated
- `default_shop_name`: warehouse code
- `sync_all_orders`: False
- `buyorders_shop_id`: Auto-populated from default shop

**Edge Cases:**
- ShopID extraction for buy orders from warehouse config
- Products grouped by shopID then aggregated (sum stock, min minimumStock)
- Ignores non-inventory item types
- deliveryTime=0 filtered out (not configured in remote)
- Special handling for Optiply-exported BOs with NFE reference

---

## 6. Magento ETL

**Template:** Old pattern (custom, simplified)

**Entities:**
- Products, SellOrders (with lines)

**Custom Logic:**
- **Dual stock sources** (config-driven):
  - Non-warehouse: `product_stock_statuses` endpoint → `stock_item` JSON explode
  - Warehouse: `source_items` endpoint → grouped by SKU
- **Salable quantity** vs regular quantity (backorder-aware)
- **Type handling**: simple products get stock; others get qty=0 + unlimitedStock=true
- Product deletions via `sync_product_deletions` flag

**Config Flags:**
- `use_inventory_source_items`: False (warehouse mode)
- `use_stock_statuses`: True (non-warehouse mode)
- `use_salable_quantity`: True
- `map_stockLevel`: True
- `warehouse_ids`: comma-separated
- `pullAllOrders`: False
- `sync_product_deletions`: False

**Edge Cases:**
- Auto-disables `use_stock_statuses` if `use_inventory_source_items` is true
- Order items parsed from JSON string (handles single quotes)
- 1000-record batch processing for orders
- Filters out products without optiply_id when matching order lines

---

## Summary: Template Usage

| Integration | Template Type |
|-------------|---------------|
| Amazon | Old (custom) |
| Amazon Vendor | Generic |
| BigCommerce | Old (custom) |
| LightSpeed | Generic |
| LightSpeed R Series | Generic |
| Magento | Old (custom) |

## Key Differentiation Patterns

1. **Warehouse filtering** → LightSpeed R Series only
2. **Product compositions/BOM** → LightSpeed R Series only
3. **Variant handling** → BigCommerce, LightSpeed
4. **Multi-marketplace** → Amazon (second_flavour)
5. **SubTenant pattern** → Amazon Vendor, LightSpeed (parent-snapshots)
6. **Dual stock sources** → Magento
7. **Force patch flags** → LightSpeed R Series (state.json)
# ETL Analysis - Batch 3

## Summary
Analysis of 10 Optiply ETL notebooks comparing custom patterns against the Generic ETL template.

---

## 1. Odoo (`/import/Odoo/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products, ProductCompositions
- Suppliers, SupplierProducts
- SellOrders, SellOrderLines
- BuyOrders, BuyOrderLines
- ReceiptLines

### Custom Mapping Logic
- Uses `sell_price_with_taxes` config to decide if prices include taxes
- Maps `productCompositions` from Odoo's BoM (Bill of Materials) system
- Multiple company_ids and warehouse_ids support for multi-company Odoo setups
- Custom stock level mapping: `map_stockLevel` config ("available_quantity" default)

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `unit_filter` | false | Filter by specific units |
| `unit_factors` | None | Unit conversion factors |
| `sell_price_with_taxes` | false | Include tax in sell price |
| `sync_purchase_price` | true | Sync purchase prices |
| `average_purchase_price` | false | Use average purchase price |
| `use_standard_price` | false | Use standard price field |
| `sync_product_price` | true | Sync product prices |
| `pullAllOrders` | false | Pull all orders (not just recent) |
| `map_sellOrdersPOS` | false | Map POS orders as sell orders |
| `export_buy_orders_as_draft` | false | Export BOs as draft |
| `bo_completed_on_receipt` | false | Complete BO on receipt |
| `map_preferred` | false | Map preferred supplier |
| `sync_deliveryTime` | true | Sync delivery time |
| `sync_moq` | true | Sync MOQ |
| `map_lotSizes` | false | Map lot sizes |
| `prod_min_stock_as_sp_moq` | false | Use min stock as SP MOQ |
| `sync_minimumStock` | false | Sync minimum stock |
| `sync_articleCode` | true | Sync article code |
| `company_ids` | "" | Filter by company IDs |
| `stocks_company_ids` | company_ids | Company for stocks |
| `sellorders_company_ids` | company_ids | Company for orders |
| `buyorders_company_ids` | company_ids | Company for purchase orders |
| `stocks_warehouse_ids` | "" | Filter by warehouse IDs |
| `map_stockLevel` | "available_quantity" | Stock level field mapping |

---

## 2. NetSuite (`/import/netsuite/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products (from `item` stream)
- ProductCompositions (from `kit_item_members`)
- Suppliers (from `vendor`)
- SupplierProducts (from `item_vendors`)
- SellOrders (from `sales_orders`)
- SellOrderLines (from `sales_order_lines`)
- BuyOrders (from `purchase_orders`)
- BuyOrderLines (from `purchase_order_lines`)

### Custom Mapping Logic
- Maps NetSuite's custom fields (e.g., `custitem_cl_external_stock`)
- Handles deleted records via `deleted_records` stream
- Uses `inventory_item_locations` for stock with location filtering
- `item_prices` stream for pricing data

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllOrders` | true | Pull all orders |
| `stock_location_ids` | None | Filter stock by location |

---

## 3. QLS (`/import/qls/etl.ipynb`)

**Pattern:** OLD (uses v2 endpoints)

### Entities Processed
- Suppliers
- Products
- SellOrders (v2)
- SellOrderLines
- BuyOrders, BuyOrders_v2
- BuyOrderLines, BuyOrderLines_v2
- ReceiptLines (v2)

### Custom Mapping Logic
- Has dual version support: v1 and v2 for orders/buy orders
- Orders extracted from `sell_orders_v2`
- Buy orders from multiple streams: `buy_orders`, `buy_orders_v2`, `buy_orders_by_id`, `buy_orders_by_id_v2`
- Receipt lines from `receipt_lines` and `buy_orders_by_id_v2`

### Config Flags / Edge Cases
- No visible custom config flags (relies on stream names)
- Complex multi-stream handling for buy orders

---

## 4. EasyEcom (`/import/EasyEcom/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products (with composition support)
- Suppliers
- SupplierProducts
- SellOrders
- SellOrderLines
- BuyOrders
- BuyOrderLines

### Custom Mapping Logic
- Product compositions extracted from `products` stream (not dedicated stream)
- Supplier products also from `products` stream
- Sell order lines extracted from `sell_orders` with nested `suborders`
- Buy orders/lines from same `buy_orders` stream

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `map_supplierProductSku` | true | Map supplier product SKU |
| `tap_name` | None | Tap name for config backup |

---

## 5. ZohoBooks (`/import/zohobooks/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- (Limited view from grep - appears to focus on SellOrders)

### Custom Mapping Logic
- Minimal custom logic visible
- `pullAllOrders` flag controls order filtering

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllOrders` | true | Pull all orders |

---

## 6. ZohoInventory (`/import/zoho-inventory/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- (Limited - focuses on sell orders)

### Custom Mapping Logic
- Different flag name: `pullAllSellOrders` (not `pullAllOrders`)

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllSellOrders` | false | Pull all sell orders |

---

## 7. Vendit (`/import/vendit/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products
- ProductCompositions
- Suppliers
- SupplierProducts
- SellOrders (from `transactions`)
- SellOrderLines (from `transactions`)
- BuyOrders (history + pending)
- BuyOrderLines

### Custom Mapping Logic
- Stock from `stock_changes` stream
- Sell orders from `transactions` stream with `saleHeaderId`, `officeId`
- Buy orders have two sources: `history_purchase_orders` and `purchase_orders_optiply`

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `tap_name` | None | Tap name for config backup |
| `sellorders_warehouse_ids` | None | Filter sell orders by warehouse |
| `stocks_warehouse_ids` | None | Filter stocks by warehouse |

---

## 8. Tilroy (`/import/tilroy/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products
- Suppliers
- SupplierProducts
- SellOrders (from `sales`)
- SellOrderLines (from `sales`)
- BuyOrders (from `purchase_orders`)
- BuyOrderLines (from `purchase_orders`)
- ReceiptLines (from `purchase_orders`)

### Custom Mapping Logic
- Stock extracted via `_extract_stock_like_df()` helper function
- Supports both `stock` and `stock_changes` streams
- Prices from separate `prices` stream
- Language-specific processing via `languageCode`

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `languageCode` | "NL" | Language for processing |
| `shop_ids` | "" | Filter by shop IDs |
| `shop_numbers` | "" | Filter by shop numbers |

---

## 9. BigQuery (`/import/bigquery/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products
- ProductCompositions
- Suppliers
- SupplierProducts
- SellOrders
- SellOrderLines
- BuyOrders
- BuyOrderLines
- ReceiptLines

### Custom Mapping Logic
- Uses standard Optiply stream naming: `products`, `suppliers`, etc.
- No visible custom mapping logic in grep output

### Config Flags / Edge Cases
- **No custom config flags** - most similar to Generic template
- Input stream naming: `products`, `sell_orders`, etc.

---

## 10. MSSQL (`/import/mssql/etl.ipynb`)

**Pattern:** OLD

### Entities Processed
- Products
- ProductCompositions
- Suppliers
- SupplierProducts
- SellOrders
- SellOrderLines
- BuyOrders
- BuyOrderLines
- ReceiptLines

### Custom Mapping Logic
- Uses `Optiply-` prefixed stream names (e.g., `Optiply-Products`, `Optiply-SellOrders`)
- Special handling for 409 (conflict) responses on supplier products - fetches existing record
- Special handling for 404 on supplier product patches - reposts as new

### Config Flags / Edge Cases
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllOrders` | true | Pull all orders |
| `stock_location_ids` | "all" | Filter stock by location |
| `force_patch_supplier_products` | false | Force patch all SPs |
| `force_patch_products` | false | Force patch all products |

### Edge Cases
- Tenant-specific handling: `TENANT_ID == "1318"` ignores supplier deletions (sets `ignored=True` instead of delete)
- Special 409 handling for duplicate supplier products
- Snapshot backup: `config_mssql_backup.json`

---

## Template Classification

| Integration | Pattern | Notes |
|-------------|---------|-------|
| Odoo | OLD | Most complex - many config flags |
| NetSuite | OLD | Custom fields, deleted records |
| QLS | OLD | Dual v1/v2 streams |
| EasyEcom | OLD | Nested data structures |
| ZohoBooks | OLD | Minimal custom logic |
| ZohoInventory | OLD | Different flag naming |
| Vendit | OLD | Warehouse filtering |
| Tilroy | OLD | Language + shop filtering |
| BigQuery | OLD | Nearly Generic-like |
| MSSQL | OLD | Prefix naming, special conflict handling |
| Generic | **NEW** | Base template - no custom config |

---

## Key Differences from Generic Template

1. **Config Flags**: Most old ETLs have 1-25+ custom config flags; Generic has none
2. **Stream Naming**: 
   - Generic: `check_sync_output("products")`
   - Old: direct names like `input_data.get("products")` or `Optiply-Products`
3. **Custom Logic**: Old ETLs have integration-specific mapping (tax handling, multi-company, warehouse filtering)
4. **Edge Case Handling**: Old ETLs handle 409/404 conflicts, deleted records, tenant-specific logic
