---
name: roblox-blueprint
description: Use after a roblox-brief is complete (or when scope is already clear) to turn it into a Roblox-native architecture plan with services, ownership boundaries, data shape, and verification path before any code is generated. Use when the user says "plan this", "design the architecture", "how should I structure this", "blueprint X", or asks for an implementation strategy.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Blueprint

The planning lane between brief and execution. Converts a Roblox creator intent into a concrete architecture using engine-native concepts, explicit server/client ownership, data shapes, remote contracts, and a verification path.

`roblox-blueprint` exists to stop planning drift before implementation: vague feature ideas become engine-grounded architecture, named with real Roblox concepts, with server/client boundaries decided **before any script changes**. The output is execution-ready for `roblox-forge`.

## When to use

- A brief is complete and the user wants to "plan", "design", or "architect" the feature.
- The user describes a feature with verbs ("add trading", "implement progression") without specifying file layout or ownership.
- A prior plan exists but a new constraint requires re-planning a slice.
- Before `roblox-forge` whenever the change crosses multiple scripts / services / replication boundaries.

## When not to use

- The brief is missing or incomplete — run `roblox-brief` first.
- The task is a precise file-level fix (`fix typo in InventoryModule line 42`) — go straight to forge.
- The user only wants design artifacts (loop specs, monetization frameworks) without architecture — use `roblox-blueprint-loops`, `roblox-blueprint-psychology`, etc.

## What this skill produces

A plan document covering:

1. **Player-facing behavior** — what the player sees, does, gets.
2. **Roblox runtime surfaces involved** — services, instance classes, replication edges.
3. **Ownership split** — what's server-only, client-only, shared.
4. **File / module layout** — concrete paths, following existing repo conventions.
5. **Data shape** — Luau-typed tables for state, payloads, persisted records.
6. **Remote contracts** — RemoteEvent/Function names + payload shapes + validation rules.
7. **Failure modes** — what happens on stale replication, duplicate grant, invalid payload, save failure.
8. **Verification path** — concrete steps proving the change works (which test, which runtime path, which state transition).
9. **Out-of-scope** — what the plan deliberately omits.

Save to `plans/<task-slug>-<YYYYMMDD>.md` for non-trivial work.

## Method

### 1. Pre-context

- Re-read the brief.
- If the brief has unresolved `OPEN:` fields material to the plan, resolve them now.
- Walk the existing codebase (or live Studio via `roblox-studio-bridge`) for:
  - existing services / modules touching the same domain
  - existing naming conventions to follow
  - existing remote shapes to extend
- If repo conventions are unclear, ask the user which set to follow (Rojo + Wally is a common modern default).

### 2. Planning checklist (work through in order)

1. **Player-facing behavior** — one paragraph. What does the player do and see?
2. **Roblox runtime surfaces** — list of services (`DataStoreService`, `MessagingService`, …) and instance classes (`RemoteEvent`, `ModuleScript`, `ProximityPrompt`, …) touched.
3. **Ownership matrix**:
   - **Server** holds: authoritative state, validation, persistence calls
   - **Client** holds: input, prediction (if any), UI render
   - **Shared** holds: types, configs, pure logic / math
4. **File / module layout** — concrete paths. Use the existing repo's conventions; if green field, default to a `server/`, `client/`, `shared/`, `config/` split per feature.
5. **Data shape** — typed Luau. Don't invent DTO ceremony.
6. **Remote contracts** — for each remote:
   - name (`<Feature><Verb>Remote`, e.g. `TradeOfferRemote`)
   - direction (client→server, server→client, request-response)
   - payload type
   - server-side validations (type / range / ownership / rate-limit)
7. **Failure modes** — for each:
   - stale replication
   - duplicate grant / double-fire
   - invalid payload from exploited client
   - DataStore save failure / throttling
   - cross-server race (if cross-server scope)
8. **Verification path** — for each acceptance criterion:
   - what test / runtime path proves it
   - what state transition is the canary

