---
tags: [architecture, infrastructure, confluence]
updated: 2026-02-24
---

# Optiply Architecture Overview

> Compiled from Confluence OP space: Architecture, Infrastructure, and related pages.

## Service-Oriented Architecture
Optiply uses a microservices architecture with:
- **Kafka** for event-driven messaging between bounded contexts
- **gRPC** for internal service communication
- **REST** for external/download endpoints
- **PostgreSQL** (with TimescaleDB extension) for databases
- **Google Cloud Storage** for file storage (imports/exports)
- **Auth0** for authentication
- **CircleCI** for CI/CD
- **SendGrid** for transactional email

## Key Services (from Confluence)
| Service | Purpose |
|---------|---------|
| Product Service | Products, product compositions |
| Supply Service | Suppliers, supplier products |
| Buy Order Service | Purchase orders, deliveries, exports |
| Import Service | File imports (CSV → product updates) |
| Export Service | File exports (CSV/XLSX/PDF generation) |
| Webshop Product Import Service | Validates + batches import data |
| Account Service | User management, webshop access |
| Webshop Service | Webshop configuration, handles |
| HotGlue Redirect Service | Integration proxy (Micronaut) |
| Webhook Gateway Service | Receives external webhooks |

## Data Infrastructure
- **PostgreSQL 15** (with logical replication streaming)
- **TimescaleDB** extension for time-series data
- **Kafka** streaming infrastructure
- **Clickhouse** (benchmarked, likely for analytics)
- **BigQuery** for data warehouse

## Key Kafka Topics
| Topic | Purpose |
|-------|---------|
| `webshop.product.import.trigger` | Triggers import processing |
| `webshop.products.import` | Validated import batches |
| `webshop.product.imports.state` | Import state updates |
| `import.state` | General import state events |
| Exports topic | Export history tracking |
| Buy order email topic | Triggers supplier emails |

## Previous Integration Platforms
- **Dovetail** — old iPaaS, being replaced
- **Alumio** — old iPaaS, being replaced
- **HotGlue** — current platform, Singer-based

## Key Differences from Old Platforms
HotGlue syncs ALL entity types per job (unlike Dovetail/Alumio which sync per entity). E.g., one WooCommerce job syncs products AND sell orders together.

## Webhook Behavior
HotGlue triggers jobs on webhook receipt, even outside scheduled windows. E.g., if scheduled every 60 min but webhook received at 30 min mark → immediate sync.
