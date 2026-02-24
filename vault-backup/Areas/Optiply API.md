---
tags: [optiply, api, reference]
updated: 2026-02-24
---

# Optiply Public API Reference

**Docs:** https://api-documentation.optiply.com/
**Spec:** Loosely follows JSONAPI spec
**Contact:** integrations@optiply.nl

## Required Header
```
Content-Type: application/vnd.api+json
```
Must be included with every request.

## Authentication
- OAuth2 based (details in API docs authentication section)
- Scopes control access (delete scope added to all users as default since 2022-07)

## API Entities (Resources)

| Entity | Description |
|--------|-------------|
| `accounts` | Customer accounts (no DELETE) |
| `products` | Product catalog |
| `suppliers` | Supplier records |
| `supplierProducts` | Product-supplier relationships (price, delivery time, lot size) |
| `sellOrders` | Sales orders |
| `sellOrderLines` | Individual lines within sell orders |
| `buyOrders` | Purchase orders |
| `buyOrderLines` | Individual lines within buy orders |
| `receiptLines` | Receipt/delivery lines |
| `productCompositions` | Bill of materials / composed products |
| `promotions` | Marketing promotions affecting demand |
| `promotionProducts` | Products linked to promotions |

## Pagination
- `page[limit]=100` — max 100, default 50
- `page[offset]=50` — must be multiple of page size

## Filtering
All entity attributes can be filtered:
- `filter[id][EQ]=12345` or `filter[id]=12345` — equal
- `filter[id][NEQ]=12345` — not equal
- `filter[id][LIKE]=abc` — string partial match
- `filter[id][LT]=12345` — less than
- `filter[id][LE]=12345` — less than or equal
- `filter[id][GT]=12345` — greater than
- `filter[id][GE]=12345` — greater than or equal
- `filter[status]=ENABLED` — status filter

## Sorting
- `sort=id` — ascending
- `sort=-id` — descending

## Key Product Fields
- `id`, `uuid`
- `stockMeasurementUnit` (added 2025-01)
- `maximumStock` (added 2024-09)
- `minimumStock` (added 2022-05)
- `manualServiceLevel` (added 2024-08)
- `createdAtRemote` (added 2024-08)
- `ignored` (added 2022-11)
- `novel` (added 2023-10)

## Key Supplier Fields
- `id`, `uuid`
- `deliveryTime` — null or 1-365
- `userReplenishmentPeriod` — null or 1-365
- `type` (added 2024-12)
- `globalLocationNumber` (added 2023-04)
- `maxLoadCapacity`, `containerVolume` (added 2022-05)
- `lostSalesReaction`, `lostSalesMovReaction`, `backorderThreshold`, `backordersReaction` — value 0 or 1

## Key SupplierProduct Fields
- `id`, `uuid`
- `deliveryTime` — null or >= 1
- `lotSize` — null or >= 1
- `minimumPurchaseQuantity` — null or >= 1
- `weight`, `volume` (added 2022-05)
- `freeStock` (added 2021-12)
- `preferred` (POST, added 2024-01)
- `availability`, `availability_date` (added 2023-10)

## Key BuyOrder Fields
- `id`, `uuid`
- `placed` — order date
- `expectedDeliveryDate` — auto-calculated: placed + supplier.deliveryTime if omitted
- `assembly` (added 2024-11)

## Key BuyOrderLine Fields
- `expectedDeliveryDate` — inherits from buyOrder or calculated from supplierProduct.deliveryTime
- `productUuid` (added 2025-05, prep for API v2)

## Cascade Deletes
- `buyOrders` → `buyOrderLines` → `receiptLines`

## Unique Constraints (409 on conflict)
- `supplierProducts`: supplier/product id pair must be unique
- `productCompositions`: composedProduct/partProduct id pair must be unique

## API v2 Preparation
- UUID fields added alongside integer IDs (2025-01, 2025-05)
- v2 will use UUID as primary identifier
- `resourceId` removed, `uuid` added on all endpoints

## Changelog Highlights
- 2026-01: deliveryTime/userReplenishmentPeriod restricted to null or 1-365
- 2025-05: UUID on buyOrderLines, cascade deletes
- 2025-01: stockMeasurementUnit, uuid on all endpoints
- 2024-12: supplier.type
- 2024-09: products.maximumStock
- 2024-08: manualServiceLevel, createdAtRemote

## Target Reference (target-optiply)

> This is the **target that writes data TO Optiply** from all integrations. Used by every tap integration to push data into Optiply.

| Attribute | Details |
|-----------|---------|
| **Target Repo** | [target-optiply](https://github.com/hotgluexyz/target-optiply) |
| **Auth Method** | OAuth2 — `client_id`, `client_secret`, `username`, `password` → token refresh with automatic retry on 401 |
| **Base URL** | `https://api.optiply.com/v1` (configurable via `optiply_base_url` env var) |

### Sinks/Entities

| Sink | Endpoint | HTTP Method |
|------|----------|-------------|
| ProductsSink | `products` | POST/PATCH |
| SupplierSink | `suppliers` | POST/PATCH |
| SupplierProductSink | `supplierProducts` | POST/PATCH |
| BuyOrderSink | `buyOrders` | POST/PATCH |
| BuyOrderLineSink | `buyOrderLines` | POST/PATCH |
| SellOrderSink | `sellOrders` | POST/PATCH |
| SellOrderLineSink | `sellOrderLines` | POST/PATCH |

### HTTP Methods
- **POST** — create new entities
- **PATCH** — update existing entities by `id`

### Error Handling
- `backoff.expo` with max 5 tries on `RetriableAPIError`, `ReadTimeout`
- 401 triggers token refresh + retry
- 404 logged as warning, continues
- 500+ raises `RetriableAPIError`
- 400+ raises `FatalAPIError`

### Quirks
- Uses `application/vnd.api+json` content type (JSONAPI spec)
- Supports `account_id` and `coupling_id` as query params
- Generates `target-state.json` for Hotglue-style state management

### See Also
- [[Build Standards]] — for tap/target building guidelines
- [[ETL Patterns]] — for ETL notebook patterns

