---
tags: [infrastructure, operations]
updated: 2026-02-24
---

# Infrastructure

## Services

| Service | Host | Port | Purpose | Managed By |
|---------|------|------|---------|------------|
| RAG Server | 127.0.0.1 | 8000 | Knowledge retrieval (pgvector) | launchd (ai.optiply.rag) |
| PostgreSQL 16 | 127.0.0.1 | 5432 | Knowledge chunks + embeddings | brew services |
| Dashboard | 127.0.0.1 | 3001 | Support dashboard UI | manual |
| OpenClaw Gateway | 127.0.0.1 | 18789 | AI agent gateway | openclaw |

## Database
- **DB:** optiply_ai
- **User:** optiply_app
- **Key table:** knowledge_chunks (pgvector embeddings)
- **Extension:** pgvector for similarity search

## Scripts
| Script | Path | Purpose |
|--------|------|---------|
| RAG server | ~/optiply/rag.py | Uvicorn API for chunk retrieval |
| Ingest | ~/optiply/ingest.py | Embed and insert chunks |

## Secrets
- `~/optiply/.env` (chmod 600)

## Logs
- `~/optiply/logs/`

## Known Issues
- RAG launchd plist references python3.9 (broken) — must use python3.11
