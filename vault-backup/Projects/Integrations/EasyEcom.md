---
tags: [integration, project, live]
integration: EasyEcom
type: E-commerce/WMS
auth: API Key
status: 🟢 Live
updated: 2026-02-24
---

# EasyEcom Integration

## Sync Board (all 30 min, BO export 10 min)
| Entity | Direction |
|--------|-----------|
| Products (no deletions) | EasyEcom → OP |
| Product Compositions | EasyEcom → OP |
| Suppliers | EasyEcom → OP |
| Supplier Products | EasyEcom → OP |
| Sell Orders | EasyEcom → OP |
| Buy Orders + Lines | EasyEcom ↔ OP |
| Receipt Lines (GRN) | EasyEcom → OP |

## Config Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `send_tax_rate` | false | Add tax to BO line prices on export |

## Product Mapping
- name=product_name, sku=sku, price=mrp, stockLevel=inventory
- assembled=cp_sub_products_count>0, remoteId=cp_id
- Compositions: from sub_products array

## Suppliers
- **Vendors** from getVendors endpoint
- **Locations** also mapped as suppliers (from products.company)

## Supplier Products: price=cost, supplierId=vendor_code

## Sell Orders
- All statuses except Canceled (id=9)
- totalValue=total_amount, placed=order_date

## Buy Orders (bidirectional)
- Completed when po_status_id in [4, 5, 7]
- Export: referenceCode=buyOrderId, vendorId=supplier_remoteId
- Lines: unitPrice can include tax if flag set

## Receipt Lines: from GRN (Goods Receipt Notes)
- quantity=received_quantity, occurred=grn_created_at

## API Reference

### Base URL
`https://api.easyecom.io`

### Auth Method
OAuth2 (Bearer token) with email/password + location_key. Token refresh logic: checks expiry (expires_in - 60s buffer), auto-refreshes via POST to `/access/token`. Writes updated token to config file.

### Endpoints
| Stream | HTTP Method | Path | Pagination |
|--------|-------------|------|------------|
| Products | GET | `/Products/GetProductMaster` | Cursor-based (nextUrl), page_size=10 |
| Suppliers | GET | `/Suppliers` | Cursor-based |
| ProductCompositions | GET | `/ProductCompositions` | Cursor-based |
| SellOrders | GET | `/SellOrders` | Cursor-based |
| BuyOrders | GET | `/BuyOrders` | Cursor-based |
| Receipts | GET | `/Receipts` | Cursor-based |
| Returns | GET | `/Returns` | Cursor-based |

### Rate Limiting
- Strategy: Backoff decorator with `max_tries=10`
- Backoff config: On `RetriableAPIError`, `ReadTimeout`, `ConnectionError`

### Error Handling
- Custom `post_process`: handles NA/N/NULL values, converts string numbers to float
- Graceful "No Data Found" responses
- Status codes: Standard HTTP + custom exceptions

### Quirks
- `_write_state_message` override to clear partitions for `gl_entries_dimensions`
- String-to-float conversion for number fields
- Cursor-based pagination via `nextUrl` from response

---

## ETL Summary

**Pattern:** OLD

**Entities Processed:**
- Products (with composition support)
- Suppliers
- SupplierProducts
- SellOrders
- SellOrderLines
- BuyOrders
- BuyOrderLines

**Key Config Flags:**
| Flag | Default | Purpose |
|------|---------|---------|
| `map_supplierProductSku` | true | Map supplier product SKU |
| `tap_name` | None | Tap name for config backup |

**Custom Logic Highlights:**
- Product compositions extracted from `products` stream (not dedicated stream)
- Supplier products also from `products` stream
- Sell order lines extracted from `sell_orders` with nested `suborders`
- Buy orders/lines from same `buy_orders` stream

---

## Links
- Tap: [tap-easyecom](https://github.com/hotgluexyz/tap-easyecom)
- Target: [target-easyecom](https://github.com/hotgluexyz/target-easyecom)
- ETL: `optiply-scripts/import/EasyEcom/etl.ipynb`
- API: [API Docs](https://api-docs.easyecom.io/)
- Confluence: [Data Mapping](https://optiply.atlassian.net/wiki/spaces/IN/pages/2928476161)
