---
tags: [crons, operations, autonomous]
updated: 2026-02-24
---

# Cron System — Autonomous Operations

> Aria runs 24/7 on a Mac Mini. Crons are her autonomous nervous system.

## Active Crons (11 total)

### High Frequency (Continuous Health)
| Cron | Schedule | Purpose | Alerts? |
|------|----------|---------|---------|
| `ops:service-health` | Every 4h | Check RAG, DB, Dashboard, Gateway | Only if down |
| `aria-heartbeat-6h` | Every 6h | General heartbeat (HEARTBEAT.md) | Only if issues |

### Daily Operations
| Cron | Schedule | Purpose | Alerts? |
|------|----------|---------|---------|
| `ops:kb-audit` | 06:00 | Verify KB chunk count, detect anomalies | If chunks dropped |
| `ops:repo-integrity` | 07:00 | Ensure Git repo clean + synced with remote | If dirty/behind |
| `ops:daily-digest` | 08:30 | Morning summary, update Handoff.md, flag blockers | ✅ Always announces |
| `memory:daily-log` | 22:00 | End-of-day log capture | No |
| `ops:vault-backup` | 00:00 | Push vault to GitHub repo | If drive unmounted |

### Weekly Maintenance
| Cron | Schedule | Purpose | Alerts? |
|------|----------|---------|---------|
| `memory:weekly-backup` | Sun 03:00 | Memory/workspace backup | No |
| `ops:memory-cleanup` | Sun 04:00 | Archive old daily notes, check vault size | If MEMORY.md bloated |
| `healthcheck:update-status` | Thu 09:00 | OpenClaw update check | If update available |
| `healthcheck:security-check` | Mon 09:00 | Security posture check | If issues found |

## Daily Timeline (Europe/Lisbon)
```
00:00  vault-backup         → Push vault to GitHub
03:00  memory:weekly-backup → Weekly backup (Sun only)
04:00  ops:memory-cleanup   → Archive old notes (Sun only)
06:00  ops:kb-audit         → Check KB integrity
07:00  ops:repo-integrity   → Check Git repo
08:30  ops:daily-digest     → Morning digest → announces to Jay
09:00  healthcheck          → Security (Mon) / Update (Thu)
~every 4h  service-health   → Check all services
~every 6h  heartbeat        → General health
22:00  memory:daily-log     → Capture day's events
```

## Alert Behavior
- **Silent when healthy**: Most crons reply HEARTBEAT_OK (suppressed)
- **Announce on issues**: Daily digest always announces. Others alert only on problems.
- **Self-healing**: Service health cron attempts restarts before alerting.

## Future Crons (once integrations are live)
- `ops:integration-monitor` — Check HotGlue job statuses every 6h
- `ops:sync-failure-alert` — Immediate alert on failed syncs
- `ops:stale-data-check` — Flag integrations with no sync >24h
