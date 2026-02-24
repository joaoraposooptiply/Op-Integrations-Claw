---
tags: [agents, infrastructure, config]
updated: 2026-02-24
---

# Agent Configuration

## Team Overview

| Agent | Role | Model | Provider |
|-------|------|-------|----------|
| **Aria 🔗** | Integration Lead + Orchestrator | claude-opus-4-6 | Anthropic (direct) |
| **Codex 🧠** | Integration Engineer (Builder) | qwen3.5-plus | OpenRouter |
| **Atlas 🔭** | API Researcher | grok-4.1-fast | OpenRouter |
| **Ingestor 📥** | Knowledge Base Sync | gemini-2.5-flash-lite | OpenRouter |

## Architecture

```
Jay (human)
  ↓ tasks, credentials, PR reviews
Aria 🔗 (Opus — orchestrator)
  ├── Codex 🧠 (qwen — builds code)
  ├── Atlas 🔭 (grok — researches APIs)
  └── Ingestor 📥 (gemini — syncs RAG)
  ↓ results
Obsidian Vault → RAG → All agents can query
```

**Key principle:** Aria makes the decisions (Opus-level reasoning), delegates bulk work to cheaper models. Small token volume on expensive model, large token volume on cheap models.

## Workspace Files

Each agent has a workspace with identity/context files:

| File | Purpose | Shared? |
|------|---------|---------|
| SOUL.md | Identity, role, rules, anti-patterns | Per agent |
| IDENTITY.md | Name, emoji, vibe | Per agent |
| MEMORY.md | Agent-specific operational context | Per agent |
| TOOLS.md | Available tools and commands | Per agent |
| AGENTS.md | Team structure and delegation rules | Shared (same file) |
| USER.md | About Jay | Shared (same file) |
| BOOTSTRAP.md | Session start protocol | Aria only |
| HEARTBEAT.md | Health check instructions | Per agent |

## Provider Routing

| Provider | Base URL | Models | Key |
|----------|----------|--------|-----|
| Anthropic | api.anthropic.com | opus, sonnet | auth profile |
| MiniMax | api.minimax.io/anthropic | M2.5, M2.1, Lightning | MINIMAX_API_KEY |
| OpenRouter | openrouter.ai/api/v1 | qwen, grok, gemini | sk-or-* |

⚠️ **MiniMax models removed from OpenRouter provider** (Feb 24) — was causing rate limits on wrong API. All MiniMax calls now go direct.

## Memory Flow

```
Agent learns something
  → Writes to Obsidian vault (/Volumes/Speedy/Obsidian/Op MindWave/)
  → Ingestor syncs vault → RAG (pgvector, localhost:8000)
  → All agents can query RAG for that knowledge
  → Agent-specific MEMORY.md for critical per-agent context
```

## Config Paths

| Config | Path |
|--------|------|
| Global config | `~/.openclaw/openclaw.json` |
| Agent list | `openclaw.json → agents.list[]` |
| Agent auth | `~/.openclaw/agents/{id}/agent/auth.json` |
| Agent models | `~/.openclaw/agents/{id}/agent/models.json` |
| Workspaces | `~/.openclaw/workspace-{name}/` |
| Aria workspace | `~/optiply-workspace/` (also the repo root) |

## Links
- [[Agent Team Proposal]] — full vision + phased rollout
- [[Model Stack]] — cost analysis
- [[Infrastructure]] — services
- [[Cron System]] — automated tasks
