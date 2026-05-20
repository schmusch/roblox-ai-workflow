---
name: roblox-analyze
description: Use to perform read-only deep analysis of a Roblox codebase, place file, or system and produce a ranked synthesis (architecture, hotspots, risks, opportunities). Use when the user says "analyze this", "explain what this codebase does", "what's wrong with this", "audit the structure", "give me a map of the project" — without making changes.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Analyze

Read-only deep analysis. Walks a codebase / Studio place / system, builds a mental map, and produces a ranked synthesis. No edits. No "fixes". Just understanding.

This is what you run **before** `roblox-blueprint`, `roblox-plan`, or `roblox-forge` on unfamiliar territory. It's also what you run when the user wants understanding without commitment — *"what does this thing even do?"*

## When to use

- Inheriting an unfamiliar Roblox codebase / place.
- Before writing a `roblox-blueprint` for a brownfield change.
- User says "analyze", "explain", "map", "audit the structure", "what's going on here".
- Pre-acquisition / pre-collaboration assessment of someone else's work.
- After a long break, re-orienting on your own project.

## When not to use

- The user wants action, not understanding → skip to `roblox-forge` or `roblox-plan`.
- Single-file question → just read the file, no full analysis needed.
- Security-specific audit → `roblox-security-review` is the right depth.
- Code-quality review on a specific change → `roblox-code-review`.

## What this skill produces

A ranked synthesis document:
1. **Project shape** — folder layout, build / package tooling, place file structure.
2. **Architecture map** — services, ownership boundaries, key modules and how they relate.
3. **Hotspots** — places where most of the logic lives; complexity concentrations.
4. **Risks** — server-authority holes, anti-slop smells, replication oddities, persistence concerns.
5. **Opportunities** — places where small changes would unlock a lot.
6. **Open questions** — things that couldn't be answered from reading alone.

No code changes. No recommendations to act on yet. Just the map.

## Method

### 1. Inventory the surface

Before reading content, list what exists:
- Top-level folders.
- Build / package config (`default.project.json` for Rojo, `wally.toml`, `aftman.toml`, `selene.toml`, `stylua.toml`).
- Test runner config (`testez.toml`, `jest.config.luau`).
- Place file (`.rbxlx` or `.rbxl`) and any other artifact files.
- Documentation (`README.md`, `docs/`, ADRs).

Note what's **missing** as much as what's present: no `wally.toml` means no package management; no test config means no automated tests; no Rojo means an in-Studio-only project.

### 2. Identify the service container layout

Walk the Rojo `default.project.json` (or place file via Studio MCP). For each service:
- `ServerScriptService` — what server logic lives here? Authority modules, persistence, marketplace.
- `ReplicatedStorage` — what shared modules, remotes, configs, assets?
- `StarterPlayer/StarterPlayerScripts` — what client logic, input, prediction?
- `StarterGui` — UI templates.
- `Workspace` — runtime instances; flag if there's substantial code here (smell).
- `ServerStorage` — server-only assets.

This is the architecture skeleton. Sketch it as a tree.

### 3. Walk the remotes

Find every `RemoteEvent` and `RemoteFunction`. For each:
- Where defined (which service container)?
- What handlers exist (client and server)?
- What payload?

The remote inventory is the system's **public API surface from the client side**. Every remote is an attack surface.

### 4. Walk the persistence

Find every `DataStoreService` call:
- Which DataStore names exist?
- What's saved per player? Per system?
- Is there retry / backoff? `BindToClose` flush?
- Is there a schema definition somewhere, or is the shape inferred from the code?

Persistence shape is the system's **long-term state model**.

### 5. Identify the hotspots

Look for:
- Largest files (often god-modules).
- Files with the most `require` references (highest-coupling modules).
- Files with the most TODO / FIXME / "hack" comments.
- Files that handle the largest number of remotes.

These are where most future work will land. Note them.

### 6. Apply Roblox-specific risk lens

