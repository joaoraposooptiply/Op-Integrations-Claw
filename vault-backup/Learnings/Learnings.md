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
- Use `profile=openclaw` for browser automation — NOT Chrome relay. Jay doesn't have the browser relay extension. OpenClaw managed browser is already logged into Confluence and works fine.
- MiniMax models were duplicated in both OpenRouter AND direct minimax providers. OpenRouter copy caused rate limits on wrong API. Fix: remove `minimax/*` models from openrouter provider in both `openclaw.json` and `agents/main/agent/models.json`. Direct provider uses `MiniMax-M2.5` (capital M, no prefix).
- Provider routing: Anthropic = direct, MiniMax = direct (api.minimax.io), everything else = OpenRouter.
