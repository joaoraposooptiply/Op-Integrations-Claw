---
tags: [standards, schema, bigquery, aws, azure, reference]
updated: 2026-02-24
source: https://optiply.atlassian.net/wiki/spaces/IN/pages/2509439012
---

# Schema for Cloud Systems (BigQuery, AWS, Azure)

> Standard schema sent to customers who use a cloud system as their source of truth. They format their data to this schema so we can integrate easily.

## Products
**Required:** ProductID (STRING), ArticleCode (STRING), Name (STRING), SKU (STRING), Price (FLOAT64), Status (STRING), StockLevel (INT64), UnlimitedStock (BOOLEAN)

## Suppliers
**Required:** SupplierID (STRING), Name (STRING)
**Optional:** Email (STRING), ContainerType (STRING), ContainerVolume (FLOAT64), ContainerWeight (FLOAT64)

## Supplier Products
**Required:** SupplierProductID (STRING), ProductID (STRING), SupplierID (STRING)
**Optional:** MOQ (INT64), LotSize (INT64)

## Sell Orders
**Required:** SellOrderID (STRING), ProductID (STRING), Quantity (INT64), SubtotalValue (FLOAT64), Timestamp (TIMESTAMP)

## Sell Order Lines
**Required:** SellOrderID (STRING), ProductID (STRING), Quantity (INT64), PricePerUnit (FLOAT64)
**Optional:** DiscountRate (FLOAT64)

## Buy Orders
**Required:** BuyOrderID (STRING), Placed (TIMESTAMP)
**Optional:** Completed (TIMESTAMP, nullable), TotalValue (FLOAT64)

## Buy Order Lines
**Required:** BuyOrderID (STRING), ProductID (STRING), Quantity (INT64), PricePerUnit (FLOAT64)
**Optional:** ExpectedDeliveryDate (DATE)

## Receipt Lines
**Required:** ReceiptLineID (STRING), ProductID (STRING), Quantity (INT64), Occurred (TIMESTAMP)

## Product Compositions
**Required:** ParentProductID (STRING), ComponentProductID (STRING), Quantity (INT64)

## Promotions
**Required:** PromotionID (STRING), Description (STRING), StartDate (DATE), EndDate (DATE)
**Optional:** Active (BOOLEAN)

## Promotion Products
**Required:** PromotionID (STRING), ProductID (STRING), DiscountRate (FLOAT64)

## Notes
- This schema is for Google BigQuery primarily but applies to AWS Redshift and Azure too
- Customers provide data in this format; we ingest via [[BigQuery]] tap or similar
- Maps 1:1 to [[Generic Data Mapping]] with cloud-native types

## Links
- [[Generic Data Mapping]] — canonical field-level mapping
- [[BigQuery]] — BigQuery integration doc
- [[MSSQL]] — MSSQL integration doc
