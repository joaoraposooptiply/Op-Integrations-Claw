---
tags: [integration, project, live]
integration: WooCommerce
type: E-commerce
auth: Consumer Key + Secret
status: 🟢 Live
updated: 2026-02-24
---

# WooCommerce Integration

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | WooCommerce → OP | Hourly (updated) or daily full sync |
| Product Deletions | WooCommerce → OP | Daily |
| Stocks | WooCommerce → OP | Hourly + on sell orders |
| Sell Orders | WooCommerce → OP | Hourly |
| Receipt Lines | OP → WooCommerce | Every 15 min |

## API Notes
- **API < 5.6:** No `modified_at` filter → daily full sync for products
- **API ≥ 5.6:** Hourly incremental product sync
- Deleted products not returned by API → full sync comparison to detect

## Options & Features
- **SubTenants:** Secondary shop pulls only sell orders, maps via SKU to main shop products. Flag: `sync_products: false`
- **pullAllOrders:** Default `false` (only completed orders). Set `true` for all statuses.
- **Stock update to WooCommerce:** When delivery created in Optiply → update product stock. Off by default. Cannot be changed in FE — requires Customer Support.

## Product Mapping
| Optiply | WooCommerce | Notes |
|---------|-------------|-------|
| name | name | |
| skuCode | sku | |
| articleCode | id | |
| price | price | |
| unlimitedStock | virtual/downloadable/manage_stock | FALSE if: !virtual AND !downloadable AND manage_stock=true |
| stockLevel | stock_quantity | |
| status | status | 'publish' → enabled, else disabled |

- Products with type "variable" not mapped (parent products without purchases)
- SubTenant secondary shop: products not synced

## Sell Order Mapping
| Optiply | WooCommerce |
|---------|-------------|
| totalValue | total |
| placed | date_created_gmt |
| completed | date_modified_gmt |
| remoteId | id |

### Sell Order Lines
| Optiply | WooCommerce |
|---------|-------------|
| productId | line_items.variation_id (or line_items.sku for subtenant) |
| quantity | line_items.quantity |
| subtotalValue | line_items.subtotal |

- **Default:** Only completed orders synced
- **Deletions:** Orders cancelled/refunded/failed → deleted
- **No line updates:** Line deletions or additions to existing orders NOT synced

## API Reference

> See also: [[Build Standards]] | [[ETL Patterns]]

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

### Base URL
`{site_url}/wp-json/wc/v3/`

### Auth Method
- **Type:** Basic Auth (consumer_key + consumer_secret as username/password)
- **Token Refresh:** N/A - Basic Auth with static credentials

### Endpoints
| Stream Name | HTTP Method | Path | Pagination |
|-------------|-------------|------|------------|
| products | GET | /products | Page-based (X-WP-TotalPages) |
| orders | GET | /orders | Page-based |
| coupons | GET | /coupons | Page-based |
| product_variations | GET | /products/{id}/variations | Page-based |
| subscriptions | GET | /subscriptions | Page-based |
| customers | GET | /customers | Page-based |
| store_settings | GET | /system_status | Full table |
| order_notes | GET | /orders/{id}/notes | Page-based |
| orders_refunds | GET | /orders/{id}/refunds | Page-based |

### Rate Limiting
- **Strategy:** `backoff.expo` with max_tries=10, factor=4
- **Backoff Config:** Exponential backoff, factor=4
- **Retries:** RetriableAPIError, ReadTimeout, ConnectionError, ProtocolError, RemoteDisconnected, ChunkedEncodingError

### Error Handling
- **401:** InvalidCredentialsError
- **429, 500-599, 403, 104:** RetriableInvalidCredentialsError
- **400-499:** InvalidCredentialsError (Fatal)
- **Config Option:** `ignore_server_errors` to skip validation

### Quirks
- Auto-detects WooCommerce version via `/system_status` endpoint
- Older versions (<5.6) use different date filtering (`after` vs `modified_after`)
- Random User-Agent rotation to avoid rate limits
- Custom meta_data processing (JSON serialization of complex objects)

## Target Reference

> Writing data FROM Optiply TO WooCommerce

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-woocommerce-v2](https://github.com/hotgluexyz/target-woocommerce-v2) |
| **Auth Method** | Basic Auth — `consumer_key`:`consumer_secret` base64 encoded |
| **Base URL** | `{site_url}/wp-json/wc/v3/` (site_url from config) |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| ProductSink | `products` | POST |
| UpdateInventorySink | `products/{id}` | PUT |
| SalesOrdersSink | `orders` | POST |
| OrderNotesSink | `orders/{id}/notes` | POST |

### Error Handling
- Custom error handling with specific messages for 404, 403, 401, 429
- Reports failures with detailed error context

### Quirks
- Rotates User-Agent (random_user_agent library) — WooCommerce blocks default agents
- Reference data fetching with pagination (`get_reference_data`)
- Export statistics tracking per sink

---

## ETL Summary

- **Pattern:** Old (simplest in batch)
- **Entities Processed:**
  - Products only
- **Key Config Flags:**
  - `sync_product_deletions` - Full sync flag
- **Custom Logic Highlights:**
  - Simpler product mapping than Shopify
  - Handles product status (enabled/disabled)
  - Webhook support for product deletions
  - Most minimal ETL in this batch
  - No snapshot-based change detection (compares full input)

---

## Links
- Tap: [tap-woocommerce](https://github.com/hotgluexyz/tap-woocommerce)
- Target: [target-woocommerce-v2](https://github.com/hotgluexyz/target-woocommerce-v2)
- ETL: `optiply-scripts/import/woocommerce/etl.ipynb`
- API: [REST API Docs](https://woocommerce.com/document/woocommerce-rest-api/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853870)
- [Common Errors](https://optiply.atlassian.net/wiki/spaces/IN/pages/3340042241)
