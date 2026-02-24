---
tags: [integration, project, live]
integration: Shopify
type: E-commerce
auth: API Key (api_key = API Password)
status: 🟢 Live
updated: 2026-02-24
---

# Shopify Integration

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Shopify → OP | Hourly (updated) |
| Product Deletions | Shopify → OP | Daily (full sync comparison) |
| Suppliers (Vendor) | Shopify → OP | Hourly |
| Supplier Products | Shopify → OP | Hourly |
| Sell Orders | Shopify → OP | Hourly |
| Receipt Lines (Item Deliveries) | OP → Shopify | Every 15 min |

## Key Behaviors
- **Variants:** When product has variants (sizes, colors), only variants are updated — main product is skipped. Variants hold stock/price.
- **Suppliers = Vendors:** Shopify has no real supplier concept. Vendor field on product is used. Only 1 supplier per product.
- **Multiple shops:** Can pull sell orders from secondary Shopify accounts — products must share same SKU across shops.
- **updateProductStock:** Default enabled. Set `updateProductStock: false` to disable inventory sync to Shopify.
- **Sell orders:** Default: only Closed orders. Can enable all statuses. No order line updates synced.
- **Deletions:** Full sync comparison (products enabled in Optiply but not in Shopify → disabled).

## Product Mapping
| Optiply | Shopify | Notes |
|---------|---------|-------|
| name | Title + variant Title | |
| skuCode | Variant sku | |
| articleCode | Variant product_id | |
| price | Variant price | |
| unlimitedStock | inventory_management | null → true, else false |
| stockLevel | Variant.inventory_quantity | |
| status | status | Active → enabled, archived/draft → disabled |
| remoteId | variant ID | |
| eanCode | variant/barcode | |
| createdAtRemote | created_at | |

## Sell Order Mapping
| Optiply | Shopify |
|---------|---------|
| totalValue | total_price |
| placed | processed_at |
| completed | closed_at |
| remoteId | id |

### Lines
| Optiply | Shopify |
|---------|---------|
| productId | optiplyWebshopProductId |
| quantity | quantity |
| subtotalValue | price |

## Supplier Mapping
| Optiply | Shopify |
|---------|---------|
| name | vendor |

- Matched by name only (no ID from Shopify)
- If customer wants multiple suppliers per product → disable Shopify supplier sync, use FE or import

## Supplier Product Mapping
| Optiply | Shopify |
|---------|---------|
| productId | optiplyWebshopProductId |
| supplierId | optiplySupplierId |
| skuCode | sku |
| eanCode | barcode |
| price | cost (from inventory_items endpoint) |
| status | default: "enabled" |

- Cost from: `/admin/api/2022-01/inventory_items/{inventory_item_id}.json`
- If no cost set → maps as 0

## Item Deliveries (OP → Shopify)
| Optiply | Shopify |
|---------|---------|
| inventory_item_id | inventory_item_id |
| receiptLines.quantity | available_adjustment |

- Uses `/inventory_levels/adjust.json`
- `inventory_item_id` stored in integration cache, not in Optiply directly

## API Reference

> See also: [[Build Standards]] | [[ETL Patterns]]

### Base URL
`{shop}.myshopify.com/admin/api/{version}/` (REST) and `/admin/api/{graphql_version}/graphql.json` (GraphQL)

### Auth Method
- **Type:** OAuth2 (admin/oauth/access_token) OR access_token/API key directly
- **Token Refresh:** OAuth flow with client_id + client_secret → access_token. No explicit refresh (note: "if job runs longer than 24 hours, this will need to be refreshed")

### Endpoints
| Stream Name | HTTP Method | Path | Pagination |
|-------------|-------------|------|------------|
| abandoned_checkouts | GET | /checkouts.json | Date window |
| customers | GET | /customers.json | Date window + since_id |
| orders | GET | /orders.json | Date window + since_id |
| order_refunds | GET | /refunds.json | Date window |
| products | GET | /products.json | Date window + since_id |
| inventory_levels | GET | /inventory_levels.json | since_id |
| locations | GET | /locations.json | Full table |
| transactions | GET | /orders/{order_id}/transactions.json | Date window |

### Rate Limiting
- **Strategy:** `@shopify_error_handling` decorator with backoff.expo
- **Backoff Config:** Retry-After header handling (`retry-after` or `Retry-After`), max retry time: 900 seconds
- **Retries:** ServerError, JSONDecodeError, ConnectionError, RetryableAPIError, ClientError (429 only)

### Error Handling
- **429:** Exponential backoff with Retry-After
- **500+:** ServerError retry
- **Custom Exception:** `RetryableAPIError`
- **Also handles:** ResourceNotFound, UnauthorizedAccess, ForbiddenAccess

### Quirks
- Uses GraphQL to fetch shop_id if not in config
- Date windows limited to 365 days to avoid 500 errors
- Uses `pyactiveresource` library for REST resources (NOT singer_sdk)
- `_sdc_shop_*` fields added to records with shop metadata

## Target Reference

> Writing data FROM Optiply TO Shopify

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-shopify-v2](https://gitlab.com/joaoraposo/target-shopify-v2.git) |
| **Auth Method** | OAuth2 via Shopify Python library — `access_token` (API key), `shop` name |
| **Base URL** | `https://{shop}.myshopify.com/admin/api/2021-04` (shop from config) |

### Sinks/Entities

| Sink | Entity | HTTP Method |
|------|--------|-------------|
| upload_orders | `shopify.Order` | POST |
| upload_products | `shopify.Product` + `shopify.InventoryLevel` | POST |
| update_product | `shopify.Product` + `shopify.Variant` | PUT/PATCH |
| update_inventory | `shopify.InventoryLevel.adjust` | POST |
| update_fulfillments | `shopify.FulfillmentEvent` | POST |
| fulfill_order | `shopify.Fulfillment` | POST |
| upload_refunds | `shopify.Refund` | POST |

### Error Handling
- `backoff.expo` with max 5 tries on `ServerError`, `JSONDecodeError`, generic `Exception`
- 429 uses `Retry-After` header for backoff
- `pyactiveresource.connection.ClientError` handled specially

### Quirks
- Uses Shopify's `pyactiveresource` library
- GraphQL for SKU lookups (`get_variant_by_sku`)
- Reads from local JSON files in `input_path/`: `orders.json`, `products.json`, etc.

---

## ETL Summary

- **Pattern:** Old (uses custom mapping functions)
- **Entities Processed:**
  - Products (explodes variants JSON)
  - Suppliers (from Vendor field)
  - SupplierProducts
- **Key Config Flags:**
  - `sync_product_deletions` - Full sync flag for product deletions
- **Custom Logic Highlights:**
  - Variant-level inventory: Uses `variants.inventory_quantity` for stockLevel
  - Vendor extraction: Extracts unique vendors from products for supplier creation
  - Price mapping from `variants.price`, barcode from `variants.barcode`
  - Uses `is_subTenant` check for parent snapshot directories
  - Decimal handling for price/inventory values

---

## Links
- Tap: [tap-shopify](https://github.com/hotgluexyz/tap-shopify.git)
- Target: [target-shopify-v2](https://gitlab.com/joaoraposo/target-shopify-v2.git)
- ETL: `optiply-scripts/import/shopify/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853909)
