---
tags: [integration, project, live]
integration: Lightspeed C-Series
type: E-commerce/POS
status: 🟢 Live
updated: 2026-02-24
---

# Lightspeed C-Series Integration

## Sync Board (all every 10 min)
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Products | LS → OP | 10 min |
| Suppliers | LS → OP | 10 min |
| Supplier Products | LS → OP | 10 min |
| Sell Orders | LS → OP | 10 min |
| Sell Order Deletions | LS → OP | 10 min (cancelled) |
| Receipt Lines | OP → LS | 15 min |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_products_hidden` | false | Sync hidden products as enabled |
| lotSize sync | off | Opt-in lotSize from variant.Colli |
| `sellorders_delete_statuses` | "cancelled" | Custom delete status list |
| Item Deliveries to LS | off | Update stock in LS on delivery |

## Product Mapping
| Optiply | Lightspeed |
|---------|------------|
| name | product.title + title_variant |
| skuCode | variant sku |
| articleCode | variant articleCode |
| price | variant priceExcl |
| unlimitedStock | stockTracking=disabled → true |
| status | visibility=hidden → disabled |
| stockLevel | variant stockLevel |
| remoteId | variant id |

## Suppliers: name (or id if no name), country, remoteId=id

## Supplier Products
| Optiply | Lightspeed |
|---------|------------|
| price | variant priceCost |
| lotSize | variant.Colli (if ≥1) |
| supplier | product.supplier |
| eanCode | variant ean |

## Sell Orders
- Many statuses synced (processing*, completed*)
- cancelled → delete
- totalValue = 0 (TBD — not properly mapped)
- No order updates

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | `{base_url}/{language}` (e.g., `https://api.webshopapp.com/nl`) |
| **Auth Method** | Basic Auth (`api_key` + `api_secret`) |
| **Pagination** | Page number (`?page=N`), limit 250 per page |
| **Rate Limiting** | Throttle 1.3s between requests (configurable), backoff expo (max 10 tries, factor 3), explicit `Retry-After` handling for 429 |

### Endpoints

| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| shop | GET | `/shop.json` | Page |
| orders | GET | `/orders.json` | Page |
| order_lines | GET | `/order_lines` | Page |
| products | GET | `/products.json` | Page |
| variants | GET | `/variants.json` | Page |
| customers | GET | `/customers.json` | Page |
| categories | GET | `/categories.json` | Page |
| suppliers | GET | `/suppliers.json` | Page |
| returns | GET | `/returns.json` | Page |
| shipments | GET | `/shipments.json` | Page |

### Error Handling
- Extra retry: 429, 404, 5xx
- Custom `TooManyRequestsError` for rate limits
- 401-499 → FatalAPIError
- 404 for "Unknown or inactive language" → FatalAPIError

### Quirks
- Cleans false values from non-boolean fields
- Converts boolean to None for integer-typed fields
- Converts empty strings to None for integer/number fields
- `_write_state_message` clears partitions for child streams

## ETL Summary

| Attribute | Value |
|-----------|-------|
| **Pattern** | Generic ETL (uses `utils.payloads` + `utils.actions`) |
| **Entities** | Products (with variants), Suppliers, SupplierProducts, SellOrders, BuyOrders, BuyOrderLines, ReceiptLines |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_lot_size` | false | Sync lotli |
| `sync_sell_ordersSize from variant.Col_only` | false | SubTenant pattern - sync only sell orders |
| `sync_products_hidden` | false | Sync hidden products as enabled |
| `sellorders_delete_statuses` | ["cancelled"] | Custom delete status list |

### Custom Logic
- **Variant handling**: Merges products + variants tables
- Parent-snapshot pattern for subtenants (`parent-snapshots` directory)
- Products have `visibility` field → status (hidden → disabled)

---

## Links
- Tap: [tap-lightspeed](https://github.com/hotgluexyz/tap-lightspeed)
- Target: [target-lightspeed](https://github.com/hotgluexyz/target-lightspeed)
- ETL: `optiply-scripts/import/LightSpeed/etl.ipynb`
- API: [eCom API](https://developers.lightspeedhq.com/ecom/introduction/introduction/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2777874433)
