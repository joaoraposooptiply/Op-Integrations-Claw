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

## Links
- Tap: [tap-mssql](https://github.com/hotgluexyz/tap-mssql)
- Target: [target-mssql](https://github.com/hotgluexyz/target-mssql)
- ETL: `optiply-scripts/import/mssql/etl.ipynb`
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/3223355393)
