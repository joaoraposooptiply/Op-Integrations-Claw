---
tags: [runbook, operations]
updated: 2026-02-24
---

# Runbooks

## RAG Server

### Start RAG Server
```bash
# Preferred (python3.11, not the broken plist)
cd ~/optiply && python3.11 -m uvicorn rag:app --host 127.0.0.1 --port 8000
```

### Restart RAG Server
```bash
# Kill existing
lsof -ti:8000 | xargs kill -9 2>/dev/null
# Restart
cd ~/optiply && python3.11 -m uvicorn rag:app --host 127.0.0.1 --port 8000 &
```

### Verify RAG
```bash
curl -s -X POST http://127.0.0.1:8000/retrieve \
  -H "Content-Type: application/json" \
  -d '{"query":"test","tenant_id":"00000000-0000-0000-0000-000000000001"}' | head -c 200
```

## Database

### Check Chunk Count
```bash
PGPASSWORD='SOB0vuUradBgb1zWMqLddQQOa_xy_TITjA-c5dK72Iw' \
  psql -h 127.0.0.1 -U optiply_app -d optiply_ai \
  -c "SELECT COUNT(*) FROM knowledge_chunks;"
```

### Wipe All Chunks
```bash
PGPASSWORD='...' psql -h 127.0.0.1 -U optiply_app -d optiply_ai \
  -c "TRUNCATE knowledge_chunks;"
```

## Ingest Knowledge
```bash
cd ~/optiply && python3.11 ingest.py --source <file> --integration <name>
```

## OpenClaw

### Check Status
```bash
openclaw status
```

### Restart Gateway
```bash
openclaw gateway restart
```

### Update
```bash
sudo npm update -g openclaw
```

### Doctor
```bash
openclaw doctor --fix
```
