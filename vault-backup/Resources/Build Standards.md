---
tags: [standards, build, reference]
updated: 2026-02-24
---

# Build Standards

> How we build taps, targets, and ETL notebooks. Every integration follows this.

## Per Integration Deliverables
1. **Tap** — extracts data from source system
2. **Target** — writes data to Optiply API
3. **ETL Notebook** — transforms tap output → Optiply entities
4. **Docs** — setup guide + troubleshooting + KB chunks

## Tap Requirements
- SDK: `hotglue_singer_sdk` (NEVER standard `singer_sdk`)
- Single `streams.py` file (NEVER `streams/` directory)
- `__init__.py` files must be EMPTY
- `alerting_level = AlertingLevel.WARNING`
- `InvalidCredentialsError` on 401
- Backoff decorator on all API calls
- `extra_retry_statuses` for transient errors
- Retry-After header handling
- 404/204 grace (don't crash on empty responses)
- `_write_state_message` fix must be present
- Replication: INCREMENTAL on updated_at where available, FULL_TABLE fallback
- Config schema must include: `api_url`, `access_token`, `start_date`

## Target Requirements
- SDK: `hotglue_singer_sdk`
- `alerting_level = AlertingLevel.WARNING`
- Maps Singer records to Optiply API entities
- Handles: create, update, delete operations
- Error handling: 401 → InvalidCredentialsError, 429 → backoff, 5xx → retry

## ETL Notebook Requirements
- Follows canonical template structure
- All Optiply entity mappings present (remoteId, skuCode, etc.)
- Snapshot diff logic (new/update/delete detection)
- Summary cell at end with counts

## Verification Checklist
### Tap
- [ ] `pip install -e .` succeeds
- [ ] `tap --config config.json --discover` produces valid JSON with `streams[]`
- [ ] Import test passes
- [ ] No TODOs or placeholders

### Target
- [ ] `pip install -e .` succeeds
- [ ] Import test: `python3.9 -c "from target_X.target import TargetX; print('OK')"`
- [ ] Write test with sample records

### ETL
- [ ] All entity mappings present
- [ ] Snapshot diff works
- [ ] Summary cell outputs counts

## Commit Convention
- Repo: `~/optiply-integrations/`
- Message: `"AI-generated [integration] tap/target"`

## Reference Implementation
- [[Sherpaan Gold Standard]] — the canonical ETL notebook all integrations should follow
