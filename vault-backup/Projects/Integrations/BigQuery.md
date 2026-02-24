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

## Links
- Tap: [tap-bigquery](https://github.com/hotgluexyz/tap-bigquery)
- Target: [target-bigquery](https://github.com/hotgluexyz/target-bigquery.git)
- ETL: `optiply-scripts/import/bigquery/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2526511105)
