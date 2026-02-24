---
tags: [integration, project, live]
integration: Amazon Seller
type: Marketplace
auth: SP-API (OAuth2 + AWS IAM)
status: 🟢 Live
updated: 2026-02-24
---

# Amazon Seller Integration

> Two flavours: **Secondary** (sell orders only) and **Full** (products + sell orders).

## API Regions
| Region | Endpoint | AWS Region |
|--------|----------|------------|
| North America | sellingpartnerapi-na.amazon.com | us-east-1 |
| Europe | sellingpartnerapi-eu.amazon.com | eu-west-1 |
| Far East | sellingpartnerapi-fe.amazon.com | us-west-2 |

- Supports multiple marketplaces per account

## Sync Board (all 30 min)
### Secondary (sell orders only)
| Entity | Direction |
|--------|-----------|
| Sell Orders | Amazon → OP |

- Products from another source (Shopify/WooCommerce etc.)
- Customer selects mapping key: skuCode or eanCode

### Full
| Entity | Direction |
|--------|-----------|
| Products | Amazon → OP |
| Sell Orders | Amazon → OP |

## Product Mapping
| Optiply | Amazon |
|---------|--------|
| name | products_inventory.item-name |
| skuCode | identifiers.identifierType=SKU |
| eanCode | identifiers.identifierType=EAN |
| price | products_inventory.price |
| stockLevel | warehouse_inventory.totalQuantity |
| remoteId | items.asin |

## Sell Orders
| Optiply | Amazon |
|---------|--------|
| totalValue | Orders.OrderTotal.Amount |
| placed | Orders.PurchaseDate |
| remoteId | Orders.AmazonOrderId |

### Lines
| Optiply | Amazon |
|---------|--------|
| productId | OrderItems.ASIN |
| quantity | OrderItems.QuantityOrdered |
| subtotalValue | OrderItems.ItemPrice.Amount |

No order updates synced. No target (inbound only).

## Links
- Tap: [tap-amazon-seller](https://github.com/hotgluexyz/tap-amazon-seller)
- ETL: `optiply-scripts/import/amazon/etl.ipynb`
- API: [SP-API](https://developer-docs.amazon.com/sp-api/) / [Swagger](https://spapi.cyou/swagger/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2717188110)
