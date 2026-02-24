---
tags: [operations, resilience, infrastructure]
updated: 2026-02-24
---

# System Resilience — Shutdown & Recovery

> How Aria's stack behaves when the host laptop shuts down, sleeps, or disconnects.

## Host: Jay's Laptop (future: Mac Mini 24/7)

## What Happens on Shutdown/Sleep

| Component | On Shutdown | On Wake | Auto-Recovery? |
|-----------|------------|---------|----------------|
| OpenClaw Gateway | Stops | Auto-starts | ✅ Yes |
| Cron schedules | Persisted | Missed crons fire on wake | ✅ Yes (staggered) |
| PostgreSQL | Stops | Auto-starts (brew services) | ✅ Yes |
| RAG Server | Stops | Depends on launchd plist | ⚠️ Maybe — service-health cron catches in ≤4h |
| Dashboard | Stops | Manual or launchd | ⚠️ Maybe — service-health cron catches in ≤4h |
| Obsidian Vault | Inaccessible if drive unmounted | Needs drive reconnect | ⚠️ Manual — vault-backup cron alerts if missing |
| GitHub Repo | Always available (remote) | Always available | ✅ Yes |

## Recovery Order (automatic on wake)
1. **Gateway starts** → cron scheduler resumes
2. **PostgreSQL starts** → DB available (brew services)
3. **Missed crons fire** (staggered, in order)
4. **service-health cron** → checks all services within 4h
   - If RAG down → attempts restart
   - If DB down → alerts Jay
   - If Dashboard down → attempts restart
5. **vault-backup cron** → detects if drive unmounted, alerts Jay

## Safety Nets

### Data Loss Prevention
| Layer | Protection |
|-------|-----------|
| Obsidian Vault | On external drive + backed up to GitHub repo daily |
| Knowledge Chunks | In PostgreSQL (survives restart) |
| Code / Config | In GitHub repo |
| Session Memory | In MEMORY.md + workspace (on local disk) |
| Cron State | Persisted by OpenClaw gateway |

### If External Drive Fails
1. vault-backup cron detects unmounted drive → alerts Jay
2. Latest vault copy available in `Op-Integrations-Claw/vault-backup/` on GitHub
3. MEMORY.md in workspace serves as read-only fallback
4. Clone repo → restore vault from `vault-backup/` folder

### If RAG Server Won't Start
1. service-health cron detects it down
2. Attempts: `cd ~/optiply && python3.11 -m uvicorn rag:app --host 127.0.0.1 --port 8000 &`
3. If still fails → alerts Jay
4. Fallback: Aria uses vault knowledge directly (lower confidence, flagged)

### If PostgreSQL Won't Start
1. service-health cron detects it
2. Attempts: `brew services restart postgresql@16`
3. If still fails → alerts Jay
4. Impact: RAG retrieval down, KB audit fails, imports/exports affected

## Mac Mini Migration Notes
When moving to 24/7 Mac Mini:
- [ ] Set up auto-login on boot
- [ ] Configure launchd for RAG server + Dashboard auto-start
- [ ] Mount external drive on boot (fstab or login item)
- [ ] Verify brew services start on boot
- [ ] Test full power-cycle recovery
- [ ] Consider UPS for clean shutdown on power loss
- [ ] Set energy preferences: never sleep, wake on network access
