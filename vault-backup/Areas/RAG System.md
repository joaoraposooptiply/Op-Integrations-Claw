---
tags: [infrastructure, rag, ai]
status: 🟢 Live
updated: 2026-02-24
---

# RAG System

## Architecture

```
Obsidian Vault (source of truth)
    ↓ ingest_vault_v2.py (section-level chunking)
pgvector (415 chunks, text-embedding-3-small)
    ↓ rag_v2.py (FastAPI on :8000)
Aria queries via /retrieve
    ↓ source_path in response
Obsidian Vault (deep read when needed)
```

**Obsidian and RAG are complementary:**
- RAG = fast semantic search across all docs (agent-facing)
- Obsidian = full structured context, human-editable (source of truth)
- Every RAG chunk links back to its Obsidian source via `source_path`

## Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/retrieve` | POST | Semantic search — returns top N chunks |
| `/health` | GET | Server + chunk count check |
| `/stats` | GET | Chunk breakdown by integration + category |

## Retrieve Request

```json
{
  "query": "How does Exact handle buy orders?",
  "tenant_id": "00000000-0000-0000-0000-000000000001",
  "integration": "Exact Online",  // optional filter
  "category": "integration",       // optional filter
  "limit": 8                       // default 8
}
```

## Retrieve Response

```json
{
  "chunks": [{
    "title": "Exact Online",
    "section": "Buy Order Export (OP → Exact)",
    "content": "...",
    "integration": "Exact Online",
    "category": "integration",
    "source_path": "Projects/Integrations/Exact Online.md",
    "similarity": 0.629
  }]
}
```

## Ingestion Pipeline (v2)

**Script:** `~/optiply/ingest_vault_v2.py`

### Chunking Strategy
- Splits by `##` headings (section-level, not arbitrary character count)
- Max chunk: 1200 chars, min: 80 chars
- Large sections sub-chunked by paragraph with overlap
- Embedding prefix: `{title} > {section}: {content}` for better context

### Metadata per Chunk
| Field | Source |
|-------|--------|
| `title` | Filename (without .md) |
| `section` | `##` heading text |
| `integration` | Frontmatter `integration:` field or path detection |
| `category` | Path-based: integration, architecture, standards, operations, daily |
| `source_path` | Relative path from vault root |
| `content_hash` | SHA256 of path+section+index+content (dedup) |

### What Gets Ingested
- ✅ `Projects/Integrations/*` — all integration docs
- ✅ `Areas/*` — architecture, infrastructure, company docs
- ✅ `Resources/*` — standards, patterns, templates, registry
- ✅ `Handoff/` + `Learnings/` — operational state
- ✅ `Daily/` — only last 7 days
- ❌ `Archive/` — skipped
- ❌ `Templates/` — skipped (no content value)
- ❌ `.obsidian/` — skipped
- ❌ MOC files (`_*.md`) and Home — skipped (navigation only)

### Running Ingestion

```bash
# Incremental (only new/changed chunks, dedup by hash)
cd ~/optiply && python3.11 ingest_vault_v2.py incremental

# Full wipe + re-ingest
cd ~/optiply && python3.11 ingest_vault_v2.py full
```

## DB Schema

```sql
knowledge_chunks:
  id          uuid PK (gen_random_uuid)
  tenant_id   uuid FK → tenants(id)
  integration text
  category    text
  title       text
  section     text          -- NEW v2
  content     text NOT NULL
  embedding   vector(1536)
  source_path text          -- NEW v2
  content_hash text         -- NEW v2
  updated_at  timestamptz   -- NEW v2

Indexes: embedding (hnsw cosine), source_path, content_hash, integration, category
RLS: tenant_isolation policy
```

## Current Stats (Feb 24, 2026)

- **415 chunks** across 52 files
- 23 integration docs + 19 architecture/standards docs + operational docs
- Embedding model: `openai/text-embedding-3-small` (1536 dims) via OpenRouter

## Workflow: Obsidian → RAG Sync

1. Edit/create docs in Obsidian vault
2. Run `python3.11 ingest_vault_v2.py incremental`
3. New/changed chunks get embedded + inserted (hash-based dedup)
4. Aria queries RAG → gets chunks with `source_path` → reads full Obsidian doc if needed

## Service Management

```bash
# Managed by launchd
launchctl load ~/Library/LaunchAgents/ai.optiply.rag.plist
launchctl unload ~/Library/LaunchAgents/ai.optiply.rag.plist

# Server: rag_v2.py (FastAPI/uvicorn on :8000)
# Logs: ~/optiply/logs/rag.log, ~/optiply/logs/rag.error.log
```

## Links
- Server: [[Infrastructure]]
- Ingestion: `~/optiply/ingest_vault_v2.py`
- Retrieval: `~/optiply/rag_v2.py`
- DB: PostgreSQL 16 on localhost:5432
