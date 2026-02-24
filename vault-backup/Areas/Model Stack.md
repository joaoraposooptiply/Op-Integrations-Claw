---
tags: [ai, models, config]
updated: 2026-02-24
---

# Model Stack

| Agent | Model | $/M in/out | Use Case |
|-------|-------|------------|----------|
| main (Aria) | minimax-m2.5 | $0.30/$1.10 | Coordination, support |
| codex | qwen/qwen3.5-plus-02-15 | $0.40/$2.40 | Code generation |
| atlas | grok-4.1-fast | $0.40/$2.40 | Research, API docs |
| ingestor | gemini-2.5-flash-lite | $0.10/$0.40 | KB ingestion |
| crons | gemini-2.5-flash-lite | $0.10/$0.40 | Health checks |
| complex | qwen/qwen3.5-plus-02-15 | $0.40/$2.40 | Multi-turn, ERP |
| anthropic | Manual override only | $15/$75 | Last resort |

## Fallbacks
| Primary | Fallback |
|---------|----------|
| qwen3.5-plus | grok-4.1-fast |
| grok-4.1-fast | gemini-2.5-flash |
| minimax-m2.5 | gemini-2.5-flash |

## Banned (for coding)
- minimax-m2-1 — dead, 0/4
- llama-3.1-8b-instruct — too low quality
- openrouter/anthropic/* — never route Anthropic through OpenRouter
