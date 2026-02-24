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

## Links
- Tap: [tap-shopify](https://github.com/hotgluexyz/tap-shopify.git)
- Target: [target-shopify-v2](https://gitlab.com/joaoraposo/target-shopify-v2.git)
- ETL: `optiply-scripts/import/shopify/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301853909)
