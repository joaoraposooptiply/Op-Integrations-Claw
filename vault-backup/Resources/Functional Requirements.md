---
tags: [standards, integration, onboarding, reference]
updated: 2026-02-24
source: https://optiply.atlassian.net/wiki/spaces/IN/pages/534544394
---

# Functional Requirement of Integration (Generic)

> Master checklist for setting up any new integration with the Optiply API. Used as onboarding guide for customers building their own integrations.

## Prerequisites

### Roles Required
1. **Functionally responsible** — makes supply chain decisions:
   - Which product sets to sync?
   - Which warehouse to look at?
   - What is the definition of stock level?
2. **Technically responsible** — makes software/IT decisions:
   - Which permissions does the API user need?
   - How to stay within rate limits?
   - How to PATCH changes efficiently?

### Supply Chain Positioning
Before integration:
- Which purchasing processes will Optiply handle?
- Which stock hubs are optimized by Optiply?
- Which suppliers are managed through Optiply?
- **One Optiply environment per physical stock location** (recommended)
- Multiple digital administrations covering one physical location? → Consolidate into one Optiply environment

### IT Connections
- Which remote software environment(s) will Optiply connect to?
- Which system is source of truth for product info + stock positions?

## Entity Sync Decisions

For each entity, decide:

| Entity | Required | Sync Direction | Notes |
|--------|----------|---------------|-------|
| Products | ✅ YES | Remote → Optiply | Always required |
| Stocks | ✅ YES | Remote → Optiply | Always required |
| Sell Orders | ✅ YES | Remote → Optiply | Only completed orders |
| Suppliers | No | Remote → Optiply (if exists in remote, else store in Optiply) | |
| Supplier Products | No | Remote → Optiply (if exists in remote, else store in Optiply) | |
| Product Compositions | No | Remote → Optiply (if exists in remote, else store in Optiply) | |
| Buy Orders | No | **Bidirectional** (if exists in remote), else store in Optiply | |
| Receipt Lines | No | **Bidirectional** (if exists in remote), else store in Optiply | |

## Products

### Requirements
- **Remote ID mapping:** keep Optiply's ID in remote (advised)
- **Operations:** Create, Update, Delete
- **Flow:** Strictly remote → Optiply
- **Initial import:** done through API
- **Limitation:** No full deletes — use `status = 'disabled'`

### Timeliness Options
- Webhooks
- Temporal Batch (refresh every 5 min)
- Full batch

### Testing Checklist
- [ ] Creating a product in remote → synced to Optiply in timely manner
- [ ] Deleting a product in remote → status = 'disabled' in Optiply
- [ ] Updating price in remote → reflected in Optiply
- [ ] Total product count matches between systems
- [ ] Price is excluding VAT
- [ ] Non-inventory products (e.g. 'shipping') → status = 'disabled'
- [ ] Composition products → status = 'disabled' or unlimitedStock = TRUE

### Product Bundles
If remote has composed products but doesn't register their sales properly, Optiply can handle this — contact support.

## Suppliers

### Requirements
- **Operations:** Create, Update
- **Flow:** Strictly remote → Optiply
- **Limitation:** No deletes — use `ignored` status

### Testing Checklist
- [ ] New supplier in remote → synced to Optiply
- [ ] Supplier emails synced

## Supplier Products

### Requirements
- **Operations:** Create, Update, Delete
- **Flow:** Strictly remote → Optiply
- **Limitation:** No full deletes — use `status = 'disabled'`. `preferred` cannot be set on POST, only on UPDATE.

### Testing Checklist
- [ ] Creating supplier product in remote → synced timely
- [ ] Deleting → status = 'disabled' in Optiply
- [ ] Purchase price updates reflected
- [ ] Purchase price is excluding VAT
- [ ] Each product has at least one supplierProduct
- [ ] Lot sizes properly set
- [ ] If multiple supplierProducts per product, correct one is preferred

## Sell Orders

### Requirements
- **Only completed sell orders** — no pending/draft
- **Each product exists only once per sell order**
- **Operations:** Create, 'delete' (set amount to 0 for cancellation)
- **Flow:** Strictly remote → Optiply
- **Sell order lines** can be created in same request as sell order
- **Think about cancelled orders** — if only occasional, no correction needed

### Testing Checklist
- [ ] New sell order gets imported
- [ ] After full import, sell order count matches
- [ ] New orders imported timely
- Test via: `GET /v1/sellOrders?filter[updatedAt][gt]=<date>`

## Stock Changes

### Requirements
- **Stock level** = physical stock in warehouse − planned outgoing stock
- Can be **negative**
- Always use **smallest denominator** (no units concept)
- Sync as close to **realtime** as possible

## Buy Orders (Bidirectional)

### When remote has buy orders:
- Sync both directions: remote ↔ Optiply
- `reference` field maps back to Optiply's BuyOrder.id

### When remote doesn't have buy orders:
- Store in Optiply only
- Sync item deliveries from Optiply to remote

## Links
- [[Generic Data Mapping]] — field-level schema for all entities
- [[Optiply API]] — API endpoint documentation
- [[ETL Patterns]] — implementation patterns
- [[Build Standards]] — code conventions
