---
name: roblox-pre-action
description: Use as a pre-action gate before generating Roblox code for non-trivial creator-domain work — classifies the task, lists services involved, defines the file tree, and names risks. Use when a user request crosses multiple scripts / services / replication boundaries, before any roblox-forge run on greenfield work, or to ground vague feature asks before implementation.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Pre-Action Gate

A mandatory gate before code generation for non-trivial creator-domain work. Fills out the pre-action template, classifies the task, names the services involved, defines the file tree, and surfaces risks **before** any code is written.

This is the cheapest place to catch architecture mistakes — fixing a wrong file layout in the pre-action plan costs one rewrite; fixing it post-implementation costs a forge cycle.

## When to use

- The user request is a new feature, system, or substantial change.
- The work crosses multiple scripts / services / replication boundaries.
- Greenfield code (no prior plan / blueprint exists).
- Before `roblox-forge` when no `roblox-blueprint` has run.

## When **not** to use (gate bypass)

The gate auto-passes when the user's input already contains:

- A specific file path + symbol + concrete change (`fix typo in InventoryModule:GetItem`).
- A bug report with a reproduction (existing test failing).
- A numbered list of explicit steps.
- A code block of intended changes.
- Explicit user override (`just do it`, `skip the gate`, `forge directly`).

In bypass cases, log that the gate was bypassed in the response so the user can correct if needed.

## What this skill produces

A filled `references/pre-action-template.md`:

1. **Task classification** (type / genre / audience / scale / multiplayer / monetization)
2. **Relevant Roblox concepts** (concepts / services / classes / gameplay patterns)
3. **Reference sources to consult**
4. **Canonical terms to use** (vocabulary alignment)
5. **Risks and uncertainties**
6. **Proposed file tree**
7. **Category ownership** (server / client / shared / config / assets / tests)
8. **Naming convention**
9. **Implementation phases**
10. **Validation checkpoints**

Output is saved as `plans/pre-action-<task-slug>-<YYYYMMDD>.md` or kept inline if short.

## Method

### 1. Read the request carefully

Pull out:
- the verb (add / implement / fix / refactor)
- the noun (what system / feature)
- explicit constraints (must reuse X, deadline Y, audience Z)

### 2. Walk the existing repo (if any)

If a codebase exists in the workspace:
- glob / search for the relevant domain
- identify existing modules / services / remotes
- identify existing naming conventions to follow

If a Roblox Studio is open via MCP, use `search_game_tree` and `script_grep` for live state.

### 3. Fill the template

Section by section. The template is in `references/pre-action-template.md`. Don't skip sections.

**Anti-pattern:** filling sections with vague placeholders (`TBD`, `various`, `as needed`). Either fill it concretely or admit the gap with an `OPEN:` note.

### 4. Apply vocabulary check (anti-slop)

Cross-check proposed module / folder / remote names against `references/roblox-vocabulary.md`. If you typed `<X>Controller` or `<X>Repository`, rewrite before continuing.

### 5. Apply server-authority check

Cross-check the proposed architecture against `references/server-authority-rules.md`:
- Does any client mutate canonical state?
- Are all remotes validated server-side?
- Does the persistence path live only on the server?

If any rule is violated, fix the design **before** flipping the gate.

### 6. Apply risk surfacing

For each risk row:
- **Unsafe assumptions:** anything client-trusted, anything depending on undocumented engine behavior.
- **Required validation:** rate limit, ownership, type, range.
- **Likely pitfalls:** replication races, DataStore quotas, throttling, cross-server issues.

This is the section that catches "looks fine but explodes at scale" issues.

### 7. Flip the gate

Once all sections are filled with concrete content and no `OPEN:` blockers remain:

```text
PRE_ACTION_COMPLETE: true
```

Hand off to `roblox-blueprint` (for deeper architectural planning) or `roblox-forge` (for direct implementation when the plan is already clear from this gate alone).

## Output format

Save to `plans/pre-action-<task-slug>-<YYYYMMDD>.md`. For small tasks, present inline.

## Anti-pattern checks

- ❌ Filling sections with `TBD` / `as needed` → gate hasn't done its job.
- ❌ Skipping the server-authority cross-check → ship a security hole.
- ❌ Skipping the vocabulary cross-check → ship enterprise-flavored Luau.
- ❌ Treating the gate as paperwork → it's an architectural rehearsal.
- ❌ Inventing file tree sections that don't exist in the repo → walk before you propose.

## Example output (small task)

```markdown
# Pre-Action: friend-trade-cooldown (2026-05-20)

`PRE_ACTION_COMPLETE: false`

## 1. Task classification
- Task type: extension
- Genre: existing tycoon
- Audience: existing (10-16)
- Scale: in-session
- Multiplayer: co-op party
- Monetization: none (this change)

## 2. Relevant concepts
- Concepts: rate-limiting, server authority, replication
- Services: ServerScriptService
- Classes: ModuleScript (existing TradeService)
- Patterns: per-player cooldown

## 3. References
- Creator docs: DataStoreService (no new persistence)
- Existing: src/server/Trade/TradeService.lua (modify)

## 4. Canonical terms
- "Cooldown" not "Throttle"; "TradeService" stays (matches repo)

## 5. Risks
- Unsafe: client may attempt rapid trades to spam the partner
- Required validation: server-side cooldown table, per-player
- Pitfalls: cooldown persistence across server hops (decision: no, in-memory is fine)

## 6. File tree
- src/server/Trade/TradeService.lua (modify)
- src/server/Trade/TradeCooldown.lua (new)

## 7. Ownership
- Server: TradeCooldown (cooldown state)
- Client: TradeController (UI disable on cooldown)
- Shared: none new

## 8. Naming
- Folder: Trade (existing)
- Module: TradeCooldown (new)
- Remote: existing TradeStartRemote modified to check cooldown

## 9. Implementation phases
1. Add TradeCooldown module with `canTrade(player, target)` and `markTraded(player, target)`
2. Wire into TradeService.lua at session start
3. Push cooldown status to client via existing replication
4. Update UI to disable trade button during cooldown

## 10. Validation checkpoints
- [ ] Docs verified (none needed; in-memory only)
- [ ] Architecture reviewed (server-only, ✓)
- [ ] File tree approved (minimal change)
- [ ] Implementation gate: 5-min cooldown verified in Studio

`PRE_ACTION_COMPLETE: true`
```

## Handoff

When complete, hand off to:
- `roblox-blueprint` for deeper architectural planning (cross-system features).
- `roblox-forge` for direct implementation when the gate already provides a complete plan.
