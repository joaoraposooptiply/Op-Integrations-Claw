---
tags: [etl, template, reference, critical]
source: /Users/jay/Documents/Optiply/optiply-scripts/import/Generic/etl.ipynb
updated: 2026-02-24
---

# Generic ETL Template — Master Reference

> This is THE template for all future ETLs. Source: `optiply-scripts/import/Generic/etl.ipynb`
> The Sherpaan integration is the best real-world example using this template.

## Architecture Overview

```
Tap Output (sync-output/) 
  → Read input_data (gluestick Reader)
  → Custom mapping per integration (rename columns to Optiply schema)
  → Global mapping (standardize types, validate, clean)
  → Snapshot diff (new / updated / deleted detection)
  → Resolve Optiply IDs (merge with snapshots)
  → Build payloads (Pydantic models → clean JSON)
  → API requests (POST new / PATCH updated / DELETE removed)
  → Update snapshots (always, even on failure — partial progress saved)
```

## Directory Structure
```
ROOT_DIR/
├── sync-output/     ← Tap output goes here (CSV/JSON from Singer)
├── etl-output/      ← ETL output (unused in most flows)
├── snapshots/       ← Persistent state between runs
│   ├── tenant-config.json
│   ├── config_googlesheets_backup.json
│   ├── products.snapshot.csv
│   ├── suppliers.snapshot.csv
│   ├── supplier_products.snapshot.csv
│   ├── product_compositions.snapshot.csv
│   ├── sell_orders.snapshot.csv
│   ├── buy_orders.snapshot.csv
│   ├── buy_order_lines.snapshot.csv
│   └── receipt_lines.snapshot.csv
└── config.json      ← Integration-specific config
```

## Entity Processing Order (STRICT — dependencies matter)
1. **Products** — no dependencies
2. **Product Compositions** — depends on Products snapshot (composedProductId, partProductId)
3. **Suppliers** — no dependencies
4. **Supplier Products** — depends on Products + Suppliers snapshots (productId, supplierId)
5. **Sell Orders + Lines** — depends on Products snapshot (productId in lines)
6. **Buy Orders** — depends on Suppliers snapshot (supplierId)
7. **Buy Order Lines** — depends on Buy Orders + Products snapshots (buyOrderId, productId)
8. **Receipt Lines (Item Deliveries)** — depends on Buy Order Lines snapshot (buyOrderLineId)

## Per-Entity Flow Pattern (repeats for each entity)

### Phase 1: Custom Mapping
Integration-specific column renames, data extraction, type coercion.
Each ETL has a "Custom" cell per entity where integration-specific transforms go.

### Phase 2: Global Mapping
Standardizes ALL entities with:
- Column name normalization (lowercase → camelCase)
- Type coercion (remoteId → str, stockLevel → int, price → float rounded to 2)
- Date formatting (truncate to `YYYY-MM-DDTHH:MM:SSZ`)
- Validation (remove null/empty/NaN remoteIds, deduplicate)
- `concat_attributes` column — concatenation of all non-date fields for change detection

### Phase 3: Snapshot Diff
```python
snapshot = get_snapshot("entity_name", SNAPSHOT_DIR)
if snapshot exists and input exists:
    new_records = input[~input.remoteId.isin(snapshot.remoteId)]
    update_records = input[input.remoteId.isin(snapshot.remoteId)]
else:
    new_records = input  # First run: everything is new
    update_records = None
```

**Change detection:** Uses `concat_attributes` (all non-date fields concatenated with `|`).
If `concat_attributes != concat_attributes_snap` → record changed → include in update.

**Delete detection:** Via `deleted_at` field from tap output.
- Records with `deleted_at` set → mark for deletion
- Some entities also detect "supplier changed" → delete old + create new

### Phase 4: ID Resolution
For entities with foreign keys (supplierProducts, sellOrderLines, buyOrderLines, etc.):
- Merge with parent snapshot to resolve remoteId → optiply_id
- Example: `supplier_products.Remote_productId` → merge with `products_snapshot.remoteId` → get `optiply_id` → set as `productId`

