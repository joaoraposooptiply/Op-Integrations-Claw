---
tags: [integration, project, live]
integration: Tilroy
type: Retail/POS
auth: API Key
status: 🟢 Live (target untested)
updated: 2026-02-24
---

# Tilroy Integration

> Belgian fashion/retail POS. Multi-language, multi-shop, SKU-level (colour/size variants).
> ⚠️ Target is NOT tested/done.

## Sync Board (all 30 min)
| Entity | Direction |
|--------|-----------|
| Products + Deletions | Tilroy → OP |
| Suppliers | Tilroy → OP |
| Supplier Products | Tilroy → OP |
| Sell Orders | Tilroy → OP |
| Buy Orders + Lines | Tilroy ↔ OP |
| Receipt Lines | Tilroy → OP |

Not synced: Product Compositions, Supplier Deletions

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `languageCode` | "NL" | Product name language (NL/FR/EN) |
| `shop_ids` | "" (all) | Filter stock/prices/sales by shop IDs |
| `use_product_details` | false | Richer SKU data but only 1 supplier/product |

## Product Mapping
- name = description[lang].standard + " - " + size.code
- skuCode = colours.skus.tilroyId
- eanCode = colours.skus.barcodes.code
- price = best current price (promo if cheaper, else standard)
- stockLevel = qty.available (shop-filterable, summed)
- remoteId = tilroyId + "_" + skuTilroyId

## Suppliers: name, code as remoteId, deliveryTime (0 treated as null)
## Supplier Products: price=costPrice, remoteId=tilroyId+skuCode+supplierId
## Sell Orders: totalValue=vat.amountNet, placed=saleDate, shop-filterable

## Buy Orders (bidirectional)
## Receipt Lines: from Tilroy

## Links
- Tap: [tap-tilroy](https://github.com/joaoraposooptiply/tap-tilroy.git)
- Target: [target-tilroy](https://github.com/joaoraposooptiply/target-tilroy.git) ⚠️ untested
- ETL: `optiply-scripts/import/tilroy/etl.ipynb`
- API: [API Overview](https://tilroy-dev.atlassian.net/wiki/spaces/TAD/pages/870481921)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3218735105)
