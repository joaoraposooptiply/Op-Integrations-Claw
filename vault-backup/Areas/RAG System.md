---
tags: [ai, rag, infrastructure]
updated: 2026-02-24
---

# RAG System

## Overview
pgvector-based retrieval for integration support queries. Tenant-isolated.

## Endpoint
```
POST http://127.0.0.1:8000/retrieve
Content-Type: application/json

{"query": "...", "tenant_id": "..."}
```

## Response
Returns top 8 chunks ranked by cosine similarity. Each chunk has:
- `title`, `content`, `integration`, `similarity`

## Confidence Rules
- similarity ≥ 0.75 → use as primary context
- similarity < 0.75 → flag as low-confidence, fall back to vault knowledge

## Chunk Format
- Size: 800 chars, 20% overlap
- Tags: integration name + category (setup/auth/troubleshooting/mapping)

## Current State
- **Chunks: 0** (wiped 2026-02-24, fresh ingest pending)
- DB: optiply_ai on localhost:5432
- Table: knowledge_chunks

## Ingest Process
1. Parse source (Postman collection, API docs, support articles)
2. Chunk at 800 chars with 20% overlap
3. Tag with integration + category
4. Embed and insert via ~/optiply/ingest.py
5. Verify: query test + count check
