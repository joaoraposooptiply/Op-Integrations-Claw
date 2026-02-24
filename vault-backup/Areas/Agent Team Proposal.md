---
tags: [agents, architecture, proposal]
updated: 2026-02-24
status: 📋 Draft v2
---

# Agent Team Proposal — Autonomous Integration Engineering

> The goal: an AI team that can receive an integration ticket, diagnose issues, fix bugs, build new integrations end-to-end, open PRs, and maintain documentation. Humans provide API credentials and review PRs. Everything else is autonomous.

## Vision: What "Done" Looks Like

**Scenario 1: Bug ticket comes in**
```
Jira: "Tenant 12345 — orders not syncing since yesterday, Shopify integration"
    ↓
Aria receives ticket → classifies as troubleshooting
    ↓
Aria checks: RAG for known Shopify issues, recent similar tickets
    ↓
Aria reads ETL logs (HotGlue webhook history, Slack #hotglue-webhooks)
    ↓
Identifies: Shopify changed their API response format for orders endpoint
    ↓
Codex: clones tap-shopify, identifies the breaking change, fixes streams.py
    ↓
Codex: runs tap --discover + test suite, verifies fix
    ↓
Codex: opens PR on tap-shopify with description of root cause + fix
    ↓
Aria: updates Shopify.md vault doc with the new quirk
    ↓
Aria: comments on Jira ticket with root cause + PR link
    ↓
Jay: reviews PR, merges, deploys to HotGlue
```

**Scenario 2: New integration request**
```
Jay: "New customer needs ChannelEngine integration. Here's the API docs URL
      and these credentials: api_key=xxx, merchant_id=yyy"
    ↓
Atlas: reads API docs, extracts full endpoint inventory, auth flow,
       pagination, rate limits, error codes, webhook support
    ↓
Atlas: outputs structured API reference → saved to vault
    ↓
Codex (parallel tasks):
  ├─ Build tap-channelengine (streams.py, tap.py, auth, tests)
  ├─ Build target-channelengine (sinks.py, target.py) if bidirectional
  └─ Build ETL notebook following Sherpaan Gold Standard
    ↓
Codex: runs full verification on each:
  ├─ pip install -e . ✓
  ├─ tap --discover → valid catalog ✓
  ├─ tap --config test.json → actual data flows ✓ (using provided credentials)
  ├─ ETL dry run with sample data ✓
  └─ target import test ✓
    ↓
Codex: opens PRs for tap + target + ETL
    ↓
Codex: generates Postman collection from tap endpoints
    ↓
Aria: creates full vault doc (Projects/Integrations/ChannelEngine.md)
      with sync board, config flags, mapping tables, API reference,
      ETL summary, target reference, quirks, testing checklist
    ↓
Ingestor: re-ingests vault → RAG updated
    ↓
Aria: reports to Jay — "ChannelEngine integration ready for review.
      3 PRs open. Docs + RAG updated. Test results attached."
    ↓
Jay: reviews PRs, tests with real tenant, deploys
```

**Scenario 3: Proactive maintenance**
```
Cron (weekly): Codex runs tap --discover on all 25 integrations
    ↓
Detects: Exact Online added new fields to Items endpoint
    ↓
Codex: updates tap-exact streams.py to include new fields
    ↓
Aria: updates Exact Online.md with new fields
    ↓
Aria: notifies Jay — "Exact added 3 new fields to Items. Updated tap + docs. PR open."
```

---

## The Team

### Aria 🔗 (Integration Lead)
**Model:** MiniMax-M2.5 (direct) | Complex: qwen3.5-plus
**Not a support bot. An integration lead who coordinates, diagnoses, and manages the full lifecycle.**

**Autonomous capabilities:**
- Receive and triage integration tickets (Jira, Slack, Telegram)
- Diagnose sync failures using: RAG knowledge, ETL logs, webhook history, tap error patterns
- Read HotGlue job status via webhook receiver logs
- Identify root cause patterns: auth expiry (401), rate limit (429), schema change, data quality, config mismatch
- Coordinate Codex/Atlas for fixes and builds
- Update vault docs after every change
- Track integration health across all 25+ tenants
- Generate incident reports with root cause analysis
- Manage knowledge base: vault + RAG sync, stale doc detection

