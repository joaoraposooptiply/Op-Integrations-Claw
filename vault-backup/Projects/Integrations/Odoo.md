---
tags: [integration, project, live]
integration: Odoo
type: ERP
auth: XML-RPC (url, db, username, password)
status: 🟢 Live
updated: 2026-02-24
---

# Odoo Integration

> Uses XML-RPC API — problematic for debugging. Mostly full syncs.

## Sync Board (all 30 min, BO export 15 min)
| Entity | Direction |
|--------|-----------|
| Products + Deletions + Stocks | Odoo → OP |
| Product Compositions | Odoo → OP |
| Suppliers | Odoo → OP |
| Supplier Products + Deletions | Odoo → OP |
| Sell Orders + Deletions | Odoo → OP |
| Sell Orders POS | Odoo → OP (if flag) |
| Buy Orders + Lines (CRUD) | Odoo ↔ OP |
| Receipt Lines | Odoo → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `use_templates` | — | Create products from templates |
| `sell_price_with_taxes` | false | Include taxes in price |
| `sync_purchase_price` | — | Sync purchase prices |
| `average_purchase_price` | — | Sync avg cost on SP |
| `pullAllOrders` | false | All statuses or only "sale" |
| `map_preferred` | false | Sync preferred supplier |
| `language` | en_US | Language for product names |
| `map_sellOrdersPOS` | false | Sync POS orders |
| `map_stockLevel` | available_quantity | Field for stock |
| `export_BOLine_price` | true | Send line price (required Odoo v18+) |
| `bo_completed_on_receipt` | false | Complete BO on full receipt |

## Product Mapping
| Optiply | Odoo |
|---------|------|
| name | product.name (in configured language) |
| skuCode | default_code |
| articleCode | product.code |
| price | product.price (or tax_string) |
| stockLevel | stock.available_quantity |
| status | active=true → enabled |
| assembled | bom_count > 0 |

- Only syncs Product.Type=Product (+ Consu if is_Storable exists and true)

## Compositions: from MRP BOM lines (production module)
## Suppliers: display_name, email_normalized, ID
## Supplier Products: remoteId = supplierId_productId, deliveryTime=delay, preferred by supplier_id

## Sell Orders (+ POS)
- Regular: amount_untaxed, date_order
- POS: amount_total, date_order
- Default: only status="sale"

## Buy Orders (bidirectional)
- Odoo → OP: status purchase/done, completed on "done"/"closed"
- OP → Odoo: partner_id=supplier, name=buyOrderId

## Receipt Lines: from purchase.order.line (qty + date)

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `{url}/xmlrpc/2` (XML-RPC protocol) |
| **Auth Method** | XML-RPC (`db` + `username` + `password`) |
| **Pagination** | Offset-based (`offset`, `limit` = page_size) |
| **Rate Limiting** | Backoff expo (max 8 tries, factor 3) on OverflowError, ResponseNotReady, ProtocolError, RetriableAPIError |

### Endpoints

| Stream | XML-RPC Method | Model | Pagination |
|--------|----------------|-------|------------|
| products | search_read | `products` | Offset |
| customers | search_read | `customers` | Offset |
| sale_orders | search_read | `sale_orders` | Offset |
| sale_order_line | search_read | `sale_order_line` | Offset |
| purchase_orders | search_read | `purchase_orders` | Offset |
| purchase_order_lines | search_read | `purchase_order_lines` | Offset |
| stock | search_read | `stock` | Offset |
| warehouse | search_read | `warehouse` | Offset |
| location | search_read | `location` | Offset |
| product_suppliers | search_read | `product_suppliers` | Offset |
| companies | search_read | `companies` | Offset |
| users | search_read | `users` | Offset |
| accounts | search_read | `accounts` | Offset |
| invoices_bills | search_read | `invoices_bills` | Offset |
| bom | search_read | `bom` | Offset |
| bom_lines | search_read | `bom_lines` | Offset |
| invoice_bill_lines | search_read | `invoice_bill_lines` | Offset |
| invoice_lines_all | search_read | `invoice_lines_all` | Offset |

### Error Handling
- 429 → RetriableAPIError
- Custom ignore_list for problematic fields on schema errors

### Quirks
- Uses XML-RPC `search_read` method
- Language config with validation (`xx_XX` format)
- Configurable `full_sync_streams` to ignore incremental for certain streams
- Filters: active/inactive products via OR filter
- Ignores specific fields on error (ignore_list pattern)
- Schema dynamically fetched via `fields_get`

## Target Reference

> Writing data FROM Optiply TO Odoo

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-odoo-v3](https://github.com/hotgluexyz/target-odoo-v3) |
| **Auth Method** | Session auth — `db`, `username`, `password` → `/web/session/authenticate` |
| **Base URL** | `{url}` (configurable, e.g., `https://odoo.instance.com`) |

### Sinks/Entities

| Sink | Odoo Model | HTTP Method |
|------|------------|-------------|
| TaxRates | `account.tax` | POST |
| Vendors | `res.partner` | POST |
| Suppliers | `res.partner` (supplier) | POST |
| PurchaseInvoices | `account.move` | POST |
| Invoices | `account.move` | POST |
| Bills | `account.move` (bills) | POST |
| BuyOrders | `purchase.order` | POST |

### Error Handling
- Base `HotglueSink` validation

### Quirks
- Uses XML-RPC / JSON-RPC (not REST)
- Authentication returns `session_id` cookie
- Has `mapping.py` + `mapping.json` for field transformations

---

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Old (most complex - many config flags) |
| **Entities** | Products, ProductCompositions, Suppliers, SupplierProducts, SellOrders, SellOrderLines, BuyOrders, BuyOrderLines, ReceiptLines |

### Key Config Flags
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

### Custom Logic
- Uses `sell_price_with_taxes` config to decide if prices include taxes
- Maps `productCompositions` from Odoo's BoM (Bill of Materials) system
- Multiple company_ids and warehouse_ids support for multi-company setups
- Custom stock level mapping (configurable field)

---

## Links
- Tap: [tap-odoo](https://gitlab.com/hotglue/tap-odoo)
- Target: [target-odoo-v3](https://github.com/hotgluexyz/target-odoo-v3)
- ETL: `optiply-scripts/import/Odoo/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2433482756)
