---
tags: [architecture, integrations, confluence]
source: https://optiply.atlassian.net/wiki/spaces/OP/pages/2052521985
author: Fábio Belga
updated: 2026-02-24
---

# Integrations Platform — Technical Specification

> Source: Confluence OP space. Original by Fábio Belga, Dec 2021.

## Summary
Build own integration platform to replace third-party iPaaS (Dovetail/Alumio). Goal: scalable, self-managed, limited-code integration building.

## Key Definitions
- **Webshop** = Optiply customer (from webshops table). E.g., Bralex.com
- **Integration** = System we integrate with. E.g., Exact Online
- **Coupling** = Instance of an integration for a webshop. E.g., "Bralex has a Picqer coupling and an Amazon Sell Order coupling"

## Requirements
1. **Logging** — analyze if process succeeded or failed and why
2. **Monitoring** — know if everything is running (rate limits, auth problems, bad requests)
3. **Modular** — mix and match: products from one system, sell orders from another, BOs from a third
4. **Webhooks** — register webhooks on installation, handle variable webhook load
5. **Multi-coupling mapping** — when combining couplings, define mapping key (remote ID, SKU, EAN)
6. **Rate limit handling** — from remote systems
7. **Retry failed HTTP calls**
8. **Dashboard for Tech Support** — trigger syncs, view status (V2: progress bar)
9. **Scheduling** — cron-based pulls
10. **Consolidation** — same object from multiple sources (e.g., Lightspeed)
11. **Supplier preferred handling**
12. **Configurable mapping key** (EAN, SKU) per coupling
13. **Single-click coupling activation** with auto-progression (products → sell orders → webhooks)
14. **Status exposure** — coupling status to frontend
15. **On/off toggles** — for BOL from BO, SOL from SO
16. **Handle deletions** — for systems without delete sync (Magento, Logic4): compare JSON bodies, find differences
17. **Automated mapping tests** — hard-coded input/output verification
18. **Data transformations** — math (`stockLevel * 2`), type casts (`int_to_string`)
19. **Combine multiple remote endpoints** — e.g., products + stock from different endpoints

## Object Types

### Suppliers
- Pull all / Pull changed since / Pull single

### Webshop Products
- Pull all / Pull changed since / Pull single
- Disable products that don't exist on remote (Magento)

### Supplier Products
- Pull all / Pull changed since / Pull single

### Product Compositions
- Pull all / Pull changed since / Pull single

### Sell Orders
- Pull all / Pull created since / Pull single
- Update stocks from sell orders (for systems without updated_at filter on stocks)

### Buy Orders
- **1-way:** POST BuyOrders to remote
- **2-way:** POST to remote + Pull open/closed BOs from remote

### Item Deliveries
- Connected to 2-way BuyOrder system OR separate API endpoint
- Only makes sense with 2-way BO relationship

## Key Complexities
1. **Different pagination:** Exact provides next-page link; WooCommerce needs page number; others calculate from page size + total count
2. **Different auth:** Exact = token refreshed every 10 min; WooCommerce = key+secret; Logic4 = token per request
3. **Different endpoint structures:** Exact needs 3 endpoints for one Product; Magento needs 2; WooCommerce needs 1; BOL splits orders across 2 endpoints

## Future Requirements (V2)
- Expose last update time + auth status to frontend
- Slack messages with installation progress
- On-the-fly updates for BOs, BOLs, item deliveries
- Cache layer for systems without 'pull since' queries

## People
- Fábio Belga (author)
- Tiago Barradas (reviewer)
- Jan Blans (reviewer)
- Daniel Ramos (code snippets)
