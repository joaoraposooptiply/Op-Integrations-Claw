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

## Links
- Tap: [tap-woocommerce](https://github.com/hotgluexyz/tap-woocommerce)
- Target: [target-woocommerce-v2](https://github.com/hotgluexyz/target-woocommerce-v2)
- ETL: `optiply-scripts/import/woocommerce/etl.ipynb`
- API: [REST API Docs](https://woocommerce.com/document/woocommerce-rest-api/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853870)
- [Common Errors](https://optiply.atlassian.net/wiki/spaces/IN/pages/3340042241)