### Phase 5: API Requests (DELETE → POST → PATCH)
**Always in this order:**

#### DELETE
```python
for row in delete_records:
    response = delete_optiply(api_creds, auth, optiply_id, entity)
    if response.status_code == 404:  # Already deleted
        continue
delete_from_snapshot(delete_records, snapshot_name, SNAPSHOT_DIR, pk="remoteId")
```

#### POST (new records)
```python
for row in new_records:
    payload = get_payload_function(row, entity)
    response = post_optiply(api_creds, auth, payload, entity)
    new_records.loc[i, "optiply_id"] = response.json()["data"]["id"]
# ALWAYS snapshot even on failure (finally block)
snapshot_records(new_records, snapshot_name, SNAPSHOT_DIR, pk="remoteId")
```

#### PATCH (updated records)
```python
for row in update_records:
    payload = get_payload_function(row, entity)
    response = patch_optiply(api_creds, auth, payload, optiply_id, entity)
    update_records.loc[i, "response_code"] = response.status_code
# Only snapshot records where response_code == 200
snapshot_records(update_records[response_code==200], ...)
```

## Key Design Patterns

### 1. Crash-Safe Snapshots
All POST/PATCH operations use `try/except/finally`. The `finally` block ALWAYS snapshots whatever was successfully processed. This means:
- If ETL crashes at record 50 of 100, records 1-49 are snapshotted
- Next run picks up from record 50
- No duplicates, no data loss

### 2. Entity-Specific Edge Cases

**Products:**
- `unlimitedStock` defaults to False on POST, None on PATCH
- Disabled products (`status == "disabled"`) are not POSTed as new
- After product compositions are created, parent product gets `assembled = True`

**Suppliers:**
- Invalid email addresses: caught on 400 response, retried without emails
- Supplier UUID captured alongside optiply_id
- Delete commented out (`#delete_records = delete_suppliers`) — suppliers not deleted by default

**Supplier Products:**
- 409 Conflict handling: if already exists, GET the existing optiply_id
- 404 on PATCH: re-POST (record was deleted in Optiply but still exists in remote)
- Supplier change detection: if supplierId changed → delete old + create new
- `deliveryTime == 0` fix: split into two groups, set 0 values to None

**Sell Orders:**
- Lines are nested inside the order payload (SellOrderWithLines)
- Lines grouped by order → `orderLines` array in payload
- Only new sell orders posted (no updates)
- Snapshot only keeps remoteId + optiply_id (minimal)

**Buy Orders:**
- Supports 2-way sync: BOs created in Optiply are tracked via export snapshots
- Supplier change detection: if supplierId changed → delete old BO + create new
- `completed` date tracked — only open BOs are eligible for updates
- Cascade: deleting a BO also deletes its lines from snapshot

**Buy Order Lines:**
- If no remoteId: auto-generate from `buyOrderId_productId`
- Cross-order moves detected: if buyOrderId changed → delete + recreate
- Lines from Optiply-exported BOs are fetched and added to snapshot

**Receipt Lines:**
- Only quantities > 0 are processed
- If no `occurred` date: defaults to current UTC timestamp

### 3. API Request Patterns
```python
# All requests go through auth._request() which handles token refresh
# Base URL: https://api.optiply.com/v1
# URL pattern: {base}/{entity}?accountId={id}&couplingId={id}
# Payload: {"data": {"type": entity, "attributes": {payload}}}
# Content-Type: application/vnd.api+json
```

### 4. Memory Management
ETL aggressively deletes DataFrames after use (`del products`, `gc.collect()`).
This is critical for large datasets — Jupyter notebooks can run out of memory.

## Pydantic Models (Payload Validation)

### Product
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| name | str | ✅ | Max 255 chars |
| stockLevel | int | ✅ | Max 9,999,999 |
| remoteId | str | Optional | |
| unlimitedStock | bool | Optional | Default False on POST |
| skuCode | str | Optional | |
| articleCode | str | Optional | Defaults to remoteId |
| eanCode | str | Optional | |
| price | float | Optional | Rounded to 2dp, min 0 |
| status | str | Optional | "enabled" or "disabled" |
| assembled | bool | Optional | |
| createdAtRemote | datetime | Optional | |
| notBeingBought | bool | Optional | |
| minimumStock | int | Optional | |
| remoteDataSyncedToDate | datetime | Optional | Always set to UTC now |

