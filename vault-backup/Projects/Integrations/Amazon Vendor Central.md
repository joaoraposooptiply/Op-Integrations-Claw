---
tags: [integration, project, live]
integration: Amazon Vendor Central
type: Marketplace
auth: LWA OAuth (SP-API)
status: 🟢 Live
updated: 2026-02-24
---

# Amazon Vendor Central Integration

> Vendor Central is the B2B counterpart to Seller Central — vendors sell directly to Amazon.
> Two flavors: **Secondary** (sell orders only) and **Full** (products + sell orders).

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
| Suppliers | Amazon → OP |
| Supplier Products | Amazon → OP |
| Sell Orders | Amazon → OP |
| Buy Orders + Lines | Amazon → OP |
| Receipt Lines | Amazon → OP |

## API Reference

### Base URL
Amazon Selling Partner API (via `sp_api` library). Base URL varies by marketplace.

### Auth Method
LWA OAuth: `lwa_client_id` + `client_secret` + `refresh_token`. Optional: `aws_access_key` + `aws_secret_key` + `role_arn` for SP-API signature.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| VendorPurchaseOrders | GET | `/vendor/orders/v1/purchaseOrders` | Async report polling |
| VendorFulfilmentPurchaseOrders | GET | `/vendor/fulfillment/v1/purchaseOrders` | Async report polling |
| VendorsSalesReport | GET | Reports API | Async report polling |
| VendorsTrafficReport | GET | Reports API | Async report polling |
| VendorsInventoryReport | GET | Reports API | Async report polling |
| InventoryProductsList | GET | `/inventory/hybrid/v1/products` | Async report polling |

Full streams: Vendor Orders, Vendor Fulfillment, Reports, Catalog, Inventory, Finances

### Rate Limiting
- Backoff with `max_tries=10`, `factor=5` on all exceptions
- 30s sleep between status checks

### Error Handling
- Custom exceptions: `InvalidMarketplace`, `ReportNotAvailable`
- Handles `FATAL` report status
- Report document saved to disk then parsed

### Quirks
- Uses `sp_api` library (Selling Partner API)
- Supports sandbox mode
- Custom report types with periods (DAY/WEEK)
- Marketplace-specific API calls
- Report documents saved to disk then parsed

---

## ETL Summary

**Pattern:** Generic (uses `utils.payloads` + `utils.actions`)

**Entities Processed:**
- Products
- Suppliers
- SupplierProducts
- SellOrders
- BuyOrders
- BuyOrderLines
- ReceiptLines

**Key Config Flags:**
| Flag | Default | Purpose |
|------|---------|---------|
| `sync_sell_orders_only` | False | If True + is_subTenant, pulls products from Optiply API |

**Custom Logic Highlights:**
- `sync_sell_orders_only` flag: if True + is_subTenant, pulls products from Optiply API (not from tap)
- SubTenant pattern via `parent-snapshots` directory detection
- Products: uses eanCode as remoteId (not itemID like standard)
- Same payload structure as Generic but simpler
- When syncing sell orders only + subtenant: reads from Optiply API using `products_optiply` snapshot key

---

## Product Mapping
| Optiply | Amazon Vendor |
|---------|----------------|
| name | product_name |
| skuCode | seller_sku |
| eanCode | ean |
| price | price |
| stockLevel | quantity |
| remoteId | vendor_product_id |

## Sell Orders
| Optiply | Amazon Vendor |
|---------|---------------|
| totalValue | totalAmount |
| placed | purchaseDate |
| remoteId | purchaseOrderNumber |

### Lines
| Optiply | Amazon Vendor |
|---------|---------------|
| productId | vendorProductId |
| quantity | quantityOrdered |
| subtotalValue | netCost |

No order updates synced. No target (inbound only).

## Links
- Tap: [tap-amazon-vendor-central](https://github.com/hotgluexyz/tap-amazon-vendor-central)
- ETL: `optiply-scripts/import/amazon-vendor/etl.ipynb`
- API: [Selling Partner API](https://developer-docs.amazon.com/sp-api/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/xxxxxxxx)
