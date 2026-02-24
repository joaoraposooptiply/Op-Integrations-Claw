---
tags: [hotglue, onboarding, runbook]
updated: 2026-02-24
source: https://optiply.atlassian.net/wiki/spaces/IN/pages/2288812043
---

# Connect New Tenant

> Steps to connect a new tenant (customer) to HotGlue after their store is created in Optiply.

## Prerequisites
- Store created in Optiply (OP)
- All needed data from the customer collected

## Steps

### 1. Connect Tenant Config
Connect tenant to dev or prod environment.

**API call:** `PUT {{hotglue_base_url}}tenant/{{hotglue_env_id}}{{tenant_id}}/config`

Body: tenant configuration JSON (varies per integration)

### 2. Link Sources
Link the tap (source) for the integration.

**API call:** `POST {{hotglue_base_url}}{{hotglue_env_id}}{{sources_id}}/{{tenant_id}}/linkedSources`

Body example (Montapacking):
```json
{
  // Integration-specific source config
}
```

### 3. Connect Target
Link the target for the integration (e.g., target-optiply).

Details: varies by integration.

## Environment URLs
- **Production:** `production.hotglue.optiply.nl`
- **Development:** `dev.hotglue.optiply.nl`

## Flow IDs
- E-commerce flow: `p6BFCREDz`

## Links
- [[HotGlue Architecture]] — environment + flow structure
- [[HotGlue Redirect Service]] — proxy API for frontend
- [[Webhook Receiver]] — handles post-connection webhooks
- [[Functional Requirements]] — what to decide before connecting