### Supplier
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| name | str | ✅ | Max 255 chars |
| remoteId | str | ✅ | |
| emails | List[str] | Optional | Validated, can cause 400 |
| deliveryTime | int | Optional | 1-365 or null |
| fixedCosts | float | Optional | |
| userReplenishmentPeriod | int | Optional | |
| ignored | bool | Optional | |
| remoteDataSyncedToDate | datetime | ✅ | |

### SupplierProduct
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| name | str | ✅ | Fallback to product name |
| remoteId | str | ✅ | |
| productId | str | ✅ | Optiply product ID |
| supplierId | str | ✅ | Optiply supplier ID |
| price | float | Optional | |
| deliveryTime | int | Optional | 1-365 or null |
| lotSize | int | Optional | Min 1 |
| minimumPurchaseQuantity | int | Optional | Min 1 |
| skuCode, eanCode, articleCode | str | Optional | |
| preferred | bool | Optional | |
| freeStock | int | Optional | Min 0 |
| weight | float | Optional | Grams |
| volume | float | Optional | cm³ |

### SellOrderWithLines
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| remoteId | str | Optional | |
| totalValue | float | ✅ | |
| placed | datetime | ✅ | |
| orderLines | list | ✅ | Array of {quantity, subtotalValue, productId} |
| completed | datetime | Optional | |

### BuyOrder
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| remoteId | str | ✅ | |
| supplierId | str | ✅ | Optiply supplier ID |
| placed | datetime | ✅ | |
| totalValue | float | ✅ | |
| completed | datetime | Optional | |
| expectedDeliveryDate | datetime | Optional | |

### BuyOrderLine
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| remoteId | str | Optional | Auto-gen from buyOrderId_productId |
| buyOrderId | int | ✅ | Optiply buy order ID |
| productId | int | ✅ | Optiply product ID |
| quantity | int | ✅ | |
| subtotalValue | float | ✅ | |
| expectedDeliveryDate | datetime | Optional | |

### ReceiptLine
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| remoteId | str | Optional | |
| buyOrderLineId | str | ✅ | Optiply BOL ID |
| quantity | int | ✅ | Must be > 0 |
| occurred | datetime | ✅ | Defaults to UTC now |

## Utility Functions

### `snapshot_records(data, stream, dir, pk)`
Appends/updates records in `{stream}.snapshot.csv`. Deduplicates by `pk`, keeps latest.

### `get_snapshot(stream, dir)`
Reads `{stream}.snapshot.csv`. Returns None if doesn't exist.

### `delete_from_snapshot(items, stream, dir, pk)`
Removes matching records from snapshot CSV.

### `concat_columns(df, columns, sep='|')`
Concatenates all specified columns into one string for change detection.

### `round_to_2(value)` / `round_to_0(value)`
Safe numeric rounding with NaN/None/overflow handling. Max: 9,999,999.99

### `validate_attribute(value)`
Returns str or None. Handles NaN/null/empty.

### `nan_to_none(value)`
Converts pandas NaN to Python None for JSON serialization.

### `clean_payload(dict)`
Removes None values from Pydantic model dict for API requests.

## Auth Flow
```python
auth = OptiplyAuthenticator(api_creds, config_path, OUTPUT_DIR)
# api_creds from tenant-config.json:
#   access_token, password, account_id, webshop_uuid,
#   client_secret, client_id, username
# Auth handles token refresh automatically via _request()
```

## Config Structure
```json
// tenant-config.json (in snapshots/)
{
  "apiCredentials": {
    "access_token": "...",
    "password": "...",
    "account_id": 98,
    "webshop_uuid": "...",
    "client_secret": "...",
    "client_id": "test-shop",
    "username": "api_imports_..."
  }
}

// config.json (integration-specific settings)
{
  // Varies per integration
}
```
