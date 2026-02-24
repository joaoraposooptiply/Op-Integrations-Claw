---
tags: [hotglue, architecture, reference]
updated: 2026-02-24
---

# HotGlue Integration Architecture

## What HotGlue Is
Embeddable, cloud-based ETL platform built on Python. Uses open-source Singer connectors.

## Core Concepts

### Singer Spec (Open Source ETL)
- **Taps (Sources)** — extract data FROM remote systems (Shopify, WooCommerce, etc.)
- **Targets** — send data TO a remote system (Optiply)
- Taps and targets communicate via stdout/stdin using JSON messages

### Singer Message Types
- `RECORD` — a data record
- `SCHEMA` — describes the structure of records
- `STATE` — bookmark for incremental sync

### Jobs
HotGlue uses Jobs to move and transform data between remote systems and Optiply.

**ETL Flow:**
1. **E (Extract)** — Tap pulls data from remote system
2. **T (Transform)** — Data is transformed and stored in cache (snapshot)
3. **L (Load)** — Target pushes transformed data to Optiply

### Incremental Sync
- First job: pulls ALL historical data, stores in snapshot (cache layer)
- Subsequent jobs: only pull new/updated records since last sync
- Snapshot enables diff detection (new vs updated vs deleted records)

## Our Integration Stack
```
Remote System → Tap (extract) → Snapshot (cache) → ETL (transform) → Target (load) → Optiply
```

## What We Build Per Integration
1. **Tap** — Python package using `hotglue_singer_sdk` to extract from the source API
2. **Target** — Python package using `hotglue_singer_sdk` to write to Optiply API
3. **ETL Notebook** — Transforms tap output to Optiply entity format
4. **Docs** — Support knowledge base for troubleshooting

## SDK
- Uses `hotglue_singer_sdk` (NOT standard `singer_sdk`)
- Python-based
- Handles: auth, pagination, rate limiting, state management, schema discovery

## Related
- [[Snapshot Queries]] — snapshot construction queries for HotGlue ETL
