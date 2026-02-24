---
tags: [standards, mapping, reference]
updated: 2026-02-24
source: https://optiply.atlassian.net/wiki/spaces/IN/pages/3474980865
---

# Generic Data Mapping

> Master schema for all integrations. Every integration maps its remote entities to these Optiply schemas.

## Products
**File name:** `products.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | ID in remote system |
| name | string (max 255) | ✅ | |
| skuCode | string (max 255) | | SKU your company uses |
| articleCode | string (max 255) | | Non-SKU, non-EAN article code |
| price | decimal (max 9 int digits, 2 decimals) | | |
| unlimitedStock | boolean | ✅ | TRUE = disable stock tracking |
| stockLevel | integer (can be negative) | ✅ | Physical stock minus already sold. Often called freeStock. |
| status | enum | | `enabled` or `disabled` |
| eanCode | string | | Barcode / EAN |
| notBeingBought | boolean | | TRUE → advice will be 0 |
| created_at | datetime (%Y-%m-%dT%H:%M:%SZ) | | |
| updated_at | datetime (%Y-%m-%dT%H:%M:%SZ) | ✅ | Replication key |
| deleted_at | datetime (%Y-%m-%dT%H:%M:%SZ) | | |

## Suppliers
**File name:** `suppliers.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| name | string (max 255) | ✅ | |
| emails | string[] | | `["a@b.com"]` or `["a@b.com";"c@d.com"]` |
| deliveryTime | integer | | Days |
| created_at | datetime | | |
| updated_at | datetime | ✅ | Replication key |
| deleted_at | datetime | | |

## Supplier Products
**File name:** `supplier_products.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| name | string (max 255) | ✅ | |
| skuCode | string (max 255) | | |
| eanCode | string (max 255) | | |
| articleCode | string (max 255) | | |
| price | decimal | | Purchase price |
| minimumPurchaseQuantity | integer | | MOQ, default 1, must be ≥ 1 |
| lotSize | integer | | e.g. sixpack = 6, default 1, must be ≥ 1 |
| productId | long | ✅ | remoteId from Products |
| supplierId | long | ✅ | remoteId from Suppliers |
| preferred | boolean | | One per product |
| status | enum | | `enabled`/`disabled` — use to mimic deletes |
| deliveryTime | integer | | Lead time in days per supplier product |
| created_at | datetime | | |
| updated_at | datetime | ✅ | Replication key |
| deleted_at | datetime | | |

## Sell Orders
**File name:** `sell_orders.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| placed | datetime | ✅ | Date order was placed |
| totalValue | decimal (max 17 int digits, 2 decimals) | ✅ | |
| updated_at | datetime | ✅ | Replication key |
| deleted_at | datetime | | |

## Sell Order Lines
**File name:** `sell_order_lines.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| quantity | integer | ✅ | |
| productId | long | ✅ | remoteId from Products |
| sellOrderId | long | ✅ | remoteId from Sell Orders |
| subtotalValue | decimal (max 17 int digits, 2 decimals) | ✅ | |
| deleted_at | datetime | | |
| updated_at | datetime | ✅ | Replication key |

## Buy Orders
**File name:** `buy_orders.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| completed | datetime | | Fill when no products left to receive — closes the order |
| placed | datetime | ✅ | Date BO was placed |
| totalValue | decimal (max 17 int digits, 2 decimals) | ✅ | |
| updated_at | datetime | ✅ | Replication key |
| deleted_at | datetime | | |
| reference | integer | | BuyOrders.id — only for BOs synced FROM Optiply TO remote |
| supplierId | long | ✅ | remoteId from Suppliers |

## Buy Order Lines
**File name:** `buy_order_lines.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| quantity | integer | ✅ | |
| productId | long | ✅ | remoteId from Products |
| BuyOrderId | long | ✅ | remoteId from Buy Orders |
| subtotalValue | decimal (max 17 int digits, 2 decimals) | ✅ | |
| created_at | datetime | | |
| updated_at | datetime | ✅ | Replication key |
| deleted_at | datetime | | |
| reference | integer | | BuyOrders.line_items.line_id — only for BOs from Optiply |

## Receipt Lines
**File name:** `receipt_lines.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| quantity | integer | ✅ | |
| buyOrderLineId | integer | ✅ | ID of the BuyOrderLine that owns this ReceiptLine |
| occurred | datetime | ✅ | When receipt happened |
| deleted_at | datetime | | |
| updated_at | datetime | ✅ | Replication key |
| reference | integer | | ReceiptLines.id — only for ReceiptLines from Optiply |

## Product Compositions
**File name:** `product_compositions.csv`

| Optiply Field | Type | Required | Notes |
|---------------|------|----------|-------|
| remoteId | string | ✅ | |
| composedProductId | long | ✅ | Parent product |
| partProductId | long | ✅ | Component product |
| partQuantity | integer | ✅ | Must be ≥ 1 |
| created_at | datetime | | |
| updated_at | datetime | ✅ | Replication key |
| deleted_at | datetime | | |

## Key Rules
- **Prices** are always **excluding VAT**
- **Stock level** = physical stock minus already sold (freeStock)
- **Deletes** are soft: set `status = disabled` or use `deleted_at`
- **updated_at** is the replication key for all entities
- **remoteId** is the foreign system's ID — kept for mapping
- **reference** fields are only for bidirectional sync (Optiply → remote)
- Products that are compositions should be `status = disabled` or `unlimitedStock = TRUE`
- Each product should have at least one supplierProduct
- Sell orders: only completed orders, each product exists once per order

## Links
- [[Optiply API]] — API endpoint reference
- [[ETL Patterns]] — how mappings are implemented
- [[Build Standards]] — code conventions for implementing these mappings
