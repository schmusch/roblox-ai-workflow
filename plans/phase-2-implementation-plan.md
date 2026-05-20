# Phase 2 — Generic SSOT Skills Implementation Plan

**Status:** ✅ delivered on 2026-05-20. 15 skills built (after consolidations), 3 new reference docs added, entry-point files updated. See the final skill list in `CLAUDE.md`. This document is kept for historical context.

## Why Phase 2 exists

Claude Code already ships excellent versions of generic workflow skills via `superpowers:*`, `anthropic-skills:*`, and built-in commands (`/review`, `/security-review`, `/init`). Phase 1 deliberately doesn't reimplement them as `roblox-*` skills because doing so adds maintenance with no benefit on Claude Code.

**Phase 2 ships these as portable `roblox-*` skills so that Gemini CLI and Codex (which don't have the `superpowers:*` family) get the same disciplined workflow in the SSOT.**

If you only ever use Claude Code, Phase 2 is optional. If you use Gemini / Codex seriously for Roblox work, build Phase 2.

## Scope (23 skills)

### Workflow process skills (8)
| Skill | Equivalent | Notes |
|-------|-----------|-------|
| `roblox-tdd` | `superpowers:test-driven-development` | TestEZ / Jest-Roblox idioms; adapt the red-green-refactor cycle to Luau |
| `roblox-deep-interview` | `superpowers:brainstorming` (deeper) | Socratic requirements gathering for complex briefs |
| `roblox-plan` | `superpowers:writing-plans` | Multi-step implementation plans with consensus loop |
| `roblox-analyze` | `Explore` agent + general-purpose | Read-only deep analysis with ranked synthesis |
| `roblox-deepsearch` | context7 + `Explore` | Doc-grounded research via Roblox Creator Docs + Wally registry |
| `roblox-autoresearch` | similar to `roblox-deepsearch` but autonomous | Background-research routine |
| `roblox-build-fix` | `superpowers:systematic-debugging` (Roblox-flavored) | Specific to Rojo / Wally / Luau LSP / Selene failures |
| `roblox-git-master` | built-in git via Bash | Roblox-aware git workflows (Wally lock files, rojo manifests) |

### Multi-agent / orchestration (5)
| Skill | Equivalent | Notes |
|-------|-----------|-------|
| `roblox-team` | `superpowers:dispatching-parallel-agents` + `subagent-driven-development` | Coordinated parallel agents on independent slices |
| `roblox-crew` | similar to `roblox-team`, RCS uses both | Could merge into `roblox-team` |
| `roblox-swarm` | many parallel single-task agents | Useful for batch refactors |
| `roblox-worker` | sub-role of `roblox-team` | Worker role for orchestrated work |
| `roblox-autopilot` | `roblox-forge` with autonomy turned up | Long-running autonomous execution |

### Quality lanes (5)
| Skill | Equivalent | Notes |
|-------|-----------|-------|
| `roblox-code-review` | `superpowers:requesting-code-review`, `/review` | Roblox-flavored: server-authority audit, anti-slop pass, replication audit |
| `roblox-security-review` | `/security-review` | Roblox-flavored: exploit-vector audit (remotes, persistence, trade) |
| `roblox-review` | meta-review (process review) | Review of work artifacts, not code |
| `roblox-ultraqa` | `superpowers:verification-before-completion` | Roblox-specific: in-Studio runtime proofs |
| `roblox-ultrawork` | `roblox-forge` with extreme verification | Combined exec + ultra-verify loop |

### Misc (5)
| Skill | Equivalent | Notes |
|-------|-----------|-------|
| `roblox-autoforge` | `roblox-brief` → `roblox-blueprint` → `roblox-forge` automated | End-to-end automation skill |
| `roblox-ai-slop-cleaner` (generic) | RCS's `ai-slop-cleaner` | Already partly covered by `roblox-anti-slop`; this is the **non-Roblox-specific** generic version for general code |
| `roblox-forge-init` | RCS PRD scaffold | Creates a PRD doc structure for a feature |
| `roblox-web-clone` | scaffold from web reference | Clone a UI / feature seen on the web; rare use |
| `roblox-ask-other-model` | RCS's `ask-claude` / `ask-gemini` | Cross-LLM query — only useful when running multi-model |

## Implementation order (when picking this up)

1. **Quality lane first** (highest immediate value): `roblox-code-review`, `roblox-security-review`, `roblox-ultraqa`.
2. **Workflow skills next**: `roblox-tdd`, `roblox-plan`, `roblox-build-fix`.
3. **Multi-agent if used**: `roblox-team` (merge crew / swarm if not needed separately).
4. **Misc last**: as needs arise.

## Skip / merge recommendations

- **Skip:** `roblox-crew` (merge into `roblox-team`), `roblox-swarm` (rare use), `roblox-worker` (sub-role, not a skill).
- **Skip:** `roblox-web-clone` (niche; ask-on-demand instead).
- **Merge:** `roblox-autoforge` is just the workflow backbone in sequence — can be a doc page, not a skill.
- **Merge:** `roblox-ai-slop-cleaner` (generic) into `roblox-anti-slop` with a `--generic` flag mention in the skill.

Realistic Phase 2 target: **~15 skills** after merges + skips, not 23.

## Per-skill template

Each Phase 2 skill follows the same SKILL.md frontmatter shape as Phase 1:

```yaml
---
name: roblox-<skill>
description: <when to use, 1 sentence>
domain: roblox-studio   # or process / quality
audience: creator
artifact-type: skill
---
```

Body sections:
- When to use
- When not to use
- What this skill produces
- Method
- Anti-pattern checks
- Roblox-specific framing
- Handoff

Keep length ~100–200 lines; deeper detail goes in `references/`.

## References to extend

Phase 2 should add:
- `references/roblox-test-patterns.md` — TestEZ / Jest-Roblox idioms, mocking Roblox APIs
- `references/roblox-security-audit-checklist.md` — exploit-vector audit (used by `roblox-security-review`)
- `references/roblox-build-toolchain.md` — Rojo + Wally + StyLua + Selene workflow patterns

## Effort estimate

- ~15 skills × ~120 lines = ~1800 lines of skill content
- 3 new reference docs × ~150 lines = ~450 lines
- One fresh session can handle this comfortably with context to spare.

## Entry-point updates after Phase 2

After Phase 2 ships, update:
- `CLAUDE.md` — move Phase 2 skills out of the "not yet built" section into the catalog.
- `GEMINI.md` — update the "companion skills" note (the gap is closed).
- `AGENTS.md` — same.
- `README.md` — update Phase status.
