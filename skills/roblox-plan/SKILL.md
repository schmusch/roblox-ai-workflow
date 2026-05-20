---
name: roblox-plan
description: Use to produce a multi-step Roblox implementation plan with a Planner / Architect / Critic consensus loop before code is written. Use when the user says "make a plan", "plan this", "write a plan", "spec this out", or when a feature crosses multiple services / scripts and needs an explicit step sequence before forge runs.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Plan

Multi-step implementation planning for Roblox features. This is heavier than `roblox-blueprint`: where the blueprint defines architecture (services, ownership, file tree, verification path), `roblox-plan` defines a **step-by-step execution sequence** — what gets built in what order, with what intermediate verification gates, and what can be parallelised.

Uses a consensus loop: a single agent plays three roles in sequence (Planner → Architect → Critic) and only finalises when all three are satisfied.

## When to use

- A feature crosses multiple scripts / services and the order of work matters.
- After `roblox-blueprint` defined the architecture but before `roblox-forge` starts building.
- The user says "make a plan", "plan it out", "spec this", "what's the implementation order".
- Risky / large work where one wrong step shape causes rework.

## When not to use

- The work is a single-file change — overkill.
- No architecture has been agreed yet → run `roblox-blueprint` first.
- The work has no creator-domain framing at all → run `roblox-brief` first.
- The user wants to **execute** the plan, not write it → that's `roblox-forge` (with this plan as input).

## What this skill produces

A structured plan document with:
- **Goal & scope** — what's in, what's out.
- **Preconditions** — what must already exist before starting.
- **Sequence of steps** — each with concrete deliverable, verification gate, dependencies.
- **Parallelisation map** — which steps are independent and can run concurrently (use `roblox-team` if you want to dispatch them).
- **Risks & open questions** — flagged before implementation.
- **Verification path** — how each step proves itself, plus the final-completion proof.

## Method

### 1. Read the upstream artifacts

Before writing the plan:
- Read the approved `roblox-blueprint` if one exists.
- Read the `roblox-brief` for creator intent.
- Walk the codebase / live Studio for any brownfield touchpoints.
- Read `references/pre-action-template.md` — the plan should satisfy the pre-action gate.

If the blueprint is missing or stale → stop and run `roblox-blueprint` first. Do not improvise architecture inside a plan.

### 2. Planner pass — write the first draft

Acting as **Planner**: produce a step sequence. Each step:
- Has a one-sentence title.
- Has a concrete deliverable (a file, a function, a remote, a test).
- Has a verification gate (what proves this step is done).
- Lists dependencies (what step(s) must complete first).

Aim for **5–15 steps**. Fewer means each step is too coarse to track. More means split into sub-plans.

Vertical-slice principle: the first step should produce the **minimal end-to-end behavior**, not a horizontal layer. E.g. for a trading feature: step 1 is "one player can offer one item, the server logs the offer" — not "build all the data types".

### 3. Architect pass — challenge structure

Acting as **Architect**: re-read the plan and ask:
- Does each step respect the ownership split (server / client / shared)?
- Does each step honor server authority?
- Are remotes named consistently and placed in `ReplicatedStorage`?
- Are persistence steps using `UpdateAsync` and retry?
- Is the file tree consistent with the blueprint?
- Are types defined in a shared location before being used in steps that depend on them?

Rewrite affected steps. Document what changed and why.

### 4. Critic pass — challenge assumptions

Acting as **Critic**: re-read the plan and ask:
- What's the worst step here? (The one most likely to balloon.)
- What's the assumption I'm uncomfortable with?
- What can fail at runtime that this plan can't predict?
- Where's the dupe risk / race risk?
- What's the test for "we're really done"?
- What did I skip that I shouldn't have?

If the Critic finds a real gap, go back to Planner. Iterate until Critic is satisfied.

### 5. Parallelisation map

After the sequence is final, mark which steps are independent:
- Step 1 → Step 2 → Step 3 (serial chain)
- Steps 4, 5, 6 are independent of each other (can be parallel after step 3)
- Step 7 depends on 4 and 5

If meaningful parallelism exists, note that `roblox-team` can dispatch the parallel slices. Don't force parallelism where dependencies are tight — serial is fine for tightly-coupled work.

### 6. Risks & open questions

List every assumption that could be wrong. For each, either:
- **Resolve now** (read docs, ask the user, run a quick `execute_luau` probe).
- **Mark as accepted risk** (with a name, so the plan reader knows it's known).
- **Block** (the plan can't proceed without resolving this).

### 7. Verification path

For the whole feature:
- What unit / module tests exist after?
- What runtime evidence in Studio (via `roblox-ultraqa`)?
- What lint / typecheck must pass?
- What review skills must pass before merge (`roblox-code-review`, `roblox-security-review` if security-sensitive)?

## Output format

```markdown
# Plan — <feature>

## Goal & scope
- In scope: ...
- Out of scope: ...

## Preconditions
- [ ] Blueprint approved (`docs/blueprints/<feature>.md`)
- [ ] Existing repo at clean state on the work branch
- [ ] Studio MCP connected (or fallback plan documented)

## Steps

### Step 1: <title>
- **Deliverable:** `src/server/<Feature>/<File>.server.lua` containing X
- **Verification gate:** TestEZ test asserts Y; manual `execute_luau` probe returns Z
- **Depends on:** —

### Step 2: <title>
- **Deliverable:** ...
- **Verification gate:** ...
- **Depends on:** Step 1

... (5–15 steps total)

## Parallelisation
- Steps 1 → 2 → 3 serial.
- Steps 4, 5, 6 independent after step 3; can dispatch via `roblox-team`.
- Step 7 needs 4 and 5 complete.

## Risks & open questions
- **Resolved:** ...
- **Accepted risk:** ... (named)
- **Blocking:** ... (must resolve before starting)

## Verification path (whole feature)
- Unit: `TestEZ` suite for `<Feature>Tests` — N tests
- Lint: `selene` + `luau-lsp` clean
- Runtime: `roblox-ultraqa` for the trade flow including adversarial cases
- Review: `roblox-code-review`, plus `roblox-security-review` for the remote / persistence surface
```

## Anti-pattern checks

- ❌ Plan with one giant step "implement the feature" — useless.
- ❌ Plan with horizontal layers ("all server first, then all client") — bad for iteration; defer integration risk.
- ❌ Skipping the Architect pass — structural mistakes compound.
- ❌ Skipping the Critic pass — assumptions blow up in `roblox-forge`.
- ❌ Plan that doesn't name a final verification path → no way to know when done.
- ❌ Plan that contradicts the blueprint silently — if the blueprint is wrong, revise the blueprint, don't bury the conflict.

## Roblox-specific framing

Generic implementation planning is mostly sequence + dependency. Roblox planning additionally enforces:
- **Server / client / shared** ownership at every step.
- **Server authority** at every state-mutation step.
- **Verification gate per step** (because Roblox runtime behavior can't be statically proven).
- **Anti-slop awareness** (Roblox vocabulary throughout — see `references/roblox-vocabulary.md`).

The consensus loop (Planner → Architect → Critic) is not theatre — each role catches different mistakes. Planner builds structure. Architect enforces invariants. Critic stress-tests assumptions.

## Handoff

- Plan approved by user → `roblox-forge` executes it (one slice / step at a time).
- Plan has parallelisable steps and the user wants speed → `roblox-team` dispatches the independent slices.
- Plan reveals blueprint gaps → loop back to `roblox-blueprint`.
- Plan reveals brief-level ambiguity → loop back to `roblox-brief` or `roblox-deep-interview`.
