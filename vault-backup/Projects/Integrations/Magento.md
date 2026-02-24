---
tags: [integration, project, live]
integration: Magento 2
type: E-commerce
auth: API Key (Bearer token)
status: 🟢 Live
updated: 2026-02-24
---

# Magento 2 Integration

> Two variants: **Non-Warehouse** (simpler) and **Warehouse** (MSI multi-source inventory).

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]
> Stock endpoint has NO `updated_at` filter — forces full syncs.

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | Magento → OP | 30 min (updated) |
| Product Deletions | Magento → OP | 60 min (full sync comparison) |
| Stocks | Magento → OP | 30 min (always full) |
| Sell Orders | Magento → OP | 30 min |

- **Full sync required** for stock (no updated_at filter on stock endpoint)
- Frequency varies per shop size (60min for small, daily for large)
- Deleted products: detected by full sync comparison (enabled in OP but gone from Magento)

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `map_stockLevel` | true | Disable if customer uses third-party stock sync |
| salable_quantity vs quantity | salable_quantity | Which stock field to use |

## Product Mapping
| Optiply | Magento |
|---------|---------|
| name | name |
| skuCode | sku |
| articleCode | id |
| price | price |
| unlimitedStock | type!="simple" OR manage_stock=false → true |
| stockLevel | qty (from stockStatuses/{SKU}) |
| status | 1=enabled, 2=disabled |
| createdAtRemote | created_at |

## Sell Orders
- totalValue=subtotal, placed=created_at, completed=updated_at
- Default: only completed. Customer can choose all.
- No order updates synced

### Lines
- productId=product_id, quantity=qty_ordered, subtotalValue=base_row_total

## Warehouse Variant
- Uses MSI (Multi-Source Inventory) for stock
- Stock from specific source(s) configurable
- Same product/order mappings

## Key Complexity
- No delete API → full sync comparison required
- No stock updated_at → forced full syncs for stock (expensive for large catalogs)

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `{store_url}/rest` |
| **Auth Method** | Bearer Token (admin integration token) OR OAuth1 (consumer_key/secret + token) |
| **Pagination** | Page number (`searchCriteria[currentPage]`, `searchCriteria[pageSize]`, default 300, max 200 pages before date shift) |
| **Rate Limiting** | Backoff with 30s initial wait, handles 500 errors with per-page retries |

### Endpoints

| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| orders | GET | `/V1/orders` | Page |
| products | GET | `/V1/products` | Page |
| customers | GET | `/V1/customers` | Page |
| invoices | GET | `/V1/invoices` | Page |
| creditmemos | GET | `/V1/creditmemos` | Page |
| categories | GET | `/V1/categories/list` | Page |
| salesRules | GET | `/V1/salesRules/search` | Page |
| coupons | GET | `/V1/coupons/search` | Page |
| websites | GET | `/V1/store/websites` | Page |
| source-items | GET | `/V1/inventory/source-items` | Page |
| lowStock | GET | `/V1/stockItems/lowStock` | Page |
| storeConfigs | GET | `/{store_code}/V1/store/storeConfigs` | Page |

### Error Handling
- Extra retry: 503, 404
- 500 after 3 retries → skip page
- 400-499 → FatalAPIError
- Custom allowed_error_messages for product existence

### Quirks
- Supports multi-store sync with `store_id` / `store_code` filtering
- Not filterable by store: categories, product_attributes, salerules
- For large syncs (>200 pages), automatically updates start_date to avoid memory issues (503)
- Special handling for `product_item_stocks` (different pagination)
- Uses `searchCriteria` with filterGroups for date range queries

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Old pattern (custom, simplified) |
| **Entities** | Products, SellOrders (with lines) |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `use_inventory_source_items` | false | Warehouse mode (MSI) |
| `use_stock_statuses` | true | Non-warehouse mode |
| `use_salable_quantity` | true | Backorder-aware stock |
| `map_stockLevel` | true | Include stock in diff check |
| `warehouse_ids` | — | Comma-separated |
| `pullAllOrders` | false | Sync all statuses |
| `sync_product_deletions` | false | Detect deletions |

### Custom Logic
- **Dual stock sources** (config-driven):
  - Non-warehouse: `product_stock_statuses` endpoint → `stock_item` JSON explode
  - Warehouse: `source_items` endpoint → grouped by SKU
- **Salable quantity** vs regular quantity (backorder-aware)
- **Type handling**: simple products get stock; others get qty=0 + unlimitedStock=true
- Product deletions via full sync comparison

---

## Links
- Tap: [tap-magento](https://github.com/hotgluexyz/tap-magento)
- Target: [target-magento](https://gitlab.com/hotglue/target-magento)
- ETL: `optiply-scripts/import/magento/etl.ipynb`
- Confluence: [Non-Warehouse](https://optiply.atlassian.net/wiki/spaces/IN/pages/2344845313) / [Warehouse](https://optiply.atlassian.net/wiki/spaces/IN/pages/2443083785)
