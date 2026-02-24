---
tags: [faq, support]
updated: 2026-02-24
---

# FAQ — Integrations

> Frequently asked questions from customers and the team. Updated continuously.

## General

### Q: How do I connect my e-commerce platform to Optiply?
A: Each platform has a specific setup process. Check the integration-specific docs in [[Projects/_Projects MOC|Integration Registry]].

### Q: How often does data sync?
A: Syncs are scheduled as HotGlue jobs. First sync pulls all historical data, subsequent syncs are incremental (new/updated records only).

### Q: What data does Optiply need from my platform?
A: Products, stock levels, sales orders, purchase orders, and suppliers. The specific fields depend on the integration.

### Q: Can I use the Optiply API directly?
A: Yes. See [[Optiply API]] for the full reference. Contact integrations@optiply.nl for API access.

---

## Technical

### Q: What is a tap/target?
A: Singer-spec connectors. A **tap** extracts data from your platform. A **target** writes data to Optiply. See [[HotGlue Architecture]].

### Q: What is a snapshot?
A: A cached copy of the last sync's data. Used to detect what's new, updated, or deleted since the last sync.

### Q: Why did my sync fail with a 401?
A: Your credentials expired or were revoked. Re-authenticate in HotGlue. See [[Troubleshooting Guide]].

---

*Add new Q&As as they come up.*
