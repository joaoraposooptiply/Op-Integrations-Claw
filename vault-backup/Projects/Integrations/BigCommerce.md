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

## Links
- Tap: [tap-bigcommerce-v2](https://github.com/hotgluexyz/tap-bigcommerce-v2)
- Target: [target-bigcommerce](https://gitlab.com/hotglue/target-bigcommerce)
- ETL: `optiply-scripts/import/bigcommerce/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2315354128)
