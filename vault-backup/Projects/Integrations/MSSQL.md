---
tags: [integration, project, live, data]
integration: MSSQL
type: Data/SQL
auth: Connection string (host, port, db, user, pass)
status: 🟢 Live
updated: 2026-02-24
---

# MSSQL Integration

> Same pattern as BigQuery — customer writes SQL queries mapped to fixed query names.
> See [[BigQuery]] for full schema documentation.

## Key Differences from BigQuery
- Direct SQL Server connection instead of service account
- Same fixed query names and column schema
- Same replication key pattern (updated_at)

## API Reference

### Base URL
Direct SQL Server connection (`host:port/database`)

### Auth Method
SQLAlchemy URL: `mssql+pyodbc` or `mssql+pymssql`. Supports `user`/`password` auth. Optional `TrustServerCertificate`.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| (dynamic) | SELECT | `{database}.dbo.{table}` | SQL-based with TOP/LIMIT |

Dynamic: discovers all tables in configured database. Each table becomes a stream.

### Rate Limiting
- Not applicable (direct DB connection)

### Error Handling
- SQLAlchemy error propagation
- Supports `fast_executemany` engine param

### Quirks
- Can use BCP (Bulk Copy Program) for export instead of SELECT
- Batch config support (JSONL+gzip)
- Optional HD JSON Schema types
- Configurable replication_keys per table

---

## ETL Summary

**Pattern:** OLD

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
| Flag | Default | Purpose |
|------|---------|---------|
| `pullAllOrders` | true | Pull all orders |
| `stock_location_ids` | "all" | Filter stock by location |
| `force_patch_supplier_products` | false | Force patch all SPs |
| `force_patch_products` | false | Force patch all products |

**Custom Logic Highlights:**
- Uses `Optiply-` prefixed stream names (e.g., `Optiply-Products`, `Optiply-SellOrders`)
- Special handling for 409 (conflict) responses on supplier products - fetches existing record
- Special handling for 404 on supplier product patches - reposts as new
- Tenant-specific handling: `TENANT_ID == "1318"` ignores supplier deletions
- Snapshot backup: `config_mssql_backup.json`

---

## Links
- Tap: [tap-mssql](https://github.com/hotgluexyz/tap-mssql)
- Target: [target-mssql](https://github.com/hotgluexyz/target-mssql)
- ETL: `optiply-scripts/import/mssql/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3223355393)
