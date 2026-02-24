---
tags: [integration, project, live, data]
integration: BigQuery
type: Data/SQL
auth: Service Account JSON
status: 🟢 Live
updated: 2026-02-24
---

# BigQuery Integration

> Customer writes custom SQL queries mapped to fixed query names. Same pattern for MSSQL/AWS Redshift.

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## How It Works
- Customer creates SQL queries in BigQuery with fixed names
- Each query maps to an Optiply entity
- Queries must include a replication key (updated_at) for incremental sync
- Bidirectional: also exports BOs and receipt lines TO BigQuery

## Fixed Query Names
| Query Name | Maps To |
|------------|---------|
| Products | Products |
| SalesOrders | Sell Orders |
| SalesOrdersLines | Sell Order Lines |
| Suppliers | Suppliers |
| SupplierProducts | Supplier Products |
| BuyOrders | Buy Orders |
| BuyOrdersLines | Buy Order Lines |
| ItemDeliveries | Receipt Lines |
| ProductCompositions | Product Compositions |

## Column Schema (customer must match)
All entities follow Optiply field names:
- Products: remoteId, name, skuCode, articleCode, price, unlimitedStock, stockLevel, status, eanCode, notBeingBought, created_at, updated_at (replication key), deleted_at
- Same pattern for all entities

## Key Rules
- `updated_at` required on every query as replication key
- Dates must be `%Y-%m-%dT%H:%M:%SZ`
- `stockLevel` = physical stock minus already sold (freeStock). Customer calculates this.
- Customer owns the SQL queries — we just run them

## Bidirectional
- BOs exported TO BigQuery
- Receipt lines exported TO BigQuery

## API Reference

### Base URL
Google BigQuery API (via `google.cloud.bigquery` client)

### Auth Method
Google Service Account credentials (via `credentials_path` config). Uses `google.oauth2.service_account`.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| (dynamic) | SELECT | `{project}.{dataset}.{table}` | Time-partitioned incremental |

Dynamic: discovers all datasets/tables in configured `project`. Each table becomes a stream: `{project}.{dataset}.{table}` → `dataset__table`

### Rate Limiting
- Query-based with retry loop on:
  - `TimeoutError`
  - `requests.exceptions.RequestException`
  - `urllib3.exceptions.HTTPError`
  - `SocketError`
  - `OSError`

### Error Handling
- Memory management via `gc.collect()`
- Deep conversion of datetime objects
- Handles empty DataFrames gracefully

### Quirks
- Outputs to Parquet format (not JSON)
- Dynamic batch size estimation
- UUID-based cursor for resumable incremental sync

---

## ETL Summary

**Pattern:** OLD (most similar to Generic template)

**Entities Processed:**
- Products
- ProductCompositions
- Suppliers
- SupplierProducts
- SellOrders
- SellOrderLines
- BuyOrders
- BuyOrderLines
- ReceiptLines

**Key Config Flags:**
- **None** — most similar to Generic template

**Custom Logic Highlights:**
- Uses standard Optiply stream naming: `products`, `suppliers`, etc.
- No visible custom mapping logic
- Customer writes SQL queries mapped to fixed query names

---

## Links
- Tap: [tap-bigquery](https://github.com/hotgluexyz/tap-bigquery)
- Target: [target-bigquery](https://github.com/hotgluexyz/target-bigquery.git)
- ETL: `optiply-scripts/import/bigquery/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2526511105)
