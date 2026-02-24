---
tags: [patterns, etl, reference]
updated: 2026-02-24
---

# ETL Patterns

## Snapshot Diff Logic
The ETL compares current tap output against the cached snapshot to detect:
- **New records** — exist in tap output but not in snapshot
- **Updated records** — exist in both but fields differ
- **Deleted records** — exist in snapshot but not in tap output

## Optiply Entity Mappings
Every integration must map source data to these Optiply entities:

### Products
| Optiply Field | Description | Required |
|---------------|-------------|----------|
| remoteId | Source system ID | ✅ |
| skuCode | SKU / article number | ✅ |
| name | Product name | ✅ |
| eanCode | EAN/barcode | |
| status | ENABLED / DISABLED | |
| stock | Current stock level | |

### Suppliers
| Optiply Field | Description | Required |
|---------------|-------------|----------|
| remoteId | Source system ID | ✅ |
| name | Supplier name | ✅ |
| deliveryTime | Days (1-365 or null) | |

### Sell Orders (Sales)
| Optiply Field | Description | Required |
|---------------|-------------|----------|
| remoteId | Source system ID | ✅ |
| ordered | Order date | ✅ |
| lines | Array of order lines | ✅ |

### Buy Orders (Purchases)
| Optiply Field | Description | Required |
|---------------|-------------|----------|
| remoteId | Source system ID | ✅ |
| placed | Order date | ✅ |
| supplierId | Optiply supplier ID | ✅ |
| lines | Array of order lines | ✅ |

---

*Extend with integration-specific mappings as needed.*
