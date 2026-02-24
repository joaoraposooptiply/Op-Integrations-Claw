---
tags: [integration, project, live]
integration: BigCommerce
type: E-commerce
status: 🟢 Live
updated: 2026-02-24
---

# BigCommerce Integration

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | BigCommerce → OP | Hourly |
| Sell Orders | BigCommerce → OP | Hourly |

## Product Mapping
| Optiply | BigCommerce | Notes |
|---------|-------------|-------|
| name | products.name + variants.label | |
| skuCode | variants.sku | |
| eanCode | products.upc | |
| price | variant.calculated_price or products.price | |
| unlimitedStock | inventory_tracking | "none" → true |
| stockLevel | products.inventory_level or variants.inventory_level | Depends on tracking type |
| articleCode | id (ParentId for variants) | |
| remoteId | variants.id | |
| status | availability | "available" → enabled |

## Sell Orders
| Optiply | BigCommerce |
|---------|-------------|
| totalValue | total_ex_tax |
| placed | date_created |
| remoteId | id |

- Default: only completed orders. `AllSellOrders` flag for all statuses.
- Deletions: Cancelled, Refunded, Declined
- No completed date mapped
- No order line updates synced

### Lines
| Optiply | BigCommerce |
|---------|-------------|
| productId | Products.product_id |
| quantity | Products.quantity |
| subtotalValue | Products.total_ex_tax × quantity |

## API Reference

> See also: [[Build Standards]] | [[ETL Patterns]]

### Base URL
`https://api.bigcommerce.com/stores/{store_hash}`

### Auth Method
- **Type:** API Key (X-Auth-Token header)
- **Token Refresh:** N/A - static access_token

### Endpoints
| Stream Name | HTTP Method | Path | Pagination |
|-------------|-------------|------|------------|
| category_trees | GET | /v3/catalog/trees | Meta pagination |
| categories | GET | /v3/catalog/categories | Meta pagination |
| coupons | GET | /v2/coupons | Page-based |
| customers | GET | /v3/customers | Meta pagination |
| orders | GET | /v2/orders | Page-based (204 handling) |
| products | GET | /v3/catalog/products | Meta pagination |
| product_images | GET | /v3/catalog/products/{id}/images | Meta pagination |
| variants | GET | /v3/catalog/products/{id}/variants | Meta pagination |
| order_lines | GET | /v2/orders/{id}/products | Page-based |
| refunds | GET | /v2/refunds | Page-based |
| transactions | GET | /v2/orders/{id}/transactions | Page-based |

### Rate Limiting
- **Strategy:** `backoff.on_exception` with configurable `backoff_max_tries`
- **Retries:** RetriableAPIError, ReadTimeout, ConnectionError

### Error Handling
- **extra_retry_statuses:** [429, 422, 401]
- **204:** No content (valid response)
- `_write_state_message` fix for partition cleanup

### Quirks
- Two API versions: V2 (page-based) and V3 (meta pagination)
- Channel filtering via `channel_id` config (query string or body)
- Filter by channel_id in query string or request body based on stream

---

## ETL Summary

- **Pattern:** Old
- **Entities Processed:**
  - Products
  - SellOrders
- **Key Config Flags:**
  - `AllSellOrders` - Sync all order statuses (not just completed)
- **Custom Logic Highlights:**
  - Default: only completed orders synced
  - Deletions: Cancelled, Refunded, Declined
  - No completed date mapped
  - No order line updates synced

---

## Links
- Tap: [tap-bigcommerce-v2](https://github.com/hotgluexyz/tap-bigcommerce-v2)
- Target: [target-bigcommerce](https://gitlab.com/hotglue/target-bigcommerce)
- ETL: `optiply-scripts/import/bigcommerce/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2315354128)
