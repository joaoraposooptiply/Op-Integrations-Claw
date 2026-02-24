---
tags: [patterns, api, reference, critical]
source: Extracted from 23 tap source codebases
updated: 2026-02-24
---

# API Patterns — Extracted from Tap Source Code

## Auth Patterns

| Integration | Auth Type | SDK Class | Notes |
|-------------|-----------|-----------|-------|
| WooCommerce | Basic Auth (key+secret) | `BasicAuthenticator` | Uses `hotglue_singer_sdk` |
| Shopify | API Key (header) | Custom | Bearer token, api_key = API Password |
| Exact Online | OAuth2 (refresh) | Custom `OAuth2Authenticator` | Token refresh every 10min, rate limit handling |
| Logic4 | OAuth2 (per-request) | `Logic4Authenticator` (singleton) | Token per request |
| Bol.com | OAuth2 | `BolAuthenticator` (singleton) | Standard OAuth flow |
| Lightspeed C | OAuth2 | Custom | Language-aware base URL |
| Lightspeed R | OAuth2 | Custom (singleton) | 429 rate limit handling |
| Montapacking | Bearer token | Simple | api-v6.monta.nl |
| Odoo | XML-RPC (uid+password) | Custom `query_odoo` | Not REST — direct RPC calls |
| Sherpaan | SOAP token | Custom `_get_soap_envelope` | Token-based pagination on SOAP |
| Amazon Seller | SP-API (AWS IAM + OAuth) | Custom | Multi-region, complex signing |
| NetSuite | OAuth1 HMAC (TBA) | Custom | Token-Based Authentication |
| QLS | Bearer token | Custom | URL from config |
| EasyEcom | Bearer token (refresh) | Custom `BearerTokenAuthenticator` | Token refresh endpoint |
| Zoho Books | OAuth2 (refresh) | Custom | Region-specific token endpoint |
| Zoho Inventory | OAuth2 (refresh) | `ZohoInventoryAuthenticator` (singleton) | Domain-mapped auth URLs |
| Vendit | Custom token | `APIAuthenticatorBase` | Token stored in config file |
| Tilroy | API Key | Simple | Page-based pagination |
| BigQuery | Service Account JSON | Google client lib | Not Singer REST stream |
| MSSQL | Connection string | pyodbc/BCP | Direct SQL, not REST |

## Pagination Patterns

| Integration | Pattern | Details |
|-------------|---------|---------|
| WooCommerce | Page number | `?page=N`, replication via `date_modified` |
| Shopify | Cursor (Link header) | `results_per_page=50` |
| Exact | Next link | Response provides next URL, `$skiptoken` |
| Logic4 | Skip/Take (POST body) | `SkipRecords` in request payload |
| Bol.com | Page number | Standard page param |
| Lightspeed C | Page number | JSON path `$.orders[*]` |
| Lightspeed R | Page number | `?page=N` |
| Montapacking | Since-ID | `?sinceid=N` for inbounds, offset for products |
| Odoo | Offset | `query_odoo(uid, models, offset)`, configurable page_size |
| Sherpaan | Token-based | SOAP token pagination, chunk_size=200 |
| Amazon | Next token | `next_token` in response |
| NetSuite | Offset/Limit | `?offset=N&limit=1000` |
| QLS | Page number | `next_page_token + 1` |
| EasyEcom | Page number | `page_size=50` |
| Zoho Inventory | Page context | `$.page_context.page` |
| Zoho Books | Per-page (CSV) | `per_page=200` |
| Vendit | Offset | `paginationOffset` in request body |
| Tilroy | Page number | `?page=N` |

## Base URLs

| Integration | Base URL |
|-------------|----------|
| Bol.com | `https://api.bol.com/retailer` |
| Logic4 | `https://api.logic4server.nl` |
| Montapacking | `https://api-v6.monta.nl` |
| WooCommerce | `{site_url}/wp-json/wc/v3/` |
| Exact | `https://start.exactonline.nl/api/v1/{division}` |
| Shopify | `https://{shop}.myshopify.com/admin/api/2022-01/` |
| Magento | `{shop_url}/rest/all/V1/` |
| Lightspeed C | `{base_url}/{language}/` |
| Sherpaan | Config-based (SOAP asmx endpoint) |
| Amazon | Region-specific (NA/EU/FE) |
| NetSuite | `https://{account}.suitetalk.api.netsuite.com/services/rest/record/v1` |
| QLS | Config-based |
| EasyEcom | `https://api.easyecom.io/` |
| Zoho | Region-mapped (zoho.com/zoho.eu/zoho.in/etc.) |
| Vendit | Config-based `api_url` |
| Tilroy | `https://api.tilroy.com/` |

## Stream Definitions per Tap

### Exact Online (most complex)
- `items` (Products) — PK: ID, RK: Modified
- `sales_order` — PK: OrderID, RK: Modified
- `purchase_orders` — PK: PurchaseOrderID, RK: Modified
- `warehouses` — path: /inventory/ItemWarehouses
- Uses DynamicStream (sync endpoint or standard)

### WooCommerce
- `products` — path: products, RK: date_modified
- `orders` — path: orders, RK: date_modified
- `product_variance` — path: products/{id}/variations
- `coupons`, `subscriptions`, `customers`

### Logic4
- `products` — path: /v1.1/Products/GetProducts, RK: DateTimeLastChanged
- `supplier_products_bulk` — /v1.1/Products/GetSuppliersForProducts
- `stocks` — /v1.1/Stock/GetStockForWarehouses
- `orders` — /v1.2/Orders/GetOrders, RK: ChangedAt

### Sherpaan (SOAP)
- `changed_items_information` — PK: ItemCode, RK: Token
- `changed_stock` — PK: [ItemCode, WarehouseCode], RK: Token
- `changed_suppliers` — PK: ClientCode, RK: Token
- `changed_item_suppliers_with_defaults` — PK: [ItemCode, ClientCode], RK: Token
- `changed_orders_information` — PK: OrderCode, RK: Token
- `changed_purchases` — RK: Token

### Montapacking
- `products` — path: /products, no replication key (full sync)
- `products_stock` — RK: LastModified
- `inbounds` — path: /inbounds, RK: Id (since-id pagination)
- `inboundforecast_parent` — path: /inboundforecast/group

### Bol.com
- `orders` — path: /orders, no RK
- `shipments` — path: /shipments, no RK
- `order_details` — path: /orders/{order_id}
- `shipment_details` — path: /shipments/{shipment_id}

### Odoo (XML-RPC)
- `products` — RK: write_date
- `products_uom`, `customers`, `partners`
- `sale_orders`, `sale_order_line` — RK: write_date
- `purchase_orders`, `purchase_order_lines` — RK: write_date

## SDK Usage

| Tap | SDK |
|-----|-----|
| WooCommerce | `hotglue_singer_sdk` ✅ |
| All others | `singer_sdk` (standard) |

**Important:** Only WooCommerce uses `hotglue_singer_sdk`. All other taps use standard `singer_sdk`. The ETL and target side uses `hotglue_singer_sdk`.
