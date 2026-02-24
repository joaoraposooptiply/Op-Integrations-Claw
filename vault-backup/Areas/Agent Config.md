---
tags: [ai, agents, config]
updated: 2026-02-24
---

# Agent Config

> See AGENTS.md in workspace for full config. This is the human-readable summary.

## Agents

| Agent | Role | Default Model |
|-------|------|---------------|
| Aria 🔗 | Integration Support Lead + Coordinator | minimax-m2.5 |
| Codex 🧠 | Integration Builder (code gen) | qwen/qwen3.5-plus-02-15 |
| Atlas 🔭 | API Researcher | grok-4.1-fast |
| Ingestor 📥 | Knowledge Base Builder | gemini-2.5-flash-lite |

## Routing
- Simple FAQ → Aria (flash)
- Code generation → Codex
- API research → Atlas
- KB ingestion → Ingestor
- Complex/ERP → Aria escalated to qwen3.5-plus

## Rules
- Sub-agents inherit parent model — always specify model in spawn
- Max 2 concurrent Codex spawns
- 3-strike loop breaker on failures
- Cost target: <€100/month
