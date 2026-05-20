---
name: roblox-forge
description: Use after a roblox-blueprint plan is approved to carry it to verified completion via the Roblox Studio integration. Use when the user says "build it", "implement the plan", "forge X", "execute the plan", or when an approved blueprint needs single-owner code execution with iterative fix/verify loops.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge

The execution lane. Carries an approved `roblox-blueprint` plan to verified completion without drifting back into generic web-enterprise habits.

`roblox-forge` is for one owner pushing until the work is actually complete, verified, and internally consistent — using Roblox services, instance hierarchies, Luau constraints, and client/server trust boundaries throughout.

## When to use

- A blueprint plan is approved and now needs implementation.
- The task crosses multiple Roblox scripts / services and should not stop at partial completion.
- The work needs repeated fix/verify loops: remotes, persistence, replication, economy, combat, UI state.
- The user says "ship this", "build it", "implement", or "keep going until it's done".

## When not to use

- The task is still ambiguous → run `roblox-brief` or `roblox-blueprint` first.
- The user only wants design artifacts → use the relevant `roblox-blueprint-*` skill.
- The work has independent parallel slices that benefit from concurrent execution → use `superpowers:dispatching-parallel-agents` to stage parallel forge runs.

## Roblox-native guardrails

(See `references/server-authority-rules.md` and `references/roblox-vocabulary.md` for full detail.)

- Clients request. Server validates. Server mutates.
- Default to Luau / Studio concepts before generic backend / web abstractions.
- Concrete touchpoints: `ServerScriptService`, `ReplicatedStorage`, `StarterPlayer`, `StarterGui`, `Workspace`, `CollectionService`, `DataStoreService`, `MarketplaceService`, `TeleportService`.
- No invented type systems or DTO ceremony when typed Luau tables and ModuleScripts suffice.
- No "service / repository / controller" structure by reflex.

## Execution loop

### 1. Pre-context intake

Before writing code:
- Confirm the blueprint is approved and current (not stale from earlier session).
- If brownfield: walk the existing codebase / live Studio (`roblox-studio-bridge`) for the touched scripts to confirm current state.
- If the blueprint is missing or vague, **stop and run `roblox-blueprint`** instead of improvising.

### 2. Confirm the ownership split

For the affected feature:
- which scripts are server (authority, validation, persistence)
- which scripts are client (input, prediction, UI)
- which ModuleScripts are shared (types, configs, pure logic)
- which Instances / assets / config tables need to exist

### 3. Implement the smallest complete vertical slice first

Don't write the whole feature flat. Pick the thinnest end-to-end path:
- one minimal remote round-trip
- one minimal persistence read/write
- one minimal UI mirror

Get that green, then layer.

### 4. Verify immediately after each slice

Use the most relevant proof:
- targeted unit / test harness (TestEZ / Jest-Roblox / existing project test runner)
- repo lint / typecheck (Selene / Luau LSP) where present
- runtime check via `execute_luau` (Studio MCP) for fast feedback
- `screen_capture` (Studio MCP) for visual changes
- `get_console_output` to catch runtime warnings/errors

**Do not claim completion from static inspection alone** when behavior depends on replication, remotes, or DataStore — actually run it.

### 5. Iterate until the changed flow is green

For each iteration:
- read the failure evidence (stack, console, screenshot)
- update the implementation
- re-verify with the same proof

Stop only when:
- the changed flow passes its verification path end-to-end
- the touched scripts use one coherent Roblox-native vocabulary
- no obvious server-authority hole remains

### 6. Anti-slop pass

Before declaring done, run the `roblox-anti-slop` skill mentally (or invoke it explicitly for large changes): scan for `Controller` / `Repository` / `DTO` / `Service` (as non-engine-service) / `Manager` (vague) / `Handler` (vague) and rewrite to Roblox-native.

### 7. Final verification + handoff

- Re-run the agreed verification path from the blueprint, fresh.
- Capture evidence: console output, screenshot, test results, state snapshot.
- Summarize what was changed (touched files + behavior change in 2–4 lines).
- Note any deferred items or follow-up risks.

## Using the Studio MCP

If `mcp__Roblox_Studio__*` is available, default to it for reads + writes. See `references/studio-mcp-cheatsheet.md` for the full pattern catalog. Key calls:

- `list_roblox_studios` first if multiple Studios may be open
- `script_read` before `multi_edit` to confirm exact whitespace
- `multi_edit` for atomic batch edits (single undo step)
- `execute_luau` for runtime probing — **not** for production logic
- `screen_capture` + `get_console_output` for evidence

If the Studio MCP is **not** available (Gemini / Codex hosts without the plugin):
- emit patches the user applies
- ask for paste-backs of console output, screenshots
- rely on the user reporting verification results

## Verification standard

At minimum, capture evidence proving:
- remote validation path works (positive + adversarial)
- replicated state updates correctly across the boundary
- DataStore / economy logic preserves server authority
- UI reflects authoritative state, not stale client guesses
- repo checks (lint / typecheck / build) still pass

## Visual iteration gate

When screenshot or reference-image work is in scope:
- Run `roblox-visual-verdict` before every next edit on the visual.
- Pass threshold default: `score >= 90` (or as the user specifies).
- Persist visual feedback inline in the session unless the user wants it logged.

## Pre-action dependency

For creator-domain work, forge expects the pre-action groundwork to exist:
- clear creator goal (from `roblox-brief`)
- normalized Roblox terminology
- agreed file / module layout (from `roblox-blueprint`)
- explicit risk notes for unsafe assumptions

If that groundwork is missing, **produce it first** via the planning lane. Do not generate implementation code until that creator planning groundwork is present.

## Forge completion checklist

- [ ] Blueprint plan re-read; ownership split confirmed
- [ ] Smallest vertical slice landed first and verified
- [ ] All planned remotes validated (type / range / ownership / rate-limit)
- [ ] DataStore writes happen only after server validation
- [ ] Replication path tested in both directions where applicable
- [ ] Anti-slop pass complete (no enterprise jargon in touched code)
- [ ] Fresh verification evidence captured
- [ ] Out-of-scope items not silently added
- [ ] Touched files listed and behavior summary written

## Example

```text
roblox-forge "Implement the approved party-trading plan:
- TradeService server-authoritative
- 4 remotes per plan with full validation
- atomic swap + DataStore-safe rollback on failure
- UI mirrors server state, no client mutation"
```
