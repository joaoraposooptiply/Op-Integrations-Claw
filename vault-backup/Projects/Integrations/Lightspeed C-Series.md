---
tags: [integration, project, live]
integration: Lightspeed C-Series
type: E-commerce/POS
status: 🟢 Live
updated: 2026-02-24
---

# Lightspeed C-Series Integration

## Sync Board (all every 10 min)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | LS → OP | 10 min |
| Suppliers | LS → OP | 10 min |
| Supplier Products | LS → OP | 10 min |
| Sell Orders | LS → OP | 10 min |
| Sell Order Deletions | LS → OP | 10 min (cancelled) |
| Receipt Lines | OP → LS | 15 min |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_products_hidden` | false | Sync hidden products as enabled |
| lotSize sync | off | Opt-in lotSize from variant.Colli |
| `sellorders_delete_statuses` | "cancelled" | Custom delete status list |
| Item Deliveries to LS | off | Update stock in LS on delivery |

## Product Mapping
| Optiply | Lightspeed |
|---------|------------|
| name | product.title + title_variant |
| skuCode | variant sku |
| articleCode | variant articleCode |
| price | variant priceExcl |
| unlimitedStock | stockTracking=disabled → true |
| status | visibility=hidden → disabled |
| stockLevel | variant stockLevel |
| remoteId | variant id |

## Suppliers: name (or id if no name), country, remoteId=id

## Supplier Products
| Optiply | Lightspeed |
|---------|------------|
| price | variant priceCost |
| lotSize | variant.Colli (if ≥1) |
| supplier | product.supplier |
| eanCode | variant ean |

## Sell Orders
- Many statuses synced (processing*, completed*)
- cancelled → delete
- totalValue = 0 (TBD — not properly mapped)
- No order updates

## Links
- Tap: [tap-lightspeed](https://github.com/hotgluexyz/tap-lightspeed)
- Target: [target-lightspeed](https://github.com/hotgluexyz/target-lightspeed)
- ETL: `optiply-scripts/import/LightSpeed/etl.ipynb`
- API: [eCom API](https://developers.lightspeedhq.com/ecom/introduction/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2777874433)
