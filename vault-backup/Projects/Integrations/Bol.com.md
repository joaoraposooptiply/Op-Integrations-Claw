---
tags: [integration, project, live]
integration: Bol.com
type: Marketplace
auth: BOL Retailer API
status: 🟢 Live
updated: 2026-02-24
---

# Bol.com Integration

> **Secondary integration only** — only syncs Sell Orders. Products come from another source.

**Part of** [[Optiply - Company|Optiply]]'s integration ecosystem · Runs on [[HotGlue Architecture|HotGlue]] · Syncs to [[Optiply API]] · Schema: [[Generic Data Mapping]] · Registry: [[Integration Registry]]

## Sync Board
| Entity | Direction | Frequency |
|--------|-----------|-----------|
| Sell Orders | BOL → OP | 60 min (matches primary source) |
| Sell Order Lines | BOL → OP | 60 min |

## Important
- BOL is always a **secondary** integration — products, suppliers, supplierProducts come from another source (WooCommerce, Shopify, etc.)
- Mapping key: customer chooses **skuCode** or **eanCode** (BOL's main key is EAN)
- FE shows option to select mapping key
- Syncs FBR (Fulfilled by Retailer) AND FBB (Fulfilled by bol.com) orders/shipments
- No order updates synced — no line changes, deletions, or additions

## Sell Order Mapping
| Optiply | BOL |
|---------|-----|
| totalValue | sum(sellOrderLine.subtotalValue) |
| placed | orderPlacedDateTime |
| remoteId | orderId |

## Sell Order Lines
| Optiply | BOL |
|---------|-----|
| productId | optiplyWebshopProductId |
| quantity | quantity |
| subtotalValue | unitPrice × quantity |

## API Reference

> See also: [[Build Standards]] | [[ETL Patterns]]

### Base URL
`https://api.bol.com/retailer`

### Auth Method
- **Type:** OAuth2 with refresh_token grant
- **Token Refresh:** Yes - `update_access_token()` with refresh_token + client_id + client_secret

### Endpoints
| Stream Name | HTTP Method | Path | Pagination |
|-------------|-------------|------|------------|
| orders | GET | /orders | Page-based |
| shipments | GET | /shipments | Page-based (FBR/FBB loop) |
| order_details | GET | /orders/{order_id} | No pagination (singleton) |
| shipment_details | GET | /shipments/{shipment_id} | No pagination (singleton) |

### Rate Limiting
- **Strategy:** `backoff.expo` with max_tries=12, factor=5
- **Backoff Config:** Honors `retry-after` header (sleeps for specified seconds)
- **Retries:** RetriableAPIError, ReadTimeout, RemoteDisconnected, ChunkedEncodingError, ProtocolError, etc.

### Error Handling
- **500-599, extra_retry_statuses:** RetriableAPIError
- **400-499:** FatalAPIError
- **503:** ServiceUnavailableError (custom exception)

### Quirks
- Accept header: `application/vnd.retailer.v10+json`
- Deduplicates orders by orderId during sync
- `_write_state_message` fix for partition cleanup
- Shipments syncs both FBR and FBB fulfillment methods sequentially

---

## ETL Summary

- **Pattern:** Old (simplest order ETL)
- **Entities Processed:**
  - Products (from primary source)
  - SellOrders (via orders + shipments)
- **Key Config Flags:**
  - `optiply_key` - Which field to match products (default: "eanCode")
  - `sell_order_method` - Filter orders by fulfillment method ("all" or specific method)
  - `sync_shipments` - Enable shipment-based order creation
- **Custom Logic Highlights:**
  - **Order merging:** Combines `order_details` and `shipment_details` into unified sell orders
  - **FBB method filter:** Can filter by fulfillment method (e.g., "FBB")
  - **Shipment sync:** Auto-disables if sellOrders snapshot exists
  - EAN-based matching for products
  - Ships orders separately if no products matched (404 handling)
  - Creates orders without lines, then posts lines separately
  - Handles `cancellationRequested` flag

---

## Links
- Tap: [tap-bol](https://gitlab.com/hotglue/tap-bol)
- ETL: `optiply-scripts/import/bol.com/etl.ipynb`
- API: [Retailer API](https://api.bol.com/retailer/public/Retailer-API/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2524643339)
