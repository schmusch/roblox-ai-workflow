# Roblox AI-Workflow — Generic Agents Entry Point (Codex / others)

This file is the entry point for Codex CLI and any other agentic platform that reads `AGENTS.md`. The canonical skill content lives in `skills/<name>/SKILL.md` and is shared with Claude Code (`CLAUDE.md`) and Gemini CLI (`GEMINI.md`).

## How to use skills here

Skills are plain Markdown files with YAML frontmatter. There is no "Skill tool" required — read them directly, and follow the instructions as you would any prompt fragment.

When the user's request matches a skill's `description`, load that file and apply it. Skill names are namespaced `roblox-*` to avoid collision with other prompt libraries.

## Canonical workflow

```
roblox-brief  →  roblox-blueprint  →  roblox-forge
```

Skip phases only when the user's input already satisfies them. See `CLAUDE.md` for the full skill catalog with one-line descriptions.

## Roblox-native guardrails (always apply)

- **Server authority:** clients request, server validates, server mutates. Never trust client-sent payloads.
- **Roblox vocabulary:** prefer `ModuleScript`, `RemoteEvent`, `DataStoreService`, `CollectionService` over generic `Controller`/`Service`/`Repository`/`DTO`. See `references/roblox-vocabulary.md`.
- **Standard places:** `ServerScriptService` for authority logic, `ReplicatedStorage` for shared, `StarterPlayerScripts` for client-only, `StarterGui` for UI templates.
- **Verification:** evidence before assertions. Do not claim "done" from static inspection alone when runtime behavior depends on replication, remotes, or DataStore.

## MCP integrations

If the host platform has the Roblox Studio MCP configured, prefer its tools for direct Studio inspection / mutation. Otherwise, work from the codebase and ask the user to verify in Studio. See `references/studio-mcp-cheatsheet.md`.

## Operating defaults

- **Language:** Skill content is English (matches Roblox terminology). User's primary language is German — respond in German unless asked otherwise.
- **Platform:** Windows 11. Avoid POSIX-only commands.
- **No remote git operations** unless explicitly requested.

## Phase 2 skills (built — full SSOT parity)

Generic-but-portable workflow / quality skills are now available as `roblox-*` so Codex and other platforms without a native `superpowers:*` family get the same discipline:

| Need | Skill |
|------|-------|
| Deep requirements / brainstorming | `roblox-deep-interview` (deep) or `roblox-brief` (light) |
| TDD (red-green-refactor) | `roblox-tdd` |
| Multi-step plan with consensus loop | `roblox-plan` |
| Read-only codebase analysis | `roblox-analyze` |
| Doc-grounded research | `roblox-deepsearch` |
| Toolchain debugging (Rojo / Wally / Selene / Luau-LSP) | `roblox-build-fix` |
| Git workflow (Wally lock, Rojo manifest, place file) | `roblox-git-master` |
| Parallel sub-agents on independent slices | `roblox-team` |
| Long-running autonomous execution | `roblox-autopilot` |
| Extreme verification (monetization / persistence / PvP) | `roblox-ultrawork` |
| Code review with Roblox-specific gates | `roblox-code-review` |
| Exploit-vector security audit | `roblox-security-review` |
| Runtime verification before completion | `roblox-ultraqa` |
| Cross-LLM consultation | `roblox-ask-other-model` |
| PRD scaffold for a new feature | `roblox-forge-init` |
| **Roblox Epic & Story Scaffolding (BMAD)** | `roblox-scrum-create-epics` |
| **Agile SCRUM Planning (BMAD)** | `roblox-scrum-planning` |
| **Roblox Context-Rich Story Spec** | `roblox-scrum-create-story` |
| **TDD Story Dev in Roblox Studio** | `roblox-scrum-dev-story` |
| **Sprint Course Correction** | `roblox-scrum-correct-course` |
| **Sprint Retrospective** | `roblox-scrum-retrospective` |
| **Complete End-to-End Dev Cycle** | `roblox-scrum-dev-cycle` |

All skill content is platform-neutral; read the SKILL.md and follow the instructions directly.
