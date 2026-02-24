---
tags: [hotglue, architecture, api, confluence]
source: https://optiply.atlassian.net/wiki/spaces/OP/pages/2274197513
author: Marlene Oliveira
updated: 2026-02-24
---

# HotGlue Redirect Service

> Source: Confluence OP space. By Marlene Oliveira, updated Feb 2026 (v13).

## What It Is
A redirect/proxy service between Optiply frontend and HotGlue APIs. Gives fine-grained control over which HotGlue endpoints are exposed. Uses Micronaut declarative HTTP client. Passes requests through without modification; responses are returned as-is.

## HotGlue Environments
- Production: `production.hotglue.optiply.nl`
- Dev: `dev.hotglue.optiply.nl`

## Roles & Permissions
- **Users** — basic access (flows, sources, linked sources, jobs read)
- **Admins** — full access including job triggers, tenant config
- **Integrations Admins** — same as admins

## Endpoint Groups

### Flows
- `GET hotglue/{webshopUuid}/flows/supported` — list available flows
- `GET hotglue/{webshopUuid}/flows/linked` — list linked flows
- `POST hotglue/{webshopUuid}/flows/linked` — create linked flow

**Flow concept:** A group of integrations of the same type. E.g., "E-commerce" flow contains Shopify, Magento, WooCommerce, Montapacking taps.

**Known flow ID:** `p6BFCREDz` = E-commerce flow

### Sources (Taps)
- `GET .../sources/{flowId}/supportedSources` — available taps (with catalog query param)
- `GET .../sources/{flowId}/{tenant}/linkedSources` — linked taps for tenant
- `POST .../sources/{flowId}/{tenant}/linkedSources` — create linked source
- `PATCH .../sources/{flowId}/{tenant}/linkedSources` — update config/field_map
- `DELETE .../sources/{flowId}/{tenant}/linkedSources/{tapName}` — unlink

### Targets
- `GET .../targets/{flowId}/supportedTargets`
- `GET .../targets/{flowId}/{tenant}/linkedTargets`
- `POST .../targets/{flowId}/{tenant}/linkedTargets`

### Jobs
- `GET .../jobs/{flowId}/{tenant}/retrieve` — list jobs (with count, scheduled params)
- `GET .../jobs/retrieve` — jobs per tap (with tenant, taps, targets, status, from/to, pagination)
- `GET .../jobs/{flowId}/{tenant}/latest` — latest job
- `POST .../jobs/{flowId}/{tenant}/latest` — trigger job (admin only)

**Job trigger params:** state, tap, job_name, override_start_date, reset_source_state, override_selected_tables, override_field_map

**Job statuses:** JOB_CREATED, JOB_COMPLETED, SYNC_FAILED

### File Imports
- `POST hotglue/{webshopUuid}/files/{flowId}/{tenant}/upload/{taps}` — multipart upload
- `DELETE hotglue/{webshopUuid}/files/{flowId}/{tenant}/delete/{taps}`

### Tenants
- `GET hotglue/tenants/{tenant}/config` — get tenant config (admin)
- `PATCH hotglue/tenants/{tenant}/config` — update config (admin)
- `PUT hotglue/tenants/{tenant}/config` — set config (admin)
- `PUT hotglue/tenants/{tenant}/metadata` — set metadata (admin)
- `POST hotglue/tenants/{tenant}/{webshopUuid}/config/imports` — create import credentials
- `POST hotglue/tenants/{tenant}/{webshopUuid}/config/api` — create API credentials

## Tenant Config Structure
```json
{
  "importCredentials": {
    "access_token": "...",
    "password": "...",
    "account_id": 98,
    "webshop_uuid": "...",
    "client_secret": "...",
    "client_id": "test-shop",
    "username": "api_imports_visdeal_393"
  },
  "apiCredentials": { ... },
  "hotglue_metadata": {
    "metadata": {
      "webshop_handle": "test-shop"
    }
  }
}
```

## API Credential Creation Flow
1. PHP → get coupling info
2. Webshop Service → get client ID (webshop handle)
3. Account Service → create Integrations user
4. Webshop Service → associate user with webshop
5. PHP/Auth Service → create client details + access token
6. Save to HotGlue tenant config
7. Create linked target (imports) or linked source (API)

## Known Taps in HotGlue
From flow examples: montapacking, woocommerce, shopify, magento, odoo, file

## Known Targets
From examples: woocommerce-v2, shopify-v2, bigquery

## Source Config Examples
- **WooCommerce source:** site_url, consumer_key, consumer_secret, pullAllOrders, updateProductStock
- **Shopify source:** api_key (API Password), start_date, date_window_size
- **Odoo source:** url, db, username, password, start_date

## Field Maps (Shopify example)
```json
{
  "inventory_items": ["id", "updated_at", "sku", "created_at"],
  "products": ["updated_at", "id", "status", "published_at", "created_at"],
  "orders": ["id", "updated_at", "presentment_currency", "subtotal_price_set"]
}
```

## Related Pages (IN space)
- Hotglue - Main concepts and how it works
- Hotglue Data Mapping - Exact Online
- Hotglue Webhook receiver
- Hotglue Data mapping - BOL
- Connect New Tenant
