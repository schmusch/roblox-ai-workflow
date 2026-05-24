# Roblox AI-Workflow — Gemini CLI Entry Point

This workspace is a **Single Source of Truth (SSOT)** for AI-assisted Roblox game development. The canonical skill content lives in `skills/<name>/SKILL.md` and is shared with Claude Code (`CLAUDE.md`) and Codex / generic agents (`AGENTS.md`).

## Skill activation

Use the `activate_skill` tool to load a skill from `skills/<name>/SKILL.md`. Skill frontmatter follows the Anthropic Skill convention (`name`, `description`) which Gemini CLI's skill loader supports.

If `activate_skill` is unavailable for any reason, read the skill file directly and follow its instructions.

## Tool name mapping (Claude Code → Gemini equivalents)

Skills are written in platform-neutral language. Where they reference generic actions, use the Gemini equivalent:

| Generic action in skill | Gemini CLI tool |
|-------------------------|-----------------|
| "read the file" | `read_file` |
| "edit the file" | `replace` / `write_file` |
| "search the codebase" | `search_file_content`, `glob` |
| "run the command" | `run_shell_command` |
| "use available Roblox Studio integration" | `mcp__Roblox_Studio__*` (if configured) |
| "fetch up-to-date docs" | `web_fetch`, context7 MCP if available |

See `CLAUDE.md` for the full skill catalog, Roblox-native guardrails, and operating defaults — those apply identically here.

## Operating defaults

- **Language:** Skill content is English. User chats in German — respond in German unless asked otherwise.
- **Platform:** Windows 11. Avoid POSIX-only commands.
- **Server authority is not optional.** Clients request, server validates, server mutates.

## Companion skills

The SSOT now has **full Phase-2 parity** — generic workflow / quality discipline that Claude Code gets from `superpowers:*` is available here as portable `roblox-*` skills:

| Need | Skill |
|------|-------|
| Deep requirements / brainstorming | `roblox-deep-interview` (deep) or `roblox-brief` (light) |
| TDD (red-green-refactor) | `roblox-tdd` |
| Multi-step plan with consensus loop | `roblox-plan` |
| Read-only codebase analysis | `roblox-analyze` |
| Doc-grounded research | `roblox-deepsearch` |
| Toolchain debugging (Rojo/Wally/Selene/Luau-LSP) | `roblox-build-fix` |
| Git workflow (Wally lock, Rojo manifest, place file) | `roblox-git-master` |
| Parallel sub-agents | `roblox-team` |
| Long-running autonomous execution | `roblox-autopilot` |
| Extreme verification (monetization / persistence / PvP) | `roblox-ultrawork` |
| Code review with Roblox-specific gates | `roblox-code-review` |
| Exploit-vector security audit | `roblox-security-review` |
| Runtime verification before completion | `roblox-ultraqa` |
| Cross-LLM consultation | `roblox-ask-other-model` |
| PRD scaffold for a new feature | `roblox-forge-init` |
| **Agile SCRUM Planning (BMAD)** | `roblox-scrum-planning` |
| **Roblox Context-Rich Story Spec** | `roblox-scrum-create-story` |
| **TDD Story Dev in Roblox Studio** | `roblox-scrum-dev-story` |
| **Sprint Course Correction** | `roblox-scrum-correct-course` |
| **Sprint Retrospective** | `roblox-scrum-retrospective` |

Skill content is identical across platforms — only the tool invocations differ (see the tool-mapping table above).
