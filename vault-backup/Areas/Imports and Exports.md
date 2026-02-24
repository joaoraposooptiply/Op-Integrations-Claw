---
tags: [architecture, imports, exports, confluence]
source: confluence OP space
authors: Marlene Oliveira
updated: 2026-02-24
---

# Imports & Exports

> Source: Confluence OP space. By Marlene Oliveira.

## Imports

### How It Works
1. User uploads CSV file (max 5MB)
2. File uploaded to Google Cloud Storage
3. Message sent to `webshop.product.import.trigger` Kafka topic
4. Webshop Product Import Service processes in batches of 500
5. Validates: operation type (UPDATE only), headers, data types, constraints
6. Sends to `webshop.products.import` topic
7. Product Service Imports Consumer updates product database
8. Updates mirrored in legacy database

### Import States
| State | Meaning |
|-------|---------|
| `IN_QUEUE` | Queued for processing |
| `IMPORTING` | Data being imported |
| `COMPLETED` | Success |
| `COMPLETED_WITH_ERRORS` | Partial success |
| `INVALID_OPERATION_TYPE` | Bad operation type |
| `FAILED_HEADERS` | Header validation failed |
| `FAILED_WITH_VALIDATION_ERRORS` | Data validation failed |
| `FAILED_UNEXPECTEDLY` | Unexpected error |

### Key Details
- Only UPDATE operation currently supported (no INSERT, no UPSERT)
- Duplicate detection: won't process if import with IMPORTING/IN_QUEUE exists
- Uses `identifier` + `webshop_uuid` to match products
- Recovery: saves `processing_offset` + `processing_step` for crash recovery

### API Endpoints
- `findOne` — get specific import info
- `findAll` — list all imports
- `retry` — re-trigger a specific import

---

## Exports

### How It Works
1. Frontend requests export with: visible columns, file name, file type, sorts/filters
2. Service checks: user has webshop access + exports feature enabled
3. Gets unpaged data from database
4. Generates file (CSV, XLSX, or PDF for buy orders)
5. Saves to Google Cloud Storage bucket
6. Sends Kafka message to Export Service for history tracking

### Available Export Sources
- Products, Suppliers, Product Suppliers, Supplier Products
- Promotions, Product Promotions, Promotion Webshop Products
- Buy Orders, Undelivered Products

### File Types
- CSV, XLSX (all exports)
- PDF (buy orders only)

### Buy Order Export Settings
Configurable per webshop — 3 active identifiers from:
- `SUPPLIER_PRODUCT_ARTICLE_CODE/EAN_CODE/SKU_CODE/NAME`
- `WEBSHOP_PRODUCT_ARTICLE_CODE/EAN_CODE/SKU_CODE/NAME`

Defaults: `WEBSHOP_PRODUCT_SKU_CODE`, `WEBSHOP_PRODUCT_EAN_CODE`, `WEBSHOP_PRODUCT_ARTICLE_CODE`

Column order always: SKU → EAN → Article Code (webshop > supplier priority)

### Buy Order Email
- Sends buy order to supplier via email with 3 export file attachments
- Uses SendGrid for email delivery
- Kafka-based: message → consumer → generate files → upload to GCS → attach URIs → send email

### Export History Table
Fields: uuid, name, created_at, updated_at, deleted_at, status, webshop_uuid, user_uuid, source, file_uri

### Infrastructure Notes
- Files stored in Google Cloud Storage bucket
- History tracked via Kafka topics
- gRPC for internal service communication
- REST for download endpoint only
