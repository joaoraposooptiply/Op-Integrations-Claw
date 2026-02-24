---
tags: [infrastructure, hotglue, webhooks]
updated: 2026-02-24
source: https://optiply.atlassian.net/wiki/spaces/IN/pages/2299494415
---

# HotGlue Webhook Receiver

> Flask (Python) service that handles HotGlue webhook events. Adds business logic on top of HotGlue's job lifecycle.

Reference: [HotGlue Webhook Lifecycle](https://docs.hotglue.com/docs/jobs-lifecycle)

## Features

### Job Failure Handling
- When a job fails → **send Slack message** to `#hotglue-webhooks`

### Job Success Handling (auto_sync / full_sync)
When a job completes successfully for `sync_type: auto_sync` or `full_sync`:
1. **Enable scheduler** for that tenant (confirmed via Slack message)
2. Check if need to **link to a target** → if so, also turn target scheduler on
3. **Trigger a job** when a link is done:
   - Checks: tenant config valid? state is null?
   - If both true → trigger job
   - Job name format: `wh-{flow_id}-{tap}-{date}`

### Incremental Sync Special Cases
When a job succeeds for `incremental_sync` AND:
- Job name contains `"full sync"` or `"62112121925143"` (encoded "fullsync": f=6, u=21, l=12, etc.)
- Job name does NOT contain `"971415185"` (encoded "ignore")

Then:
1. Enable scheduler for that tenant
2. Check if need to link to target → turn on target scheduler

### Exact Online: 401 Handling
When a job fails with `requests.exceptions.HTTPError: 401 Client Error: Unauthorized for url: https://start.exactonline.nl/api/oauth2/token`:
- **Turn off schedulers** for that tenant

### Exact Online: Buy Order Export Failures
When an export fails because there was an error sending a BO to Exact:
- **Slack message** with error details and how many BOs failed
- (Waiting for HotGlue to add BO ID to the report)

### Config Validation
- Checks if tenant config is valid
- If not → **sends Slack message**

### Webhook Logging
- Logs all incoming webhooks
- Data retained for **30 days**

## Encoding Scheme
Used to hide strings from frontend display:
- Each letter → its position number: a=1, b=2, c=3, ..., z=26
- `"fullsync"` → `62112121925143`
- `"ignore"` → `971415185`

## Links
- [[HotGlue Architecture]] — overall HotGlue setup
- [[HotGlue Redirect Service]] — proxy API
- [[Troubleshooting Guide]] — common webhook issues