**Needs from humans:**
- HotGlue admin access (deploy taps/targets)
- Customer credentials (API keys, OAuth consent)
- PR approval + merge
- Escalation decisions on financial data issues

---

### Codex 🧠 (Integration Engineer)
**Model:** qwen3.5-plus (via OpenRouter) | Complex: same
**The builder. Writes, tests, fixes, and PRs all integration code.**

**Autonomous capabilities:**

#### Building (new integrations)
- Generate complete Singer taps following [[Build Standards]]:
  - `hotglue_singer_sdk`, single `streams.py`, empty `__init__.py`
  - Auth handling (OAuth2 refresh, API key, Basic, SOAP, XML-RPC)
  - Pagination (cursor, offset, page, OData, async reports)
  - Rate limiting (backoff.expo, Retry-After, 429/503 handling)
  - `alerting_level = AlertingLevel.WARNING`
  - `_write_state_message` fix, `extra_retry_statuses`
  - INCREMENTAL on updated_at, FULL_TABLE fallback
- Generate Singer targets:
  - Entity sinks (buy orders, products, stock)
  - Proper HTTP methods per entity (POST create, PATCH update, DELETE)
  - Error handling per API (409 conflict, 404 not found, etc.)
- Generate ETL notebooks following [[Sherpaan Gold Standard]]:
  - Pydantic payload models via `utils.payloads`
  - Centralized CRUD via `utils.actions`
  - Hash-based snapshot change detection (`concat_attributes`)
  - Entity processing order: Products → Compositions → Suppliers → SupplierProducts → SellOrders → BuyOrders → BuyOrderLines → ReceiptLines
  - Config flag support, test mode, summary cell
- Generate Postman collections from tap endpoint inventory
- Run full verification checklist before reporting done

#### Fixing (bug tickets)
- Clone affected repo, read error context
- Identify root cause in tap/target/ETL code
- Write minimal fix (not refactor — fix the bug)
- Run tests to verify fix doesn't break anything
- Open PR with: root cause description, what changed, test results

#### Maintaining (proactive)
- Run `tap --discover` periodically to detect API schema changes
- Update streams.py when new fields appear
- Flag deprecated endpoints before they break

---

### Atlas 🔭 (API Researcher)
**Model:** grok-4.1-fast (via OpenRouter)
**Deep research agent. Turns "here's a website" into a complete API specification.**

**Autonomous capabilities:**
- Read API documentation sites (REST, GraphQL, SOAP, XML-RPC)
- Extract complete endpoint inventory with request/response schemas
- Identify auth flow: OAuth2 (which grant?), API key (header/query?), Basic, custom
- Map pagination pattern: cursor, offset, page number, link header, token
- Document rate limits: per-endpoint, global, burst, daily caps
- Find error codes and retry behavior
- Identify webhook/realtime capabilities
- Find sandbox/test environments
- Generate Postman-compatible collection JSON
- Output structured markdown matching vault integration template

**Input:** API docs URL + any notes from Jay
**Output:** Complete API reference doc ready for vault + Codex consumption

---

### Ingestor 📥 (Knowledge Sync)
**Model:** gemini-2.5-flash-lite (via OpenRouter)
**Keeps RAG synchronized with vault. Runs automatically.**

