# Roblox AI-Workflow

A Single-Source-of-Truth (SSOT) skill set for AI-assisted Roblox game development across **Claude Code**, **Gemini CLI**, and **Codex** / generic agents.

Inspired by [JustineDevs/roblox-ai-os (RCS)](https://github.com/JustineDevs/roblox-ai-os) — the workflow concepts, psychology framework, and Roblox-native guardrails are adapted to Claude Code's native skill system and made platform-portable.

## Structure

```
.
├── CLAUDE.md           # Claude Code entry point
├── GEMINI.md           # Gemini CLI entry point
├── AGENTS.md           # Codex / generic entry point
├── README.md           # this file
│
├── skills/             # SSOT — 36 Roblox-focused skills (Phase 1 + Phase 2)
├── references/         # shared docs (vocabulary, psychology, server-authority, etc.)
├── docs/               # design specs
├── plans/              # implementation plans (incl. Phase 2)
└── roblox-ai-os/       # the cloned upstream RCS repo (inspiration source)
```

## Quick start

### In Claude Code

1. `cd "G:\Meine Ablage\Projekte\GameDev\Roblox\AI-Workflow"` — Claude Code auto-loads `CLAUDE.md`
2. Start with a request like *"Hilf mir, ein Tycoon-Spiel zu planen"* — Claude will invoke `roblox-brief` then `roblox-blueprint`.

### In Gemini CLI

1. `cd` to the same workspace — Gemini reads `GEMINI.md`
2. Use `activate_skill` with a name from the catalog, or describe the task and Gemini will pick the matching skill.

### In Codex / other agents

1. Point the agent at `AGENTS.md`.
2. Skills are plain Markdown — the agent reads them directly.

## What's in Phase 1 (built)

21 Roblox-specific skills covering: creator brief, Roblox-native planning, Studio-MCP execution, the 5-driver player-psychology framework (progression / status / FOMO / mastery / community), three reward-loop types (reward, daily, event), social mechanics, retention design, anti-slop (enterprise-jargon removal), visual verification, the pre-action gate, and Studio-MCP integration patterns.

See `CLAUDE.md` for the full catalog with one-line descriptions of each.

## What's in Phase 2 (built)

15 portable workflow / quality skills that bring SSOT parity to Gemini CLI and Codex (which don't ship the `superpowers:*` family):

- **Process & planning:** `roblox-deep-interview`, `roblox-plan`, `roblox-analyze`, `roblox-deepsearch`, `roblox-tdd`, `roblox-build-fix`, `roblox-git-master`, `roblox-forge-init`, `roblox-ask-other-model`
- **Multi-agent execution:** `roblox-team`, `roblox-autopilot`, `roblox-ultrawork`
- **Quality lanes:** `roblox-code-review`, `roblox-security-review`, `roblox-ultraqa`

Plus 3 new reference docs: `references/roblox-test-patterns.md`, `references/roblox-security-audit-checklist.md`, `references/roblox-build-toolchain.md`.

Total skill count: **36**. See `CLAUDE.md` for the full catalog.

## Design principles

- **Server authority is non-negotiable** — clients request, server validates, server mutates.
- **Roblox vocabulary over enterprise jargon** — `RemoteEvent`, not `Controller`. `ModuleScript`, not `Repository`. `DataStoreService`, not `database`.
- **Evidence before assertions** — never claim "done" from static inspection when behavior depends on replication / remotes / DataStore.
- **Psychology backward from player desire** — design loops from what the player actually wants, not from feature lists.
- **Platform-neutral skill content** — skill instructions don't name specific tools so they work in Claude Code, Gemini CLI, and Codex.

## Source attribution

The conceptual vocabulary, psychology framework, and pre-action protocol are derived from the [RCS project (MIT-licensed)](https://github.com/JustineDevs/roblox-ai-os) by [@JustineDevs](https://github.com/JustineDevs). This workspace is a Claude-Code-first reinterpretation; it does not bundle, re-publish, or claim authorship of RCS itself.
