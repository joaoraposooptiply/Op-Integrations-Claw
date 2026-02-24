# Sherpaan ETL Deep Dive — The Gold Standard

> **Purpose:** This document provides a comprehensive, cell-by-cell breakdown of the Sherpaan ETL integration. It serves as the canonical reference for building all future Optiply ETL integrations using the Generic template approach.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Cell-by-Cell Breakdown](#2-cell-by-cell-breakdown)
   - [Setup & Imports](#setup--imports)
   - [Configuration](#configuration)
   - [Auth & Utilities](#auth--utilities)
   - [Entity Processing](#entity-processing)
3. [Entity Processing Order](#3-entity-processing-order)
4. [Generic Template Patterns](#4-generic-template-patterns)
5. [Config Flags](#5-config-flags)
6. [Snapshot Handling & Change Detection](#6-snapshot-handling--change-detection)
7. [API Interaction Patterns](#7-api-interaction-patterns)
8. [Error Handling & Edge Cases](#8-error-handling--edge-cases)
9. [What Makes It the Gold Standard](#9-what-makes-it-the-gold-standard)
10. [Differences from Old-Pattern ETLs](#10-differences-from-old-pattern-etls)

---

## 1. Architecture Overview

**Location:** `/Users/jay/Documents/Optiply/optiply-scripts/import/sherpaan/etl.ipynb`

**Entities Processed (in order):**
1. Products
2. ProductCompositions (BOMs)
3. Suppliers
4. SupplierProducts
5. SellOrders (with embedded lines)
6. BuyOrders
7. BuyOrderLines
8. ReceiptLines

**Key Files:**
- `etl.ipynb` — Main ETL notebook
- `utils/auth.py` — OAuth token management, request handling with backoff
- `utils/payloads.py` — Pydantic model → Optiply API payload conversion
- `utils/tools.py` — Snapshot management, data transformations
- `utils/models.py` — Pydantic schemas for all entities

---

## 2. Cell-by-Cell Breakdown

### SETUP & IMPORTS

#### Cell 1: Core Imports
```python
import gluestick as gs
import pandas as pd
import os
import json
from utils.auth import OptiplyAuthenticator
from utils.tools import (snapshot_records, get_snapshot, delete_from_snapshot, 
    concat_columns, handle_invalid_dates, round_to_2, round_to_0, 
    validate_attribute, convert_to_bool, round_numeric_to_2, round_numeric_to_0)
from utils.payloads import get_product_payload, get_product_compositions_payload, 
    get_supplier_payload, get_supplier_product_payload, 
    get_sell_order_withlines_payload, get_sell_order_payload, 
    get_sell_order_line_payload, get_buy_order_payload, 
    get_buy_order_line_payload, get_receipt_line_payload
from utils.actions import post_optiply, patch_optiply, delete_optiply, get_optiply
import numpy as np
import gc
```
**Purpose:** Loads all required libraries and custom utilities.

---

#### Cell 2: Directory Setup
```python
ROOT_DIR = os.environ.get("ROOT_DIR", ".")
INPUT_DIR = f"{ROOT_DIR}/sync-output/"
OUTPUT_DIR = f"{ROOT_DIR}/etl-output/"
SNAPSHOT_DIR = f"{ROOT_DIR}/snapshots/"

input_data = gs.Reader(INPUT_DIR)
optiply_base_url = os.environ.get('optiply_base_url', 'https://api.optiply.com/v1')
```
**Purpose:** Defines standard HotGlue directory structure. Reads from `sync-output/` (tap output) and writes to `etl-output/`.

---

#### Cell 3: Tenant Configuration
```python
config_path = f"{SNAPSHOT_DIR}/tenant-config.json"
with open(config_path) as f:
    config = json.load(f)
api_creds = config["apiCredentials"]
auth = OptiplyAuthenticator(api_creds, config_path, OUTPUT_DIR)
```
**Purpose:** Loads tenant-specific API credentials and initializes the authenticator.

---

### CONFIGURATION

#### Cell 4: Config Flags (Check Config Flags)
```python
config_path = "./config.json"
with open(config_path) as f:
    config = json.load(f)

pullAllOrders = config.get("pullAllOrders", True)
warehouse_group_code = config.get("warehouse_group_code", None)
not_sync_suppliers_attributes = config.get("not_sync_suppliers_attributes", None)
not_sync_supProds_attributes = config.get("not_sync_supProds_attributes", None)
stock_warehouse_codes = config.get("stock_warehouse_codes", None)
sellOrders_warehouse_codes = config.get("sellOrders_warehouse_codes", None)
buyOrders_warehouse_codes = config.get("buyOrders_warehouse_codes", None)
```
**Purpose:** Reads customer-specific configuration flags. These control filtering and behavior.

---

#### Cell 5: Force Patch Flags (Job State)
```python
job_state_path = os.path.join(ROOT_DIR, "state.json")
if os.path.exists(job_state_path):
    job_state = read_json_file(job_state_path)
    force_patch_supplier_products = job_state.get("force_patch_supplier_products", False)
    force_patch_products = job_state.get("force_patch_products", False)
```
**Purpose:** Reads job state to allow forcing patches on all records (useful for recovery scenarios).

---

#### Cell 6: Force Patch Application
```python
if force_patch_supplier_products:
    supplier_products_snapshot = get_snapshot("supplier_products", SNAPSHOT_DIR)
    supplier_products_snapshot["concat_attributes"] = "ForcePATCH"
    supplier_products_snapshot.to_csv(f"{SNAPSHOT_DIR}/supplier_products.snapshot.csv", index=False)
```
**Purpose:** Overrides snapshot `concat_attributes` to force PATCH on all records.

---

#### Cell 7: Payload Function Router
```python
def get_payload_function(row, entity):
    if entity == "suppliers":
        return get_supplier_payload(row)
    elif entity == "products":
        return get_product_payload(row)
    elif entity == "productCompositions":
        return get_product_compositions_payload(row)
    elif entity == "supplierProducts":
        return get_supplier_product_payload(row)
    elif entity == "sellOrders":
        return get_sell_order_withlines_payload(row)
    elif entity == "buyOrders":
        return get_buy_order_payload(row)
    elif entity == "buyOrderLines":
        return get_buy_order_line_payload(row)
    elif entity == "receiptLines":
        return get_receipt_line_payload(row)
    else:
        raise ValueError("Invalid entity type")
```
**Purpose:** Central dispatcher that maps entity names to payload builder functions.

---

### ENTITY PROCESSING

Each entity follows the same repeatable pattern:

1. **Load Input Data** — Read from tap output using `input_data.get()`
2. **Custom Mapping** — Transform source columns to internal schema
3. **Global Mapping** — Standardize column names, apply transformations
4. **Snapshot Merge** — Join with snapshot to get `optiply_id` and existing values
5. **Diff Logic** — Determine new/update/delete based on `concat_attributes`
6. **API Calls** — POST/PATCH/DELETE to Optiply
7. **Snapshot Update** — Persist successful records

#### PRODUCTS (Example — Full Pattern)

**Cell: Extract EAN**
```python
def extract_ean(cell_value):
    """Safely parses JSON and handles cases where the target item is EITHER a dict OR a list of dicts."""
    if pd.isna(cell_value):
        return np.nan
    try:
        data = json.loads(cell_value)
        ean_codes_obj = data.get('EanCodes', {})
        if not ean_codes_obj:
            return np.nan
        item_info = ean_codes_obj.get('EanCodeItemInformationItem')
        if isinstance(item_info, dict):
            return item_info.get('EanCode')
        elif isinstance(item_info, list):
            if len(item_info) > 0 and isinstance(item_info[0], dict):
                return item_info[0].get('EanCode')
        return np.nan
    except (json.JSONDecodeError, TypeError):
        return np.nan
```
**Purpose:** Parses nested JSON structure for EAN codes (Sherpaan-specific).

---

**Cell: Load Products**
```python
incoming_products = input_data.get("changed_items_information", usecols=[...], dtype="object")
incoming_products = incoming_products[incoming_products["ItemType"].isin(["Stock", "Assembly"])]
incoming_products["assembled"] = (incoming_products["ItemType"] == "Assembly")
incoming_products = incoming_products.rename(columns={...})
incoming_products["remoteId"] = incoming_products["skuCode"]
incoming_products["eanCode"] = incoming_products['eanCode'].apply(extract_ean)
incoming_products["status"] = "enabled"
incoming_products.loc[incoming_products["ItemStatus"] != "Active", "status"] = "disabled"
```
**Purpose:** Custom mapping: filters for Stock/Assembly items, sets `assembled` flag, renames columns.

---

**Cell: Load Stocks**
```python
if warehouse_group_code is not None:
    incoming_stocks = input_data.get("changed_stock_by_warehouse_group_code", ...)
    incoming_stocks = incoming_stocks.sort_values(by="Token", ascending=False)
    incoming_stocks = incoming_stocks.drop_duplicates(subset=["ItemCode"], keep="first")
    incoming_stocks["WarehouseCode"] = "WarehouseGroupCode_" + warehouse_group_code
else:
    incoming_stocks = input_data.get("changed_stock", ...)

incoming_stocks["concat_id"] = incoming_stocks["ItemCode"] + "_" + incoming_stocks["WarehouseCode"]
snapshot_records(incoming_stocks, "changed_stock", SNAPSHOT_DIR, pk="concat_id")
```
**Purpose:** Handles both warehouse-group-specific and general stock data.

---

**Cell: Merge Products + Stocks**
```python
incoming_itemIDs = pd.concat([incoming_products_ids, incoming_stocks_ids], ...).drop_duplicates()
incoming_data = incoming_itemIDs.merge(incoming_products, on='remoteId', how='left')
incoming_data = incoming_data.merge(incoming_stocks, on='remoteId', how='left')
```
**Purpose:** Combines product and stock data into unified input.

---

**Cell: Snapshot Merge (Historical Values)**
```python
products_snapshot = get_snapshot("products", SNAPSHOT_DIR)
if incoming_data is not None and products_snapshot is not None:
    products = incoming_data.merge(products_snapshot, on='remoteId', how='left', suffixes=('', '_snap'))
    # Fill missing incoming values from snapshot
    for column in non_id_columns:
        mask = products[column].isna() | products[column].eq('')
        products.loc[mask, column] = products.loc[mask, column + '_snap']
    products.drop(columns=columns_to_drop, inplace=True)
```
**Purpose:** Pulls historical values from snapshot to fill gaps (e.g., if stock level not in current sync).

---

**Cell: Global Mapping (Standardized Transformations)**
```python
products.columns = products.columns.str.lower()
products.rename(columns={"remote_id": "remoteId"}, inplace=True)
products["remoteId"] = products["remoteId"].astype(str)
products["name"] = products["name"].str.replace("\r", "").str[:255]
products["stockLevel"] = products["stockLevel"].apply(round_to_0)
products["price"] = products["price"].apply(round_numeric_to_2).clip(lower=0)
products["skuCode"] = products["skuCode"].apply(validate_attribute)
products["eanCode"] = products["eanCode"].apply(validate_attribute)
products["assembled"] = products["assembled"].astype(str).str.lower().map({'true': True, 'false': False, ...})
products = products[products["name"].notna()]
products = products.drop_duplicates(subset=["remoteId"])
products["concat_attributes"] = concat_columns(products, concat_fields)
```
**Purpose:** Applies universal transformations: lowercase columns, validate EAN/SKU, round prices/stock, create change-detection hash.

---

**Cell: New/Update/Delete Split**
```python
products_snapshot = get_snapshot("products", SNAPSHOT_DIR)
if products_snapshot is not None:
    new_products = products[~products["remoteId"].isin(products_snapshot["remoteId"])]
    update_products = products[products["remoteId"].isin(products_snapshot["remoteId"])]
    update_products = update_products.merge(products_snapshot[["remoteId", "optiply_id", "concat_attributes"]], on="remoteId", ...)
    delete_products = update_products[~update_products["deleted_at"].isnull() & (update_products["deleted_at"] != "")]
    update_products = update_products[update_products["concat_attributes"] != update_products["concat_attributes_snap"]]
```
**Purpose:** Determines which records are new, updated, or deleted by comparing to snapshot.

---

**Cell: API Requests (DELETE → POST → PATCH)**
```python
# DELETE
if delete_records is not None:
    for i, row in delete_records.iterrows():
        response = delete_optiply(api_creds, auth, int(row['optiply_id']), entity=entity)
        if response.status_code == 404:
            print(f"Record already deleted, skipping.")
            continue
        if not response.ok:
            raise Exception(...)
    delete_from_snapshot(delete_records, snapshot_name, SNAPSHOT_DIR, pk="remoteId")

# POST
if new_records is not None:
    for i, row in new_records_.iterrows():
        payload = get_payload_function(row, entity)
        response = post_optiply(api_creds, auth, payload, entity=entity)
        new_records_.loc[i, "optiply_id"] = str(response.json()["data"]["id"])
    new_records_ = new_records_[~new_records_["optiply_id"].isna()]
    snapshot_records(new_records_, snapshot_name, SNAPSHOT_DIR, pk="remoteId")

# PATCH
if update_records is not None:
    for i, row in update_records.iterrows():
        payload = get_payload_function(row, entity)
        response = patch_optiply(api_creds, auth, payload, int(row['optiply_id']), entity=entity)
        update_records.loc[i, "response_code"] = response.status_code
    update_records = update_records[update_records["response_code"] == 200]
    snapshot_records(update_records, snapshot_name, SNAPSHOT_DIR, pk="remoteId")
```
**Purpose:** Executes API calls in order: DELETE first (to handle dependency issues), then POST, then PATCH.

---

### PRODUCT COMPOSITIONS

**Cell: Parse BOM JSON**
```python
def parse_json_to_list(x):
    if pd.isna(x) or x == "":
        return []
    parsed = json.loads(x) if isinstance(x, str) else x
    inner_data = parsed.get("ItemAssemblies", {}).get("ItemAssembly", [])
    if isinstance(inner_data, dict):
        return [inner_data]
    elif isinstance(inner_data, list):
        return inner_data
    return []
```
**Purpose:** Flattens nested BOM JSON into a list of components.

---

**Cell: Explode and Normalize**
```python
product_compositions["ItemAssemblies"] = product_compositions["ItemAssemblies"].apply(parse_json_to_list)
product_compositions = product_compositions.explode("ItemAssemblies", ignore_index=True)
product_compositions = product_compositions[product_compositions["ItemAssemblies"].notna()]
purchase_line_df = pd.json_normalize(product_compositions["ItemAssemblies"])
product_compositions = pd.concat([product_compositions.drop(columns=["ItemAssemblies"]), purchase_line_df], axis=1)
product_compositions["remoteId"] = product_compositions["composedProductId"] + "_" + product_compositions["partProductId"]
```
**Purpose:** Explodes one-to-many BOM relationships into individual rows.

---

**Cell: Link Parent/Child to Optiply IDs**
```python
# Link composedProductId to parent optiply_id
product_compositions = product_compositions.merge(
    products_snapshot[["Remote_composedProductId", "optiply_id"]],
    how="inner", on="Remote_composedProductId"
)
product_compositions = product_compositions.rename(columns={"optiply_id": "composedProductId"})

# Link partProductId to child optiply_id
product_compositions = product_compositions.merge(
    products_snapshot[["Remote_partProductId", "optiply_id"]],
    how="inner", on="Remote_partProductId"
)
product_compositions = product_compositions.rename(columns={"optiply_id": "partProductId"})
```
**Purpose:** Converts remote IDs to Optiply internal IDs for parent/child relationships.

---

### SUPPLIERS

**Cell: Custom Mapping**
```python
suppliers = input_data.get("supplier_info", ...)
suppliers = suppliers.drop_duplicates(subset=["SupplierCode"])
suppliers["name"] = suppliers["Company"] + " " + suppliers["supplier_name"]
suppliers = suppliers.rename(columns={"SupplierCode": "remoteId", "OrderPeriod": "userReplenishmentPeriod", ...})
if not_sync_suppliers_attributes is not None:
    suppliers = suppliers.drop(columns=not_sync_suppliers_attributes, errors="ignore")
```
**Purpose:** Concatenates Company + Name, filters out customer-specified attributes.

---

**Cell: Global Mapping (with email cleanup)**
```python
suppliers["emails"] = suppliers["emails"].str.replace("[", "").str.replace("]", "").str.replace("'", "").str.replace('"', "").str.replace(" ", "")
```
**Purpose:** Strips list formatting from email strings.

---

### SUPPLIER PRODUCTS

**Cell: Custom Mapping**
```python
supplier_products["remoteId"] = supplier_products["ItemCode"] + "_" + supplier_products["SupplierCode"]
supplier_products["status"] = supplier_products["SupplierItemStatus"].str.contains("Active").map({True: "enabled", False: "disabled"})
```
**Purpose:** Creates composite remoteId and derives status from supplier item status.

---

**Cell: Merge with Product/Supplier Snapshots**
```python
supplier_products = supplier_products.merge(suppliers_snapshot[["Remote_supplierId", "optiply_id"]], on="Remote_supplierId", how="inner")
supplier_products = supplier_products.rename(columns={"optiply_id": "supplierId"})
supplier_products = supplier_products.merge(products_snapshot[["Remote_productId", "optiply_id"]], on="Remote_productId", how="inner")
supplier_products = supplier_products.rename(columns={"optiply_id": "productId"})
```
**Purpose:** Resolves both supplier and product to Optiply internal IDs.

---

**Cell: Handle deliveryTime=0 as null**
```python
supplier_products["deliveryTime"] = pd.to_numeric(supplier_products["deliveryTime"], errors="coerce")
supplier_products["deliveryTime"] = supplier_products["deliveryTime"].fillna(0).astype(int)
supplier_products1 = supplier_products[supplier_products["deliveryTime"] > 1].copy()
supplier_products = supplier_products[supplier_products["deliveryTime"].isna() | (supplier_products["deliveryTime"] <= 1)]
supplier_products["deliveryTime"] = None
supplier_products = pd.concat([supplier_products, supplier_products1], ignore_index=True)
```
**Purpose:** Treats delivery time of 0 or 1 as "not configured" (null).

---

### SELL ORDERS

**Cell: Custom Mapping**
```python
sell_orders = input_data.get("changed_orders_information", ...)
sell_orders = sell_orders.rename(columns={"OrderNumber": "remoteId", "OrderDate": "placed", "OrderAmountInclVAT": "totalValue"})
sell_orders.loc[sell_orders["OrderStatus"] == "Cancelled", "deleted_at"] = pd.Timestamp.now().strftime("%Y-%m-%d %H:%M:%S")
```
**Purpose:** Maps order fields, sets deleted_at for cancelled orders.

---

**Cell: Chunked Order Line Processing**
```python
def process_chunk(chunk, columns_to_keep):
    chunk['parsed'] = chunk['OrderLines'].apply(parse_json_column)
    exploded = chunk.explode('parsed').dropna(subset=['parsed'])
    lines_df = pd.DataFrame(exploded['parsed'].tolist(), index=exploded.index)
    result = pd.concat([exploded[['OrderNumber']], lines_df], axis=1)
    if 'QuantityOrdered' in result.columns:
        result['QuantityOrdered'] = pd.to_numeric(result['QuantityOrdered'], errors='coerce')
    return result

sol_sync_data = input_data.get("changed_orders_information", usecols=[...], dtype="object", chunksize=200000)
for i, chunk in enumerate(sol_sync_data):
    processed_slice = process_chunk(chunk, target_columns)
    chunk_list.append(processed_slice)
    del chunk
    gc.collect()
sell_order_lines = pd.concat(chunk_list, ignore_index=True)
```
**Purpose:** Memory-efficient processing of large order files using chunking + garbage collection.

---

**Cell: Group Lines into Orders**
```python
order_lines_grouped = sell_order_lines.groupby('Remote_sellOrderId').apply(
    lambda x: x[['quantity', 'subtotalValue', 'productId']].to_dict('records')
)
new_sell_orders = new_sell_orders.merge(order_lines_grouped, left_on='remoteId', right_on='Remote_sellOrderId', how='left')
```
**Purpose:** Nests order lines inside the parent order for the `get_sell_order_withlines_payload`.

---

### BUY ORDERS

**Cell: Complex Line Parsing**
```python
def parse_json_to_list(x):
    if pd.isna(x) or x == "" or x == "nan":
        return []
    if isinstance(x, list):
        return x
    parsed = ast.literal_eval(x) if isinstance(x, str) else x
    if isinstance(parsed, dict):
        return [parsed]
    return parsed if isinstance(parsed, list) else []

buy_orders["PurchaseLines"] = buy_orders["PurchaseLines"].apply(parse_json_to_list)
buy_orders = buy_orders.explode("PurchaseLines", ignore_index=True)
buy_orders = buy_orders[buy_orders["PurchaseLines"].notna()]
purchase_line_df = pd.json_normalize(buy_orders["PurchaseLines"])
buy_orders = pd.concat([buy_orders.drop(columns=["PurchaseLines"]), purchase_line_df], axis=1)
```
**Purpose:** Handles both JSON string and list formats, explodes into line items.

---

**Cell: Calculate Order Completion**
```python
buy_orders["totalValue"] = buy_orders.groupby("PurchaseOrderNumber")["Amount"].transform("sum")
buy_orders["totalQuantityOrdered"] = buy_orders.groupby("PurchaseOrderNumber")["QuantityOrdered"].transform("sum")
buy_orders["totalQuantityReceived"] = buy_orders.groupby("PurchaseOrderNumber")["QuantityReceived"].transform("sum")
completed_mask = buy_orders['totalQuantityOrdered'] == buy_orders['totalQuantityReceived']
latest_completed = buy_orders.loc[completed_mask].groupby('PurchaseOrderNumber')['ReceivedDate'].max()
buy_orders['completed'] = buy_orders['PurchaseOrderNumber'].map(latest_completed)
```
**Purpose:** Sets `completed` date when order is fully received.

---

**Cell: Handle Optiply-Exported BuyOrders**
```python
export_bo_snapshot_name = f"{export_bo_stream_name}_nfeL_OU1k"
optiply_buy_orders = get_snapshot(export_bo_snapshot_name, SNAPSHOT_DIR)
if optiply_buy_orders is not None:
    # Mark as PATCH to sync status
    buy_orders_to_snapshot["concat_attributes"] = "PATCH_remoteId"
    buy_orders_to_snapshot["completed"] = None
    snapshot_records(buy_orders_to_snapshot, "buy_orders", SNAPSHOT_DIR, pk="remoteId")
```
**Purpose:** Handles buy orders originally created in Optiply (exported) and now being re-imported.

---

### BUY ORDER LINES

**Cell: Extract from Processed BuyOrders**
```python
buy_order_lines = buy_orders[["PurchaseOrderNumber", "ItemCode", "QuantityOrdered", "QuantityReceived", "Amount", "DateExpected"]]
buy_order_lines["remoteId"] = buy_order_lines["PurchaseOrderNumber"] + "_" + buy_order_lines["ItemCode"].astype(str)
buy_order_lines = buy_order_lines.rename(columns={...})
```
**Purpose:** Derived from exploded buy orders data.

---

**Cell: Cross-Order Move Detection**
```python
changed_buyorder = update_buy_order_lines[update_buy_order_lines["buyOrderId"] != update_buy_order_lines["buyOrderId_snap"]]
delete_buy_order_lines = pd.concat([delete_buy_order_lines, changed_buyorder], ignore_index=True)
new_buy_order_lines = pd.concat([new_buy_order_lines, changed_buyorder], ignore_index=True)
```
**Purpose:** If a line's parent order changes, treat as delete + create (not update).

---

### RECEIPT LINES

**Cell: Filter to Received Quantities**
```python
receipt_lines = receipt_lines[receipt_lines["ReceivedDate"].notna()]
receipt_lines["quantity"] = receipt_lines["QuantityReceived"]
receipt_lines["occurred"] = receipt_lines["ReceivedDate"]
receipt_lines["remoteId"] = receipt_lines["PurchaseOrderNumber"] + "_" + receipt_lines["ItemCode"].astype(str)
```
**Purpose:** Creates receipt lines only for received quantities.

---

## 3. Entity Processing Order

| Step | Entity | Notes |
|------|--------|-------|
| 1 | Products | Core master data |
| 2 | ProductCompositions | Depends on Products snapshot |
| 3 | Suppliers | Master data |
| 4 | SupplierProducts | Depends on Products + Suppliers |
| 5 | SellOrders | With embedded lines |
| 6 | BuyOrders | Separate from lines |
| 7 | BuyOrderLines | Depends on BuyOrders |
| 8 | ReceiptLines | Depends on BuyOrderLines |

**Dependency Chain:**
- ProductCompositions → needs Products `optiply_id`
- SupplierProducts → needs Products + Suppliers `optiply_id`
- SellOrders → embedded lines, no separate lookup
- BuyOrderLines → needs BuyOrders + Products `optiply_id`
- ReceiptLines → needs BuyOrderLines `optiply_id`

---

## 4. Generic Template Patterns

### utils.payloads
Each entity has a dedicated function:
- `get_product_payload(row)` — returns dict validated by Pydantic
- `get_supplier_payload(row)`
- `get_supplier_product_payload(row)`
- `get_sell_order_withlines_payload(row)` — includes nested `orderLines`
- `get_buy_order_payload(row)`
- `get_buy_order_line_payload(row)`
- `get_receipt_line_payload(row)`

All use:
```python
model = EntityModel(**data_dict)
payload = clean_payload(model.dict())
return payload
```

### utils.actions
Centralized API calls:
```python
post_optiply(api_creds, auth, payload, entity)  # → POST /{entity}
patch_optiply(api_creds, auth, payload, optiply_id, entity)  # → PATCH /{entity}/{id}
delete_optiply(api_creds, auth, optiply_id, entity)  # → DELETE /{entity}/{id}
get_optiply(api_creds, auth, url)  # → GET /{url}
```

All wrap `auth._request()` which handles:
- OAuth token refresh
- Backoff on failure
- Error handling

### utils.tools
| Function | Purpose |
|----------|---------|
| `get_snapshot()` | Load snapshot CSV |
| `snapshot_records()` | Merge + save snapshot |
| `delete_from_snapshot()` | Remove deleted records |
| `concat_columns()` | Create change-detection hash |
| `round_to_2()` | Round prices to 2 decimals |
| `round_to_0()` | Round quantities to integers |
| `validate_attribute()` | Strip null/empty EAN/SKU |
| `nan_to_none()` | Convert pandas NaN to Python None |

---

## 5. Config Flags

| Flag | Type | Default | Purpose |
|------|------|---------|---------|
| `pullAllOrders` | bool | `True` | Pull all sell orders or only processed |
| `warehouse_group_code` | string | `None` | Filter stock by warehouse group |
| `not_sync_suppliers_attributes` | string | `None` | CSV list of supplier fields to skip |
| `not_sync_supProds_attributes` | string | `None` | CSV list of supplier product fields to skip |
| `stock_warehouse_codes` | string | `"all"` | Filter stock by warehouse codes |
| `sellOrders_warehouse_codes` | string | `"all"` | Filter sell orders by warehouse |
| `buyOrders_warehouse_codes` | string | `"all"` | Filter buy orders by warehouse |
| `force_patch_supplier_products` | bool | `False` | Force PATCH on all supplier products |
| `force_patch_products` | bool | `False` | Force PATCH on all products |

---

## 6. Snapshot Handling & Change Detection

### Snapshot Structure
Each entity has a `.snapshot.csv` file containing:
- `remoteId` — Source system ID
- `optiply_id` — Optiply internal ID
- `concat_attributes` — Hash of all attribute values
- Entity-specific fields

### Change Detection Algorithm
```python
# 1. Compute hash of current record
current_hash = concat_columns(row, non_date_columns)

# 2. Compare with snapshot hash
if remoteId not in snapshot:
    → NEW → POST
elif current_hash != snapshot_hash:
    → UPDATE → PATCH
elif deleted_at is set:
    → DELETE → DELETE
```

### Snapshot Update Patterns
```python
# POST: Add new record + optiply_id
snapshot_records(new_records_, snapshot_name, SNAPSHOT_DIR, pk="remoteId")

# PATCH: Update existing record
snapshot_records(update_records, snapshot_name, SNAPSHOT_DIR, pk="remoteId")

# DELETE: Remove from snapshot
delete_from_snapshot(delete_records, snapshot_name, SNAPSHOT_DIR, pk="remoteId")
```

---

## 7. API Interaction Patterns

### URL Construction
```python
url = f"{optiply_base_url}/{entity}?accountId={api_creds['account_id']}&couplingId={api_creds['couplingId']}"
```

### Payload Wrapper
```python
payload = json.dumps({
    "data": {
        "type": entity,
        "attributes": payload_dict
    }
})
```

### Response Handling
```python
# POST: Extract new ID
new_records_.loc[i, "optiply_id"] = str(response.json()["data"]["id"])

# PATCH: Track status code
update_records.loc[i, "response_code"] = response.status_code
update_records = update_records[update_records["response_code"] == 200]

# DELETE: Handle 404 as success
if response.status_code == 404:
    print("Already deleted, continuing")
```

---

## 8. Error Handling & Edge Cases

### Auth Retry (utils/auth.py)
```python
@backoff.on_exception(backoff.constant, Exception, max_tries=10, interval=20)
def _request(self, method, **kwargs):
    # Handles 401 → token refresh → retry
    if response.status_code == 401:
        self.get_access()  # Refresh token
        # Retry with new token (automatic via backoff)
```

### Specific Error Handling

**Supplier email invalid (400):**
```python
if entity == "suppliers" and response.status_code == 400 and "not a valid address" in response.text.lower():
    payload.pop("emails")  # Remove and retry
    response = post_optiply(api_creds, auth, payload, entity=entity)
```

**SupplierProduct 409 (already exists):**
```python
if entity == "supplierProducts" and response.status_code == 409:
    # Query existing record
    url = f"{optiply_base_url}/supplierProducts?filter[supplierId]={...}&filter[productId]={...}"
    response = get_optiply(api_creds, auth, url)
    new_records_.loc[i, "optiply_id"] = str(response.json()["data"][0]["id"])
```

**SupplierProduct 404 on PATCH (deleted in Optiply):**
```python
if entity == "supplierProducts" and response.status_code == 404:
    # Re-POST as new
    response = post_optiply(api_creds, auth, payload, entity=entity)
```

### Ignored Status Codes
```python
if response.status_code not in [200, 201, 204, 409]:
    if not (response.status_code == 400 and "is not a valid address" in response.text):
        if not (response.status_code == 404 and method == 'DELETE'):
            if not (response.status_code == 404 and method == 'POST' and 'receiptLines' in url):
                if not (response.status_code == 404 and method == 'PATCH' and 'supplierProducts' in url):
                    raise Exception(response.text)
```

---

## 9. What Makes It the Gold Standard

### ✅ Complete Patterns
1. **Uniform entity processing** — Every entity follows identical NEW/UPDATE/DELETE pattern
2. **Separation of concerns** — Custom mapping → Global mapping → Snapshot merge → API calls
3. **Robust error handling** — Specific handlers for known API edge cases
4. **Memory efficiency** — Chunked processing for large files + `gc.collect()`
5. **Atomic snapshots** — Only successful API calls persist to snapshot

### ✅ Change Detection
- `concat_attributes` provides deterministic change detection
- Handles partial updates (incoming data merged with snapshot)
- Force-patch flags for disaster recovery

### ✅ Relationship Management
- Proper ID resolution (remoteId → optiply_id) before API calls
- Cross-entity validation (only sync SP if both supplier + product exist)
- Order line embedding (SellOrders with lines as nested array)

### ✅ Production Ready
- Backoff on API failures
- Token refresh automation
- 404 handling (already deleted = success)
- Config-driven behavior (no hardcoded values)

---

## 10. Differences from Old-Pattern ETLs

| Aspect | Old Pattern | Gold Standard (Generic) |
|--------|-------------|-------------------------|
| **Payload Construction** | Inline dict building | `utils.payloads` functions with Pydantic validation |
| **API Calls** | Scattered `requests.post()` calls | Centralized in `utils.actions` |
| **Snapshot Logic** | Custom per-entity | Generic `get_snapshot()`, `snapshot_records()`, `concat_columns()` |
| **Change Detection** | Field-by-field comparison | Hash-based (`concat_attributes`) |
| **Error Handling** | Try/catch per call | Centralized in `auth._request()` + entity-specific handlers |
| **Configuration** | Hardcoded values | Config JSON flags |
| **Memory Management** | Load all data | Chunked processing + garbage collection |
| **Order Lines** | Separate API calls | Nested in parent payload (`sellOrderWithLines`) |
| **Testing** | N/A | `FakeResponse` class for test mode |

### Key Innovations in Generic Template

1. **Pydantic Models** (`utils/models.py`) — Type-safe payload validation before API calls
2. **Payload Cleaners** (`utils/utils.py`) — Remove None values, format for Optiply API
3. **Backoff Decorator** — Automatic retry on transient failures
4. **Test Mode** — `hotglue_test` flag enables mock responses without API calls
5. **Cross-Entity ID Resolution** — Merges snapshots to convert remote IDs to Optiply IDs

---

## Quick Reference: Building a New ETL

1. **Add payload function** to `utils/payloads.py` using Pydantic model
2. **Add entry** to `get_payload_function()` dispatcher in ETL
3. **Follow the pattern:**
   ```
   Load Input → Custom Map → Global Map → Snapshot Merge → Diff → API → Snapshot Update
   ```
4. **Use `concat_columns()`** for change detection
5. **Handle 404/409** in API calls for your entity
6. **Test with** `hotglue_test=True` in tenant config

---

*Document generated from Sherpaan ETL analysis. Last updated: 2026-02-24*
