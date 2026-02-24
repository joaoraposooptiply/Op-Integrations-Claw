---
tags: [troubleshooting, support]
updated: 2026-02-24
---

# Troubleshooting Guide

> Common integration issues and fixes. Updated as we encounter and resolve problems.

## General

### Sync Not Running
**Check:** Is the HotGlue job scheduled and enabled?
**Check:** Are credentials still valid? (tokens expire)
**Fix:** Re-authenticate, then trigger manual sync

### 401 Unauthorized
**Cause:** Expired token, revoked access, wrong credentials
**Fix:** Re-authenticate the integration in HotGlue

### 429 Rate Limited
**Cause:** Too many API requests
**Fix:** Built-in backoff should handle this. If persistent, check rate limit settings.

### Data Missing After Sync
**Check:** Was the sync incremental? Check the state/bookmark.
**Check:** Does the source system have the data? (verify in source UI)
**Fix:** If bookmark is ahead of data, reset state and do full sync.

### Duplicate Records
**Cause:** Missing or incorrect deduplication in ETL
**Fix:** Check remoteId mapping in ETL notebook. Verify snapshot diff logic.

---

## Per-Integration Issues
*Added as issues are encountered and resolved.*

---

## Escalation Triggers
- Customer reports data loss or incorrect orders
- Auth failures not resolved in 2 turns
- Custom ERP configurations (SAP, Dynamics, NetSuite edge cases)
- Financial data discrepancies