**Autonomous capabilities:**
- Incremental vault → RAG sync (hash-based dedup)
- Section-level chunking (## headings)
- Metadata tagging (integration, category, source_path)
- Stale chunk detection and cleanup
- Stats reporting

---

## What's Missing for Full Autonomy

These are the gaps between "AI assistant" and "AI integration engineer":

### Gap 1: Ticket Intake
**Current:** Aria only responds when talked to via Telegram/webchat.
**Needed:** Aria monitors Jira/Slack for new integration tickets automatically.
**Solution:**
- Jira webhook → OpenClaw → Aria receives ticket context
- Slack bot monitoring `#hotglue-webhooks` and `#integrations`
- Or: cron that polls Jira API for new tickets assigned to integrations team

**Effort:** Medium — needs Jira API integration or webhook setup

### Gap 2: Log Access
**Current:** Can't see HotGlue job logs or webhook history.
**Needed:** Read ETL execution logs to diagnose failures.
**Solution options:**
- A. HotGlue API access (if they expose job logs via API)
- B. Read webhook receiver logs (Flask service stores 30 days)
- C. Read Slack `#hotglue-webhooks` messages (already has failure alerts)
- D. Database query for tenant sync status

**Effort:** Low-Medium — webhook receiver logs are most accessible

### Gap 3: Git Workflow
**Current:** Codex can write code but PR workflow isn't set up.
**Needed:** Clone repo → branch → commit → push → open PR → link to ticket.
**Solution:**
- Use `gh` CLI (already installed) for PR creation
- Branch naming: `fix/{ticket-id}-{description}` or `feat/{integration-name}`
- PR template with: root cause, changes, test results, vault doc updates

**Effort:** Low — just needs a standardized workflow script

### Gap 4: Testing with Real Credentials
**Current:** Can run `tap --discover` but can't test with real API calls without credentials.
**Needed:** Test with actual API to verify data flows correctly.
**Solution:**
- Jay provides credentials per integration in a secure config
- Store in `~/optiply-integrations/{integration}/config.json` (gitignored)
- Codex runs `tap --config config.json | head -100` to verify real data

**Effort:** Low — just credential management

### Gap 5: HotGlue Deployment
**Current:** Can't deploy taps/targets to HotGlue production.
**Needed:** Upload built tap/target to HotGlue environment.
**Solution options:**
- A. HotGlue CLI (`hotglue push`) — if available
- B. API upload — if HotGlue exposes deployment API
- C. **Stay manual** — Jay deploys after PR review (safest for now)

**Effort:** Unknown — depends on HotGlue capabilities. Recommend staying manual initially.

### Gap 6: Tenant Config Access
**Current:** Can't read or modify customer tenant configurations.
**Needed:** Check config flags when debugging ("is `pullAllOrders` set to true?").
**Solution:**
- Read-only access to tenant configs via HotGlue API or database query
- Never modify without human approval
- Could build a simple read-only API endpoint that queries tenant config

**Effort:** Medium — needs API or DB access setup

### Gap 7: Postman Collection Generation
**Current:** Can read Postman collections but can't generate them from tap code.
**Needed:** Auto-generate Postman collection for any tap.
**Solution:**
- Script that reads `streams.py` → extracts endpoints, methods, params → outputs collection JSON
- Codex can build this as a one-time tool

**Effort:** Low — one script

---

## Phased Rollout

### Phase 1: Knowledge + Support (NOW — we're here)
- [x] Full knowledge base (564 chunks, 63 vault docs)
- [x] RAG v2 with Obsidian backlinks
- [x] All source code analyzed
- [x] Gold standard documented
- [ ] Auto-sync cron (vault → RAG)
- [ ] Test: 10 support queries, measure accuracy
- **Aria can:** Answer integration questions, point to docs, escalate

### Phase 2: Bug Fixing (Next 1-2 weeks)
- [ ] Git workflow setup (branch → commit → PR via `gh`)
- [ ] Log access (webhook receiver logs or Slack)
- [ ] Codex builds test tap from scratch (quality validation)
- [ ] PR template standardized
- [ ] Test: give Codex a real bug, measure fix quality
- **Aria + Codex can:** Diagnose issues, fix tap/target/ETL bugs, open PRs

### Phase 3: New Integration Building (2-4 weeks)
- [ ] Atlas tested on 3 unknown APIs
- [ ] Codex builds complete integration from Atlas output
- [ ] Postman collection generation script
- [ ] Testing with real credentials workflow
- [ ] Full end-to-end test: API docs in → working integration out
- **Full team can:** Build new integrations from API docs + credentials

### Phase 4: Full Autonomy (1-2 months)
- [ ] Jira ticket intake (webhook or polling)
- [ ] Slack monitoring for alerts
- [ ] Tenant config read access
- [ ] Proactive API change detection cron
- [ ] Mac Mini 24/7 deployment
- **Full team can:** Receive tickets, diagnose, fix, build, PR, document — end to end

---

## Cost Model (Phase 4 Steady State)

| Agent | Model | Monthly Tokens (est.) | Cost |
|-------|-------|--------------------|------|
| Aria | MiniMax-M2.5 (direct) | ~30M in / 5M out | ~$14.50 |
| Codex | qwen3.5-plus | ~8M in / 2M out | ~$8.00 |
| Atlas | grok-4.1-fast | ~3M in / 1M out | ~$3.60 |
| Ingestor | gemini-flash-lite | ~2M in / 0.5M out | ~$0.40 |
| Crons | gemini-flash-lite | ~1M in / 0.2M out | ~$0.18 |
| Escalation (Opus) | anthropic/opus | ~1M in / 0.2M out | ~$18.00 |
| Embeddings | text-embedding-3-small | ~0.5M tokens | ~$0.01 |
| **Total** | | | **~$45/mo** |

Previous estimate was inflated. With MiniMax direct (free caching on coding plan), proper routing, and realistic usage patterns, this is well under €100.

**Where the money goes:**
- 32% — Opus (rare, complex escalations only)
- 32% — Aria daily operations
- 18% — Codex building/fixing
- 8% — Atlas research
- 10% — everything else

---

## Infrastructure (No Changes Needed)

| Service | Port | RAM | Purpose |
|---------|------|-----|---------|
| PostgreSQL 16 | 5432 | ~60MB idle | pgvector RAG + knowledge |
| RAG v2 (uvicorn) | 8000 | ~30MB idle | Embedding retrieval |
| Dashboard (uvicorn) | 3001 | ~30MB idle | Backend API |
| OpenClaw gateway | 18789 | ~50MB idle | Agent orchestration |
| **Total** | | **~170MB** | Runs fine on 16GB, overkill on Mac Mini |

All compute is API-based. Local machine just runs lightweight orchestration.

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Codex writes buggy code | Medium | Verification checklist mandatory. Jay reviews all PRs. |
| Wrong diagnosis on ticket | Medium | Confidence scoring. Escalate if < 80%. Never auto-deploy. |
| API change breaks tap | High | Weekly `--discover` cron catches schema drift early |
| Cost spike from runaway agents | Medium | 3-strike loop breaker. 300s timeout on all spawns. |
| Hallucinated API endpoints | High | Atlas must cite source URL. Codex must test with real API. |
| Stale knowledge base | Low | Auto-sync cron + weekly stale doc check |
| MiniMax rate limits | Low | Fixed — now using direct provider. Batch sub-agents max 2. |

---

## Success Metrics

| Metric | Phase 2 Target | Phase 4 Target |
|--------|---------------|----------------|
| Support query accuracy | 70% resolved without human | 90% |
| Bug fix time (ticket → PR) | < 2 hours | < 30 min |
| New integration build time | N/A | < 1 day (was 3-5 days manual) |
| False escalation rate | < 30% | < 10% |
| Knowledge base freshness | Updated same-day | Updated within 1 hour |
| Cost per integration | N/A | < $5 |

---

## Next Steps (Immediate)

1. **Set up auto-sync cron** (vault → RAG, every 6 hours)
2. **Set up vault backup cron** (vault → GitHub, daily)
3. **Test support accuracy** — run 10 real integration questions through Aria
4. **Test Codex build quality** — have Codex build a tap from scratch
5. **Set up git workflow** — branch/commit/PR script for Codex
6. **Move to Mac Mini** when ready for 24/7

## Links
- [[Model Stack]] — provider routing
- [[Cron System]] — existing crons
- [[Infrastructure]] — services
- [[Build Standards]] — Codex follows these
- [[Sherpaan Gold Standard]] — ETL template
- [[Generic Data Mapping]] — entity schemas
- [[Functional Requirements]] — integration checklist
