---
tags: [hotglue, snapshots, sql, reference]
updated: 2026-02-24
source: https://optiply.atlassian.net/wiki/spaces/IN/pages/2369847337
status: 🚧 Work in Progress
---

# Snapshot Construction Queries for HotGlue

> SQL queries used to construct snapshot CSV files for HotGlue ETL. Work in progress.

## QLS — Supplier Products
```sql
-- QLS supplier products snapshot query
-- (Details to be added)
```

## Magento — Products
**Snapshot name:** `products.snapshot.csv`
```sql
-- Magento products snapshot
-- (Details to be added)
```

## Magento — Orders
**Snapshot name:** `orders.snapshot.csv`
```sql
-- Magento orders snapshot
-- (Details to be added)
```

## WooCommerce — Products
**Snapshot name:** `products.snapshot.csv`
```sql
-- WooCommerce products snapshot
-- (Details to be added)
```

## Notes
- Snapshots are CSV files used for change detection in the ETL pipeline
- The `concat_attributes` field concatenates all non-date columns for diff comparison
- See [[Generic ETL Template]] for how snapshots are consumed
- See [[ETL Patterns]] for the snapshot-based change detection pattern

## Links
- [[Generic ETL Template]] — template that uses these snapshots
- [[HotGlue Architecture]] — where snapshots fit in the pipeline
