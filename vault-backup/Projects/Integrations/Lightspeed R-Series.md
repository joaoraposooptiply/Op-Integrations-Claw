---
tags: [integration, project, live]
integration: Lightspeed R-Series
type: Retail/POS
auth: OAuth2
status: 🟢 Live
updated: 2026-02-24
---

# Lightspeed R-Series Integration

> Retail POS. Multi-location, bidirectional, supports compositions.

## Sync Board (all 30 min)
| Entity | Direction |
|--------|-----------|
| Products + Compositions | LS-R → OP |
| Suppliers | LS-R → OP |
| Supplier Products | LS-R → OP |
| Sell Orders | LS-R → OP |
| Buy Orders + Lines | LS-R ↔ OP |
| Receipt Lines | LS-R → OP |

## Config
| Setting | Notes |
|---------|-------|
| Account ID | Unique admin account ID |
| Default Location Code | Main location for BO export (case-sensitive) |
| Get Data From | All Locations / Multiple (comma-separated) / One (default) |
| Sync All Sales Orders | Default: only completed. Enable for all statuses. |

## Product Mapping
- name=description, skuCode=customSku (fallback systemSku)
- price=Prices.Default.amount, stockLevel=qoh per shop
- status: archived=true → disabled
- assembled: itemType "assembly" or "box"
- minimumStock=reorderPoint
- Item types: default, non_inventory (filtered out), assembly, box

## Compositions: assemblyItemID → composedProduct, componentItemID → partProduct

## Suppliers: Vendor.json, name+vendorID

## Supplier Products: from vendor items

## Sell Orders: by location, completed or all statuses

## Buy Orders (bidirectional)
- Export to specific location (Default Location Code)

## Troubleshooting (from Confluence)
- Products not syncing → check item type isn't non_inventory
- Sales orders missing → check Sync All Sales Orders flag
- BO not creating in LS → verify location code (case-sensitive)
- Stock incorrect → verify location selection

## Links
- Tap: [tap-lightspeed-rseries](https://github.com/mariocostaoptiply/tap-lightspeed-rseries.git)
- Target: [target-lightspeed-r-series](https://gitlab.com/mariocosta_opt/target-lightspeed-r-series.git)
- ETL: `optiply-scripts/import/LightSpeed_r_series/etl.ipynb`
- API: [Retail API](https://developers.lightspeedhq.com/retail/introduction/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3422748673)