Run a quick scan for:
- **Server-authority** smells: client RemoteEvents that "report" state to the server (e.g., `ReportCurrencyRemote`) — usually indicates trust holes. See `references/server-authority-rules.md`.
- **Anti-slop** smells: `Controller` / `Repository` / `DTO` naming. See `references/roblox-vocabulary.md`.
- **Persistence** smells: `SetAsync` on race-prone keys, no retry, no `BindToClose`.
- **Replication** smells: server secrets in `ReplicatedStorage`, runtime code in `Workspace`.
- **Service-container mismatches**: `LocalScript` in `ServerScriptService` (dead), `Script` in `StarterPlayer` (won't replicate as server).
- **Deprecated API**: `wait()`, `spawn()`, `delay()`, `FilteringEnabled = false`.

Each smell is a **risk note**, not a fix recommendation yet — this is read-only.

### 7. Identify opportunities

Where would small changes unlock disproportionate value?
- A single missing rate-limit on an exposed remote.
- A god-module that could be split with low effort.
- Missing tests on a critical surface that's easy to test.
- A documented blueprint that doesn't match the code (drift).

### 8. List open questions

What couldn't be answered from reading alone?
- What does `<X>` actually do in this codebase?
- Why is `<Y>` in `ServerStorage` instead of `ReplicatedStorage`?
- Is `<Z>` still used or dead code?

These get asked of the user, or probed with `execute_luau` in a follow-up.

### 9. Rank and synthesize

Put findings in a ranked order:
- Most important risk first (security / dupe / data-loss).
- Then structural risks (god modules, slop).
- Then opportunities.
- Then open questions.

The order is the user's priority list for follow-up work.

## Output format

```markdown
# Analysis — <project / system>

## Shape
- **Build tooling:** Rojo (`default.project.json`), Wally (`wally.toml`), Selene, StyLua
- **Test tooling:** TestEZ (suite in `tests/`)
- **Layout style:** feature folders under `src/server`, `src/client`, `src/shared`
- **Documentation:** README + `docs/` with 3 ADRs (last updated 4 months ago)
- **Place file:** `place.rbxlx` (versioned)

## Architecture map
- `ServerScriptService/Game/`
  - `WalletService.server.lua` — server-authoritative currency
  - `InventoryService.server.lua` — server-authoritative inventory
  - `TradeService.server.lua` — trading; calls Wallet + Inventory
  - `ReceiptHandler.server.lua` — MarketplaceService receipts
- `ReplicatedStorage/Shared/`
  - `Remotes/` — 8 RemoteEvent / 2 RemoteFunction
  - `Catalog.lua` — item catalog (read by both server and client UI)
  - `Types.lua` — typed Luau definitions
- `StarterPlayerScripts/`
  - `UI/HUD.client.lua` — currency / inventory display
  - `Trade/TradeUI.client.lua` — trade window
- `Workspace/`
  - Runtime instances only — clean

## Hotspots
- `TradeService.server.lua` — 480 lines, 4 of the 10 remotes, most TODO comments.
- `InventoryService.server.lua` — 320 lines, shared by many systems.

## Risks (ranked)
1. **Trade non-atomicity** (suspected) — `TradeService.server.lua:140` does grant + remove without a rollback wrapper. Possible dupe path. (Needs `roblox-security-review` to confirm.)
2. **No rate-limit on `UseItemRemote`** — could be auto-fired.
3. **Anti-slop:** `InventoryRepository` in `src/server/Inventory/`. Enterprise naming; doesn't add value over direct DataStore calls.
4. **`SetAsync` used in `WalletService:Save`** — race risk across servers if the player teleports.

## Opportunities
- `Catalog.lua` is duplicated logic across server / client paths; consolidating would simplify.
- `TradeService` has clear sub-responsibilities (offer state, lock, resolve, persist) ready to split.
- No tests on `TradeService` — easy wins available via `roblox-tdd`.

## Open questions
- What does `LegacyShim.lua` in `ServerStorage` do? Referenced by nothing I can find.
- Are there cross-server flows (`MessagingService`) I missed? Couldn't tell from the source.
- Is the `place.rbxlx` the canonical source or is the Rojo sync the source of truth?
```

## Anti-pattern checks

- ❌ Making code changes during analysis — defeats the read-only contract. Note, don't fix.
- ❌ Skimming and producing a vague "looks fine to me" — useless. Either go deep or say "couldn't analyze due to <X>".
- ❌ Listing every file with no ranking — overwhelming. Rank by impact.
- ❌ Importing assumptions from another Roblox project ("usually trade is implemented as X") — verify what THIS codebase does.
- ❌ Mixing analysis with prescription — analysis describes what's there; prescription comes later from `roblox-blueprint` / `roblox-plan`.

## Roblox-specific framing

Generic code analysis tools look at function complexity, cyclomatic counts, dependency graphs. Roblox analysis additionally requires checking:
- **Service-container layout** — code in the wrong service is a structural bug.
- **Remote inventory** — the external attack surface.
- **Persistence layout** — DataStore usage patterns.
- **Replication boundaries** — what crosses client/server, what stays put.

These are Roblox-specific because they don't exist in generic codebases.

## Handoff

- Analysis complete → user picks priorities → run `roblox-blueprint` for any planned change.
- Risks identified → `roblox-security-review` for the security ones; `roblox-code-review` for code-shape ones.
- Open questions → `roblox-deepsearch` for doc-grounded answers, or ask the user.
- Ready to act on opportunities → `roblox-plan` to sequence the work.