### 3. Apply Roblox-native rules

Before finalizing:
- Cross-check vocabulary against `references/roblox-vocabulary.md`. Reject any `Controller`/`Repository`/`DTO`/`Service` (when not an engine service) — rename to engine-native.
- Cross-check authority against `references/server-authority-rules.md`. Reject any plan where the client mutates economy / inventory / damage / persistence state.
- Cross-check player-driver alignment with `references/psychology-framework.md` — does the plan actually serve the brief's dominant driver?

### 4. Anti-slop rules

- ❌ Do **not** emit architecture that reads like an enterprise CRUD app unless the existing repo is already that shape.
- ❌ Do **not** use `DTO`, `Controller`, `Repository`, `Service` (when not an engine service), `microservice`, `middleware chain` by reflex for Roblox gameplay code.
- ❌ Do **not** invent fake type hierarchies when normal Luau tables and typed Luau suffice.
- ❌ Do **not** hand off to forge until naming, ownership, and verification are concrete.

### 5. Deepening lanes (optional, when the plan benefits)

After the core plan:
- `roblox-blueprint-psychology` — verify driver alignment + design feedback surfaces.
- `roblox-blueprint-loops` — when the feature is a reward / daily / event loop.
- `roblox-blueprint-retention` — when retention is the success metric.
- `roblox-blueprint-social` — when the feature is parties / trading / guilds / co-op.

## Handoff

When the plan is complete and self-consistent:

> "Blueprint complete. Recommend running `roblox-forge` to execute, or `roblox-pre-action` if the implementation hasn't been gate-checked yet."

Hand off to `roblox-forge` for single-owner execution. If the plan has independent parallel slices, `superpowers:dispatching-parallel-agents` can stage parallel forge runs.

## Example output

```markdown
# Plan: party-trading (2026-05-20)

## Player-facing behavior
Two party members open a trade panel via ProximityPrompt. Each adds items, both confirm, items swap atomically. UI shows offer state in real time.

## Roblox runtime surfaces
- Services: `ReplicatedStorage`, `ServerScriptService`, `DataStoreService`
- Classes: `RemoteEvent` (4), `ModuleScript` (3), `ScreenGui` (1), `ProximityPrompt`

## Ownership
- Server: `TradeService` (session state, validation, mutation, persistence)
- Client: `TradeController` (UI, input)
- Shared: `TradeTypes`, `TradeConfig`

## File layout
- `src/server/Trade/TradeService.server.lua`
- `src/server/Trade/TradeValidator.lua`
- `src/client/Trade/TradeController.client.lua`
- `src/shared/Trade/TradeTypes.lua`
- `src/shared/Trade/TradeConfig.lua`

## Data shape
```luau
type TradeOffer = { items: {string}, locked: boolean }
type TradeSession = {
    a: { player: Player, offer: TradeOffer },
    b: { player: Player, offer: TradeOffer },
    state: "open" | "locked" | "completed" | "cancelled",
}
```

## Remote contracts
- `TradeStartRemote` (c→s): `{ targetUserId: number }` — server checks proximity + party membership
- `TradeAddItemRemote` (c→s): `{ itemId: string }` — server checks ownership, both sides unlocked
- `TradeLockRemote` (c→s): `{}` — server transitions session state
- `TradeStateRemote` (s→c): `TradeSession` — pushed on every mutation

## Failure modes
- Duplicate accept → server uses single-flight per session ID
- Item left inventory mid-trade → re-validate at lock time, reject lock
- DataStore save fail post-swap → roll back in-memory + log + retry
- Player leaves mid-trade → session cancelled, no mutation

## Verification path
- Unit: `TradeValidator` rejects items the offerer doesn't own
- Runtime: two test players in Studio Play Solo → trade item A↔B → assert post-swap inventories
- Adversarial: client fires `TradeLockRemote` for a session they're not in → server rejects silently

## Out of scope
- Cross-server trading
- Mailbox / async trading
- Tax / fee
```
