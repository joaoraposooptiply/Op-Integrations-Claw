---
tags: [integration, project, live]
integration: Montapacking
type: WMS/Fulfillment
status: 🟢 Live
updated: 2026-02-24
---

# Montapacking Integration

> Two flavours: **Simple** (BO + Receipts only) and **Full** (all entities).

## Sync Board
### Simple (1st flavour)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Buy Orders | OP → Monta | 15 min |
| Buy Orders | Monta → OP | 30 min |
| Receipt Lines | Monta → OP | 30 min |

### Full (2nd flavour — adds these)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Monta → OP | 30 min |
| Suppliers | Monta → OP | 30 min |
| Supplier Products | Monta → OP | 30 min |
| Sell Orders | Monta → OP | 30 min |

**Important (Simple):** Customer must put Optiply supplier IDs into Monta Supplier Codes manually.

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `use_StockInTransit` | false | Add transit stock to stockLevel |
| `sync_minimum_stock` | false | Map MinimumStock |
| `use_return_forecasts` | false | Add return forecast to stock |
| CustomField1 for SP name | off | Alternative name mapping |
| `sync_leadTime_supProducts` | false | Sync LeadTime |
| `del_bol_completed` | false | Delete approved-but-unreceived BOLs |

## Product Mapping
| Optiply | Monta |
|---------|-------|
| name | Description |
| skuCode | Sku |
| eanCode | Barcodes[0] |
| price | SellingPrice |
| stockLevel | StockAvailable (+StockInTransit if flag) (+returns if flag) |
| minimumStock | MinimumStock (if flag) |
| remoteId | productId |

**Note:** Inactive products on Monta stop syncing — status change NOT reflected on OP automatically.

## Suppliers: name=Title, email=AddressEmail, remoteId=Code

## Supplier Products
- **Only 1 supplier per product** in Monta
- If supplier changes → delete old SP + create new
- price=PurchasePrice, lotSize=PurchaseStepQty
- weight=WeightGrammes, volume=(L×W×H)/1000
- deliveryTime=LeadTime

## Sell Orders
- totalValue=0, placed=Received, completed=Shipped (or Received if no Shipped)
- Monta max 1 year pull per job
- Deletions synced (Deleted:true)
- subtotalValue=0 on lines

## Buy Orders (OP → Monta)
- Maps as InboundForecastGroup
- DeliveryDate = placed + supplier.deliveryTime
- Lines sorted by skuCode ascending

## Receipt Lines
- Mapped from InboundForecast.ReceivedQuantity
- Only quantities > 0

## Links
- Tap: [tap-montapacking](https://gitlab.com/hotglue/tap-montapacking)
- Target: [target-montapacking-v2](https://github.com/hotgluexyz/target-montapacking-v2)
- ETL: `optiply-scripts/import/montapacking/etl.ipynb`
- API: [API v6](https://api-v6.monta.nl/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2301886535)
