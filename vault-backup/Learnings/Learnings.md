---
tags: [learnings, rules, append-only]
updated: 2026-02-24
---

# 🧠 Learnings — Rules From Mistakes

> One-line rules learned from errors. Append-only. This compounds into an operations manual.

---

## Feb 24, 2026
- Sub-agents need EXACT filenames — "Exact Online.md" not "Exact.md". Always verify file exists before delegating.
- Old Python processes linger on ports after launchd unload — always `kill` by PID before rebinding.
- RLS policy blocks ALL queries without `SET app.tenant_id` — include in every DB function, including health/stats.
- Section-level chunking (## headings) >> arbitrary 800-char splits for RAG quality.
- Embed with context prefix (`title > section: content`) for better semantic match.
