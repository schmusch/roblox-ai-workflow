---
name: roblox-team
description: Use to coordinate multiple parallel agents working on independent slices of a Roblox project. Use when the user says "split this work", "dispatch parallel agents", "run these in parallel", "team up on this", "swarm this refactor", or when a roblox-plan identified independent steps that can run concurrently.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Team

Multi-agent orchestration for Roblox work. When a plan has multiple independent slices, this skill coordinates parallel sub-agents on those slices, then merges their outputs.

Consolidates the originally-planned `roblox-crew`, `roblox-swarm`, and `roblox-worker` into one skill. The differences between them (crew = small group, swarm = many parallel, worker = sub-role) are operational details, not skill boundaries.

## When to use

- A `roblox-plan` identified steps that can run in parallel.
- Refactoring or test-coverage tasks across many similar files (batch-style).
- The user says "dispatch", "split", "parallel", "swarm", "team up on this".
- Time pressure on a large change where serial execution is too slow.

## When not to use

- Tightly-coupled work where each step depends on the previous → serial is right; use `roblox-forge` alone.
- Single-file change → overhead not worth it.
- Work that touches the same files from multiple slices → merge conflicts will dominate; consolidate first.
- No plan exists yet → run `roblox-plan` first; you can't dispatch what isn't sliced.

## What this skill produces

A multi-agent execution:
- **Slice definitions** — which slice covers which files / responsibility.
- **Per-slice subagent prompts** — concrete, self-contained, no shared mutable state.
- **Merge plan** — how outputs come together.
- **Integration verification** — proves the merged result is coherent.

## Method

### 1. Confirm the slices are truly independent

Walk the plan's parallelisation map. For each candidate parallel slice:
- Does it write to files that no other parallel slice writes to?
- Does it depend on output from another parallel slice? (If yes → not independent, must serialise.)
- Does it require shared state mutation (e.g., both modify the same RemoteEvent set)?
- Does it require live coordination during execution?

**Only truly independent slices parallelise.** When in doubt, serialise.

### 2. Define each slice's contract

For each slice, write a self-contained brief that another agent (or process) could execute from cold:
- **Goal** — what this slice delivers.
- **Inputs** — relevant files, current state, blueprint references.
- **Outputs** — exact deliverable (files, behavior, tests).
- **Verification gate** — what proves this slice is done before merge.
- **Boundary** — what files / scope this slice must NOT touch.
- **Reporting back** — what summary the slice agent provides on completion.

Each prompt should stand alone — the slice agent will not have this conversation's context.

### 3. Dispatch

Use the host platform's parallel-agent dispatch mechanism (Claude Code's `dispatching-parallel-agents` or Gemini / Codex equivalent if available). If no parallel dispatch is available, execute slices serially but **as if they were parallel** — same boundaries, same independence discipline, just slower wall-clock.

Each dispatched agent:
- Receives its slice brief.
- Operates in its own context.
- Does not communicate with siblings during execution.
- Returns its summary on completion.

### 4. Collect outputs

When all slices return:
- Inventory what each delivered (files changed, tests added, etc.).
- Cross-check: did any slice touch a file outside its boundary? (Should not — if yes, investigate.)
- Run combined build steps: `wally install`, `rojo build`, `stylua --check`, `selene`, full test suite.

### 5. Merge integration verification

After all slices land, the system is now in a state no single slice has seen. Run integration verification:
- Full test suite — pass.
- `roblox-ultraqa` runtime checks on the integrated whole, especially across slice boundaries.
- `roblox-code-review` on the cumulative diff if security-sensitive surfaces were touched.

### 6. Reconcile and report

If any slice failed or its output doesn't compose with the others:
- Either re-dispatch the failing slice with corrected brief.
- Or fold the slice back into serial work under `roblox-forge`.

Report back to the user:
- Slices dispatched: N
- Slices completed: N
- Integration verification: passed / failed
- Touched files (combined): list
- Open items: list

## Slice patterns (templates)

### Refactor swarm (many small, identical tasks)
"For each file in `src/**/`<pattern>`, rename `Controller` → `Module` per `roblox-anti-slop`. One slice per file. Boundary: own file only."

### Test coverage push
"For each untested public function in `src/server/`<Feature>`, write a TestEZ spec. One slice per module. Boundary: only adds test files in `tests/<module>.spec.lua`."

### Feature triplet
"Slice A: implement `WalletService` (server). Slice B: implement `WalletConfig` + types (shared). Slice C: implement `WalletUI` (client). Each independent; merge after all three return."

### Doc / config sweep
"Add module-level Luau type definitions to N files. One slice per file."

## Anti-pattern checks

- ❌ Dispatching slices that touch the same file → merge conflicts dominate; serialise these.
- ❌ Slice briefs that say "and use your judgment about X" — judgment requires context; specify or serialise.
- ❌ Skipping integration verification after parallel work → the whole may not compose even if each part did.
- ❌ Dispatching when the plan isn't actually parallel — slows things down due to coordination overhead.
- ❌ Letting slices communicate during execution — defeats independence; introduces races.
- ❌ Not reporting back what each slice did — invisible mass change is hard to review.

## Roblox-specific framing

Generic parallel-agent dispatch works for any modular codebase. Roblox-specific overlays:
- **Service-container boundaries make independence easier** — server / client / shared are natural slice boundaries.
- **Remote definition locations are shared** — slices that add new remotes all touch `ReplicatedStorage/Remotes/`; serialise the remote-definition step.
- **`default.project.json`** is shared — slices that add new top-level paths all touch this; serialise or merge carefully.
- **`wally.toml`** is shared — slices that add packages all touch this; serialise or merge carefully.
- **Place file** if committed is shared — slices that add Instances all touch this; serialise.

Pure-Luau code in feature folders parallelises cleanly. Manifest / shared-config edits do not.

## Handoff

- Slices complete + integration green → continue with the next planned step (`roblox-forge`) or wrap.
- Some slice failed → re-dispatch or fold back into serial work.
- Integration broke a previously-passing test → `roblox-build-fix` or `roblox-ultraqa` to diagnose.
- Combined change is large → `roblox-code-review` before merging the integrated branch.
