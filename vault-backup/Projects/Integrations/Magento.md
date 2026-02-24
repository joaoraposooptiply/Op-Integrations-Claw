---
tags: [integration, project, live]
integration: Magento 2
type: E-commerce
auth: API Key (Bearer token)
status: 🟢 Live
updated: 2026-02-24
---

# Magento 2 Integration

> Two variants: **Non-Warehouse** (simpler) and **Warehouse** (MSI multi-source inventory).
> Stock endpoint has NO `updated_at` filter — forces full syncs.

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Magento → OP | 30 min (updated) |
| Product Deletions | Magento → OP | 60 min (full sync comparison) |
| Stocks | Magento → OP | 30 min (always full) |
| Sell Orders | Magento → OP | 30 min |

- **Full sync required** for stock (no updated_at filter on stock endpoint)
- Frequency varies per shop size (60min for small, daily for large)
- Deleted products: detected by full sync comparison (enabled in OP but gone from Magento)

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `map_stockLevel` | true | Disable if customer uses third-party stock sync |
| salable_quantity vs quantity | salable_quantity | Which stock field to use |

## Product Mapping
| Optiply | Magento |
|---------|---------|
| name | name |
| skuCode | sku |
| articleCode | id |
| price | price |
| unlimitedStock | type!="simple" OR manage_stock=false → true |
| stockLevel | qty (from stockStatuses/{SKU}) |
| status | 1=enabled, 2=disabled |
| createdAtRemote | created_at |

## Sell Orders
- totalValue=subtotal, placed=created_at, completed=updated_at
- Default: only completed. Customer can choose all.
- No order updates synced

### Lines
- productId=product_id, quantity=qty_ordered, subtotalValue=base_row_total

## Warehouse Variant
- Uses MSI (Multi-Source Inventory) for stock
- Stock from specific source(s) configurable
- Same product/order mappings

## Key Complexity
- No delete API → full sync comparison required
- No stock updated_at → forced full syncs for stock (expensive for large catalogs)

## Links
- Tap: [tap-magento](https://github.com/hotgluexyz/tap-magento)
- Target: [target-magento](https://gitlab.com/hotglue/target-magento)
- ETL: `optiply-scripts/import/magento/etl.ipynb`
- Confluence: [Non-Warehouse](https://optiply.atlassian.net/wiki/spaces/IN/pages/2344845313) / [Warehouse](https://optiply.atlassian.net/wiki/spaces/IN/pages/2443083785)
