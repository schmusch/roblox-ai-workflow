---
name: roblox-code-review
description: Use to review Luau / Roblox code for server-authority holes, anti-slop violations, replication mistakes, and Roblox-specific bugs before merge. Use when the user says "review this code", "code review", "review the PR", "audit this script", "is this server-safe", or after roblox-forge ships a non-trivial change.
domain: quality
audience: creator
artifact-type: skill
---

# Roblox Code Review

Structured code review for Luau / Roblox work. Goes deeper than a generic review because Roblox has three specific failure modes generic reviewers miss:

1. **Server-authority holes** — code that trusts client-sent values for canonical state.
2. **Enterprise-jargon slop** — `Controller` / `Repository` / `DTO` smell inside Luau.
3. **Replication mistakes** — wrong service container, wrong remote direction, wrong ownership.

This skill is the merged version of generic code-review and Roblox-specific review. There is no separate `roblox-review` — this covers both code and adjacent artifacts.

## When to use

- After `roblox-forge` lands a non-trivial change.
- Before merging an AI-assisted PR.
- When the user says "review", "audit", "go over the code", "is this safe".
- When inheriting an unfamiliar Roblox codebase and you need a first-pass assessment.

## When not to use

- The code is still being written → wait for a checkpoint.
- The change is a one-line typo fix → overkill.
- The work needs verification of runtime behavior, not code-shape critique → use `roblox-ultraqa` instead.
- The work is a security-focused exploit-vector audit → use `roblox-security-review` instead (this skill calls it out but doesn't go as deep).

## What this skill produces

A structured review report with:
- **Blockers** — must-fix before merge (server-authority holes, dupe risk, DataStore unsafety, crashes).
- **Strong-recommend** — should-fix (anti-slop, replication awkwardness, missing rate-limits).
- **Nits** — style / naming polish.
- **Praise** — what was done well (keep the team learning what "good" looks like).

Plus a one-line verdict: **APPROVE / REQUEST CHANGES / NEEDS DISCUSSION**.

## Method

### 1. Scope intake

Before reading code, confirm:
- Which files / scripts are in scope.
- What the change is supposed to do (read the blueprint, the PR description, or ask).
- What verification the author already ran (tests? Studio playtest? lint?).

If scope is unclear, stop and ask. Reviewing without context produces noise.

### 2. Read the diff structurally

For each touched file, classify:
- **Server-only** (`ServerScriptService`, `ServerStorage`) — authority lives here.
- **Client-only** (`StarterPlayer`, `StarterGui`) — input + display.
- **Shared** (`ReplicatedStorage`) — types, configs, pure logic.
- **Runtime** (`Workspace`) — instances; should not contain logic.

Flag immediately:
- A `Script` (server) inside `StarterPlayerScripts` (won't replicate as server).
- A `LocalScript` inside `ServerScriptService` (won't run).
- A `ModuleScript` containing server secrets placed in `ReplicatedStorage` (visible to clients).

### 3. Server-authority audit (mandatory)

Consult `references/server-authority-rules.md`. Walk every `OnServerEvent` / `OnServerInvoke` handler in the diff and ask:

- Is **every parameter** type-checked?
- Is **ownership** validated (does this player actually own that item / unit)?
- Is **range / bounds** validated (price > 0, qty > 0, qty <= stack max)?
- Is **rate-limit** applied?
- Does the server **read its own canonical state**, not echo client claims?
- Does the server **mutate authoritative state** itself, not delegate to the client?

If any of these fail → **BLOCKER**.

For DataStore work specifically:
- `SetAsync` instead of `UpdateAsync` on race-prone keys → **BLOCKER**.
- Save without retry + backoff → **STRONG-RECOMMEND**.
- DataStore write triggered directly inside `OnServerEvent` with no validation layer → **BLOCKER**.

For MarketplaceService:
- `ProcessReceipt` returns `PurchaseGranted` before grant is durably persisted → **BLOCKER** (refund risk on rollback).
- Missing idempotency on `PurchaseId` → **BLOCKER** (Roblox retries — double-grant risk).

For trading / transfers:
- Non-atomic grant + remove → **BLOCKER** (dupe risk).
- Trade resolution accepting client input after lock → **BLOCKER**.

### 4. Anti-slop pass

Consult `references/roblox-vocabulary.md`. Scan for:
- `Controller` (when not a literal Roblox controller object).
- `Repository` / `DAO` / `<X>Repo` naming.
- `<X>Service` where `<X>` is not a real Roblox engine service.
- `DTO`, `ViewModel`, `BaseClass`, `AbstractFactory`.
- `Manager`, `Handler` when vague (no concrete domain).
- Folders like `controllers/`, `repositories/`, `dtos/`.
- Inheritance hierarchies where composition would do.

For each match → **STRONG-RECOMMEND**: rename or restructure per `roblox-anti-slop`. Cross-reference that skill in the review comment.

### 5. Replication audit

For each `RemoteEvent` / `RemoteFunction` in the diff:
- Is the direction correct? (Client→server: validate. Server→client: canonical update. `RemoteFunction` server→client should be avoided.)
- Is the remote stored where both ends can see it (`ReplicatedStorage`)?
- Is the payload reasonable size (not a 10MB table)?
- Is there a rate-limit on the server handler?

For replication via Attributes / replicated values:
- Are sensitive values (currency, inventory) replicated via server-authoritative attributes only, not client-writable state?
- Is the client UI reading the replicated state, not maintaining its own shadow copy?

### 6. Roblox-specific bug patterns

Walk for these common pitfalls:
- `wait()` calls in tight loops (deprecated, use `task.wait()`).
- `spawn` / `delay` (deprecated, use `task.spawn` / `task.delay`).
- Missing `task.cancel` on long-running coroutines tied to player session.
- `Players.PlayerRemoving` save without `BindToClose` flush → data loss on shutdown.
- `:Connect` calls without disconnect on cleanup → memory leak / ghost handlers.
- `:WaitForChild` with no timeout in code that may legitimately fail → infinite yield.
- Workspace iteration without `:GetChildren()` snapshot → mid-iteration mutation bugs.
- Streaming-disabled assumptions in StreamingEnabled places.

### 7. Test / verification audit

- Did the author add or update tests for the change?
- If runtime behavior changed (remotes, persistence, replication), is there evidence it was actually run in Studio (`execute_luau` output, `screen_capture`, `get_console_output`)?
- Lint / typecheck clean? (`selene`, `luau-lsp`, `stylua`)

If runtime-behavior changed and there's no runtime evidence → **STRONG-RECOMMEND**: run `roblox-ultraqa` before merge.

### 8. Synthesize the verdict

Group findings by severity. State the verdict in the first line of the report so a busy reader sees it immediately.

## Output format

```markdown
## Code Review — <feature / PR title>

**Verdict:** APPROVE / REQUEST CHANGES / NEEDS DISCUSSION

### Blockers
- `src/server/Trade/TradeRemote.server.lua:42` — `OnServerEvent` handler reads `itemId` from client without ownership check. Player can trade items they don't have. Fix: server reads inventory before transfer.

### Strong-recommend
- `src/shared/Inventory/InventoryController.lua` — name "Controller" is enterprise slop. Rename to `InventoryModule`. See `roblox-anti-slop`.
- `src/server/Economy/Wallet.server.lua:88` — no rate-limit on `RequestPurchaseRemote`. Add the rate-limit pattern from `references/server-authority-rules.md`.

### Nits
- `src/client/UI/HUD.client.lua:12` — uses `wait()` instead of `task.wait()`. Trivial swap.

### Praise
- `TradeService` uses `UpdateAsync` with retry — exactly right.
- Server-authority pattern in `WalletService` is textbook.

### Verification ran
- selene: clean
- luau-lsp: clean
- TestEZ: 14/14 passed
- Runtime (in-Studio): trade flow verified for happy-path; adversarial path NOT tested → run roblox-ultraqa before merge.
```

## Anti-pattern checks (meta — for the reviewer)

- ❌ Reviewing without reading the surrounding context — false positives.
- ❌ Listing 50 nits and burying the one real blocker — readers miss the blocker.
- ❌ Praising nothing — team loses signal on what good looks like.
- ❌ Approving without running the server-authority audit on remote handlers.
- ❌ Reviewing only code-shape and skipping runtime verification when behavior actually depends on replication.

## Roblox-specific framing

Generic code review checks naming, structure, complexity, tests. **Roblox code review additionally requires** the server-authority audit, the replication-direction audit, and the anti-slop pass. Without those three, the review is incomplete — a passing generic review can still ship an exploitable game.

The three Roblox-specific gates are not optional:
1. Server-authority — see `references/server-authority-rules.md`.
2. Replication direction — see service-container rules above and `references/roblox-vocabulary.md`.
3. Anti-slop — see `references/roblox-vocabulary.md` and the `roblox-anti-slop` skill.

## Handoff

- If verdict is **APPROVE** with no blockers → ready to merge.
- If verdict is **REQUEST CHANGES** with blockers → hand back to author (or `roblox-forge` if iterating in-session).
- If runtime behavior changed without runtime evidence → run `roblox-ultraqa` first.
- If security-sensitive surfaces were touched (remotes, persistence, trading, marketplace) → also run `roblox-security-review` for the deeper exploit-vector pass.
