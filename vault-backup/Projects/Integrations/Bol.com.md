---
tags: [integration, project, live]
integration: Bol.com
type: Marketplace
auth: BOL Retailer API
status: 🟢 Live
updated: 2026-02-24
---

# Bol.com Integration

> **Secondary integration only** — only syncs Sell Orders. Products come from another source.

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Sell Orders | BOL → OP | 60 min (matches primary source) |
| Sell Order Lines | BOL → OP | 60 min |

## Important
- BOL is always a **secondary** integration — products, suppliers, supplierProducts come from another source (WooCommerce, Shopify, etc.)
- Mapping key: customer chooses **skuCode** or **eanCode** (BOL's main key is EAN)
- FE shows option to select mapping key
- Syncs FBR (Fulfilled by Retailer) AND FBB (Fulfilled by bol.com) orders/shipments
- No order updates synced — no line changes, deletions, or additions

## Sell Order Mapping
| Optiply | BOL |
|---------|-----|
| totalValue | sum(sellOrderLine.subtotalValue) |
| placed | orderPlacedDateTime |
| remoteId | orderId |

## Sell Order Lines
| Optiply | BOL |
|---------|-----|
| productId | optiplyWebshopProductId |
| quantity | quantity |
| subtotalValue | unitPrice × quantity |

## Links
- Tap: [tap-bol](https://gitlab.com/hotglue/tap-bol)
- ETL: `optiply-scripts/import/bol.com/etl.ipynb`
- API: [Retailer API](https://api.bol.com/retailer/public/Retailer-API/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2524643339)
