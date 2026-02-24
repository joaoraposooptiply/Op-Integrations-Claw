---
tags: [integration, project, live, gold-standard]
integration: Sherpaan
type: WMS/Logistics
auth: SOAP/asmx
status: 🟢 Live (IN PROGRESS docs)
updated: 2026-02-24
---

# Sherpaan Integration

> ★ **Gold standard** — most recent, uses new Generic ETL template patterns.

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]
> API is SOAP/XML (asmx endpoints), not REST.

## Sync Board (all 60 min)
| Entity | Direction |
|--------|-----------|
| Products + Compositions | Sherpaan → OP |
| Suppliers | Sherpaan → OP |
| Supplier Products | Sherpaan → OP |
| Sell Orders (+ deletions) | Sherpaan → OP |
| Buy Orders + Lines | Sherpaan ↔ OP |
| Receipt Lines | Sherpaan → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `stock_warehouse_codes` | all | Filter stock by warehouse codes |
| `warehouse_group_code` | None | Single warehouse group for stock |
| `not_sync_suppliers_attributes` | None | Skip specific supplier fields |
| `not_sync_supProds_attributes` | None | Skip specific SP fields |
| `pullAllOrders` | true | All or only "Processed" |
| `sellOrders_warehouse_codes` | all | Filter SOs by warehouse |
| `buyOrders_warehouse_codes` | all | Filter BOs by warehouse |

## Product Mapping (SOAP: ChangedItemsInformation + ChangedStock)
- Only ItemType=Stock or Assembly
- name=Description, skuCode=ItemCode, eanCode=EanCodes[0]
- status: Active → enabled
- assembled: Assembly → true
- remoteId=ItemCode (not numeric ID)

## Compositions: from ItemAssemblies, remoteId=CONCAT(parent+part ItemCode)

## Suppliers (SOAP: ChangedSuppliers + SupplierInfo)
- name=CONCAT(Company, Name), remoteId=SupplierCode
- deliveryTime=DeliveryPeriod, userReplenishmentPeriod=OrderPeriod, emails=Email

## Supplier Products (SOAP: ChangedItemSuppliersWithDefaults)
- price=SupplierPrice, skuCode=SupplierItemCode
- deliveryTime=DeliveryPeriod, minimumPurchaseQuantity=MinPurchaseQty

## Sell Orders
- Cancelled status → delete
- No SO line deletions

## Buy Orders (bidirectional)
- Warehouse-filterable

## API Reference

> See also: [[Build Standards]], [[Sherpaan Gold Standard]] | [[ETL Patterns]]

### Base URL
`{base_url}/{shop_id}/Sherpa.asmx` (default: `https://sherpaservices-prd.sherpacloud.eu`)

### Auth Method
- **Type:** SOAP security_code in SOAP envelope header
- **Token Refresh:** N/A - static security_code

### Endpoints (SOAP Services)
| Stream Name | Method | Path | Pagination |
|-------------|--------|------|------------|
| ChangedItemsInformation | POST | /Sherpa.asmx | Token-based |
| ChangedStock | POST | /Sherpa.asmx | Token-based |
| ChangedSuppliers | POST | /Sherpa.asmx | Token-based |
| SupplierInfo | POST | /Sherpa.asmx | Token-based |
| ChangedItemSuppliersWithDefaults | POST | /Sherpa.asmx | Token-based |
| ChangedOrdersInformation | POST | /Sherpa.asmx | Token-based |
| ChangedPurchases | POST | /Sherpa.asmx | Token-based |
| PurchaseInfo | POST | /Sherpa.asmx | Token-based |
| ChangedStockByWarehouseGroupCode | POST | /Sherpa.asmx | Token-based |
| ChangedDeletedObjects | POST | /Sherpa.asmx | Token-based |

### Rate Limiting
- **Strategy:** tenacity retry
- **Backoff Config:** stop_after_attempt(3), wait_exponential(multiplier=1, min=4, max=10)
- **Config Options:** max_retries, retry_wait_min, retry_wait_max

### Error Handling
- Generic exception handling in `_make_soap_request`
- zeep SOAP client with strict=False

### Quirks
- SOAP/XML API (not REST)
- Dynamic response parsing via xmltodict
- Nested XML objects flattened with JSON serialization for complex types
- `_write_state_message` fix to clean partitions for non-incremental streams

## Target Reference

> Writing data FROM Optiply TO Sherpaan

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-sherpaan](https://github.com/joaoraposooptiply/target-sherpaan.git) |
| **Auth Method** | SOAP + custom auth — `shop_id`, `security_code` in SOAP envelope |
| **Base URL** | `https://sherpaservices-prd.sherpacloud.eu` (configurable) |

### Sinks/Entities

| Sink | SOAP Method | HTTP Method |
|------|-------------|-------------|
| PurchaseOrderSink | `AddOrderedPurchase` + `ChangePurchase2` | SOAP POST |

### Error Handling
- `tenacity.retry` with 3 attempts, exponential backoff (4-10s)
- Raises on HTTP errors

### Quirks
- Uses SOAP (not REST)
- Two-step process: first `AddOrderedPurchase`, then `ChangePurchase2` for lines
- XML payloads with namespace `http://sherpa.sherpaan.nl/`
- Timeout configurable (default 300s)

---

## ETL Summary

- **Pattern:** NEW Generic (gold standard - most recent template)
- **Entities Processed:**
  - Products (+ Compositions)
  - Suppliers
  - SupplierProducts
  - SellOrders
  - BuyOrders (+ Lines)
  - ReceiptLines
- **Key Config Flags:**
  - `stock_warehouse_codes` - Filter stock by warehouse codes
  - `warehouse_group_code` - Single warehouse group for stock
  - `not_sync_suppliers_attributes` - Skip specific supplier fields
  - `not_sync_supProds_attributes` - Skip specific SP fields
  - `pullAllOrders` - All or only "Processed"
  - `sellOrders_warehouse_codes` - Filter SOs by warehouse
  - `buyOrders_warehouse_codes` - Filter BOs by warehouse
- **Custom Logic Highlights:**
  - Gold standard - uses new Generic ETL template patterns
  - Only ItemType=Stock or Assembly products synced
  - Compositions from ItemAssemblies, remoteId=CONCAT(parent+part ItemCode)
  - Sell order deletions for cancelled status
  - Bidirectional buy orders with warehouse filtering

---

## Links
- Tap: [tap-sherpaan](https://github.com/Optiply/tap-sherpaan.git)
- Target: [target-sherpaan](https://github.com/joaoraposooptiply/target-sherpaan.git)
- ETL: `optiply-scripts/import/sherpaan/etl.ipynb`
- API: [SOAP/asmx](https://sherpaservices-prd.sherpacloud.eu/406/Sherpa.asmx)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3170369561)
