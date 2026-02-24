---
tags: [integration, project, live]
integration: Amazon Seller
type: Marketplace
auth: SP-API (OAuth2 + AWS IAM)
status: 🟢 Live
updated: 2026-02-24
---

# Amazon Seller Integration

> Two flavours: **Secondary** (sell orders only) and **Full** (products + sell orders).

## API Regions
| Region | Endpoint | AWS Region |
|--------|----------|------------|
| North America | sellingpartnerapi-na.amazon.com | us-east-1 |
| Europe | sellingpartnerapi-eu.amazon.com | eu-west-1 |
| Far East | sellingpartnerapi-fe.amazon.com | us-west-2 |

- Supports multiple marketplaces per account

## Sync Board (all 30 min)
### Secondary (sell orders only)
| Entity | Direction |
|--------|-----------|
| Sell Orders | Amazon → OP |

- Products from another source (Shopify/WooCommerce etc.)
- Customer selects mapping key: skuCode or eanCode

### Full
| Entity | Direction |
|--------|-----------|
| Products | Amazon → OP |
| Sell Orders | Amazon → OP |

## Product Mapping
| Optiply | Amazon |
|---------|--------|
| name | products_inventory.item-name |
| skuCode | identifiers.identifierType=SKU |
| eanCode | identifiers.identifierType=EAN |
| price | products_inventory.price |
| stockLevel | warehouse_inventory.totalQuantity |
| remoteId | items.asin |

## Sell Orders
| Optiply | Amazon |
|---------|--------|
| totalValue | Orders.OrderTotal.Amount |
| placed | Orders.PurchaseDate |
| remoteId | Orders.AmazonOrderId |

### Lines
| Optiply | Amazon |
|---------|--------|
| productId | OrderItems.ASIN |
| quantity | OrderItems.QuantityOrdered |
| subtotalValue | OrderItems.ItemPrice.Amount |

No order updates synced. No target (inbound only).

## API Reference

| Attribute | Value |
|-----------|-------|
| **Base URL** | Amazon Selling Partner API (via `sp_api` library) |
| **Auth Method** | OAuth 2.0 (refresh_token + LWA app credentials) + AWS (access_key, secret_key, role_arn) |
| **Pagination** | Marketplace-based partitions, report polling (30s sleep loop) |
| **Rate Limiting** | Backoff expo (max 10 tries, factor 5) |

### Endpoints

| Stream | Method | Notes |
|--------|--------|-------|
| marketplaces | SP-API | Marketplace enum |
| orders | Report-based | Report → poll → download |
| order_items | Report-based | Report → poll → download |
| order_buyer_info | Report-based | Report → poll → download |
| order_address | Report-based | Report → poll → download |
| order_financial_events | Report-based | Report → poll → download |
| reports | SP-API | Report management |
| warehouse_inventory | Report-based | FBA inventory report |
| products_inventory | Report-based | Marketplace inventory |
| product_details | Report-based | Product catalog |
| vendor_fulfilment_orders | SP-API | Vendor orders |
| vendor_customer_invoices | SP-API | Vendor invoices |
| vendor_purchase_orders | SP-API | Vendor PO |
| afn_inventory_country | Report-based | AFN by country |
| sales_traffic_report | Report-based | Traffic analytics |
| fba_inventory_ledger | Report-based | Inventory ledger |
| fba_customer_shipment_sales | Report-based | Shipment sales |
| product_catalog | Report-based | Catalog details |
| awd_inventory | Report-based | AWD inventory |
| account | SP-API | Account info |

### Error Handling
- Extensive retry on all exceptions
- Report processing: FATAL/CANCELLED → skip gracefully

### Quirks
- Uses `sp_api` library (not raw REST)
- Report-based streams: creates report → polls every 30s → downloads document (CSV/JSON)
- Marketplace-specific (US, EU, etc.) via `Marketplaces` enum
- Skip incremental partitions for child streams: orderitems, orderbuyerinfo, orderaddress, orderfinancialevents, warehouse_inventory
- Custom CSV parsing (tab-delimited, ISO-8859-1 encoding)

## ETL Summary

### Amazon (Seller - Primary)

| Attribute | Value |
|-----------|-------|
| **Pattern** | Old pattern (custom payload construction, no utils.payloads) |
| **Entities** | Products (from `products_inventory`, `warehouse_inventory`, `product_catalog_details`) |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `optiply_key` | "eanCode" | Match field (eanCode or skuCode) |
| `second_flavour` | false | Switch between FBA vs marketplace inventory |
| `marketplaces` | — | Comma-separated warehouse IDs |
| `uri` | — | Marketplace URL |

### Custom Logic
- Multi-marketplace support with `marketplaceId` concatenation: `remoteId = articleCode_marketplaceId`
- `second_flavour` flag - switches between FBA inventory vs marketplace inventory
- Extracts EAN/SKU from `product_catalog_details` identifiers JSON
- Merges stock from `warehouse_inventory` (multiple warehouses summed)
- Pulls existing products from Optiply API if no snapshot exists (filter by `status=ENABLED`)
- Main warehouse extraction via regex on URI (`.amazon.<country>/`)
- Stock fallback: uses `quantity` if `stockLevel` is 0

### Amazon Vendor (Secondary)

| Attribute | Value |
|-----------|-------|
| **Pattern** | Generic ETL (uses `utils.payloads` + `utils.actions`) |
| **Entities** | Products, Suppliers, SupplierProducts, SellOrders, BuyOrders, BuyOrderLines, ReceiptLines |

### Key Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_sell_orders_only` | false | SubTenant mode - only sync orders |

### Custom Logic
- SubTenant pattern via `parent-snapshots` directory detection
- Products: uses eanCode as remoteId (not itemID like standard)
- Same payload structure as generic but simpler

---

## Links
- Tap: [tap-amazon-seller](https://github.com/hotgluexyz/tap-amazon-seller)
- ETL: `optiply-scripts/import/amazon/etl.ipynb`
- API: [SP-API](https://developer-docs.amazon.com/sp-api/) / [Swagger](https://spapi.cyou/swagger/index.html)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2717188110)
