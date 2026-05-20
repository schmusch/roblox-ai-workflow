---
name: roblox-forge-init
description: Use to scaffold a Product Requirements Document (PRD) for a new Roblox feature — the structured doc that anchors brief → blueprint → plan → forge. Use when the user says "start a new feature", "init a PRD", "scaffold the feature doc", "create the spec", "set up the feature folder", or at the very beginning of a non-trivial feature.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Forge Init

PRD scaffold for a new Roblox feature. Creates the structured document that everything downstream (`roblox-brief`, `roblox-blueprint`, `roblox-plan`, `roblox-forge`) reads and updates.

A good PRD is **the artifact that survives staffing changes, multi-session work, and AI context resets**. Without it, every session re-derives the same context badly. With it, each session picks up cleanly.

## When to use

- Starting a non-trivial new feature.
- A multi-session project where context will be lost between sessions.
- The user says: "start a new feature", "init a PRD", "set up the doc", "scaffold the spec".
- The work is large enough that `roblox-brief` alone isn't enough to anchor multiple sessions.

## When not to use

- Single-session, single-file fix — overkill.
- A spike / throwaway exploration — no document needed yet.
- The feature already has a PRD — don't create a second one; update the existing.
- Routine config / asset / cosmetic work — PRD adds noise.

## What this skill produces

A PRD file at `docs/features/<feature-name>.md` (or the repo's convention) containing:
1. **Header** — name, status, owner, dates.
2. **One-paragraph summary** — what this is, in plain language.
3. **Creator vision link** — points to the `roblox-deep-interview` output if available.
4. **Brief** — clarified intent (link to or inline from `roblox-brief`).
5. **Architecture / Blueprint** — link or summary (the full version is from `roblox-blueprint`).
6. **Plan** — link or summary (full version from `roblox-plan`).
7. **Implementation status** — what's done, what's in-progress, what's blocked.
8. **Verification path** — how this feature proves itself done.
9. **Open questions** — anything unresolved.
10. **Change log** — dated entries every time the doc is updated.

The PRD is a **living document** — updated as the feature progresses, not written once and forgotten.

## Method

### 1. Confirm the feature is PRD-worthy

Ask the user:
- Is this expected to be more than one session of work?
- Is there a chance someone else (or future-you) needs to pick this up cold?
- Does this touch monetization / persistence / multi-system surface?

If any "yes" → PRD-worthy. If all "no" → skip.

### 2. Pick the location and naming

Default: `docs/features/<kebab-case-name>.md` in the repo.

Alternative locations (per project convention):
- `docs/prd/<name>.md`
- `prd/<name>/README.md`
- Notion / external doc — if the user uses Notion, the relevant MCP can mirror it (but the in-repo doc remains canonical for the codebase).

Name should be specific: `party-trading.md`, not `trading.md` or `social-system.md`.

### 3. Create the scaffold

Write the PRD with the template (below). Fill what you know; leave clear placeholders for what's unknown so they can't be missed.

### 4. Populate from upstream artifacts

If `roblox-brief` / `roblox-deep-interview` already ran for this feature → pull their content (or link them).

If `roblox-blueprint` exists → pull or link.

If `roblox-plan` exists → pull or link.

If none of these exist yet → the PRD scaffold names them as next steps.

### 5. Set status accurately

- **Draft** — scaffolded, not yet planned.
- **Planning** — brief / blueprint / plan in progress.
- **In progress** — forge actively building.
- **In review** — code-review / security-review / ultraqa pending.
- **Done** — shipped + verified.
- **Deferred** — paused, with reason.

### 6. Commit to discipline of updating it

The PRD's value collapses if it goes stale. Establish:
- Update the change log every time a session touches the feature.
- Update implementation status before ending a session.
- Update open questions every time one is resolved or added.

## PRD template

```markdown
# PRD — <Feature Name>

**Status:** Draft / Planning / In progress / In review / Done / Deferred
**Owner:** <creator name>
**Created:** YYYY-MM-DD
**Last updated:** YYYY-MM-DD

## Summary

<One paragraph, plain language, what this feature is and what it does for players.>

## Creator vision

(link to `roblox-deep-interview` output, or inline summary)
- Primary driver: <Progression / Status / FOMO / Mastery / Community>
- Player desire: <one sentence>
- First-session promise: <what player feels in first 5 minutes>
- Anti-vision: <what this is NOT>

## Brief

(link to `roblox-brief` output, or inline)
- Genre: ...
- Audience: ...
- Scale: ...
- Multiplayer: ...
- Monetization: ...

## Architecture (Blueprint)

(link to `roblox-blueprint` output, or inline summary)
- Server scripts: ...
- Client scripts: ...
- Shared modules: ...
- Remotes: ...
- Persistence: ...
- Key types: ...

## Plan

(link to `roblox-plan` output, or inline summary)
- Step 1: ...
- Step 2: ...
- ...

## Implementation status

| Step | Status | Verification | Notes |
|------|--------|--------------|-------|
| 1 | Done | TestEZ ✓, ultraqa ✓ | shipped 2026-05-18 |
| 2 | In progress | unit ✓, runtime pending | |
| 3 | Blocked | | waiting on creator decision X |

## Verification path

- Unit tests: TestEZ suite `<FeatureTests>`
- Runtime: `roblox-ultraqa` flow definition
- Lint / typecheck: selene + luau-lsp clean
- Code review: `roblox-code-review`
- Security review: `roblox-security-review` (yes / not applicable)
- Visual: `roblox-visual-verdict` against `<ref>` (yes / not applicable)

## Open questions

- [ ] Resolved / Unresolved — question text — owner

## Risks

- ...

## Change log

- 2026-05-20 — PRD scaffolded
- 2026-05-21 — brief approved, blueprint draft started
- 2026-05-22 — plan finalised, forge began
```

## Anti-pattern checks

- ❌ PRD as a one-time write-only doc — value comes from updates.
- ❌ PRD that duplicates the blueprint / plan content instead of linking — diverges from the truth.
- ❌ Vague "Open questions" without owner / status — they go stale and nobody resolves them.
- ❌ Status field set to "In progress" forever — review monthly.
- ❌ PRD for every micro-task — only PRD-worthy features (multi-session, multi-system) deserve one.
- ❌ PRD content in chat without persisting to a file — the point is persistence across sessions.

## Roblox-specific framing

Generic PRDs assume software engineering features. Roblox PRDs additionally include:
- **Creator vision** as a first-class section — Roblox features are creator-driven, not feature-list-driven.
- **Psychology driver** explicit — primary + supporting from the 5-driver framework.
- **Server-authority intent** explicit — the PRD names the server-vs-client boundary.
- **Anti-vision** explicit — protects against AI / collaborator scope creep.

## Handoff

- PRD scaffolded → run `roblox-deep-interview` (deep brief) or `roblox-brief` (light brief) to fill creator vision / brief.
- Creator vision filled → `roblox-blueprint` for architecture.
- Architecture filled → `roblox-plan` for sequence.
- Plan filled → `roblox-forge` (or `roblox-autopilot` / `roblox-ultrawork`) to execute.
- Each downstream step **updates the PRD** as it completes.
