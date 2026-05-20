---
name: roblox-security-review
description: Use to audit Roblox code for exploit vectors — remote validation gaps, dupe paths, marketplace receipt mishandling, persistence abuse, rate-limit gaps, and other live-game attack surfaces. Use when the user says "security review", "audit for exploits", "is this exploitable", "check for dupes", "audit before launch", or before any non-trivial monetization / trading / persistence change ships.
domain: quality
audience: creator
artifact-type: skill
---

# Roblox Security Review

Exploit-vector audit specialised for Roblox. Generic security reviews check for SQL injection, XSS, secrets in repo — none of which is the threat model on Roblox.

The Roblox threat model is:
- **Client exploit tools** (Synapse, Krnl, etc.) can call any RemoteEvent with arbitrary payloads.
- **Memory editors** can read / write client-side values freely.
- **Network sniffers** see all replicated state the client receives.
- **Multi-account / alt-farming** can defeat rate-limits and identity checks.

This skill audits against the Roblox threat model and produces a prioritised exploit findings list.

## When to use

- Before launching or major-update-shipping monetization, trading, persistence, or competitive systems.
- After `roblox-code-review` flags security-sensitive surfaces.
- When the user says "audit for exploits", "is this exploitable", "check for dupes", "secure this", "before launch".
- Periodically on live games handling real player progression / money.

## When not to use

- Non-game-impact UI polish, cosmetic-only changes, or static-data tuning → overkill.
- The code is still being designed (no remotes / persistence written yet) → use `roblox-blueprint` to design security in from the start, then audit later.
- General code-quality review (naming, structure, anti-slop) → use `roblox-code-review`.

## What this skill produces

A structured exploit-vector findings list:
- **Critical** — actively exploitable; could cause currency / item duplication, account compromise, server crashes, persistent player harm.
- **High** — exploitable with some setup; could cause economic damage or unfair advantage.
- **Medium** — exploitable but limited blast radius; nuisance or recoverable.
- **Low** — theoretical / requires unrealistic conditions.

Plus a one-line verdict: **CLEAR / FIX BEFORE LAUNCH / DO NOT SHIP**.

## Method

Walk the audit checklist in `references/roblox-security-audit-checklist.md` step by step. For each finding, document:
- **Location** (`path:line`)
- **Attack** — what a malicious client does
- **Impact** — what they get / break
- **Fix** — the specific code change

### 1. Remote surface inventory

List every `RemoteEvent` and `RemoteFunction` in the touched code. For each:
- Direction (client→server, server→client, request-response)
- What payload it accepts
- What state it mutates
- What identity check it performs

If you can't quickly say what a remote does, it's already a finding.

### 2. Per-remote validation audit

For each client→server remote, confirm:
- ✅ Type check on every parameter (`typeof(x) == "number"`)
- ✅ Range / bounds check (positive, within expected min/max)
- ✅ Ownership check (does this player own the referenced entity?)
- ✅ Authorization check (does this player have permission for this action?)
- ✅ Rate-limit (server-tracked, per-player, per-remote)
- ✅ Server reads canonical state, doesn't trust client-supplied state values

Missing any of these → **High** to **Critical** depending on what's mutated.

### 3. Economy & inventory abuse paths

Walk every code path that changes currency, inventory, equipped state, or grants items. Ask:
- Can a player trigger a grant without paying the corresponding cost?
- Can a player trigger a payment without receiving the grant (server crash mid-flow → DataStore writes one but not the other)?
- Can two simultaneous calls produce duplication (race between read and write)?
- Can a trade resolve such that both sides end up with both copies (non-atomic)?
- Can a player drop an item, log out, log back in, and still have a phantom copy?

Each of these is a **dupe path** if true. Dupe paths are **Critical**.

Atomicity test: every economic mutation must be a single server-tick state change that either fully completes or fully reverts. No "grant first, then deduct" without rollback. No "deduct first, then grant" without rollback.

### 4. Persistence abuse

Walk every DataStore read/write. Ask:
- Is the save key tied to `userId` (the only stable identifier — `Player.Name` changes)?
- Is `UpdateAsync` used for race-prone fields (currency, inventory, level)?
- Is there retry-with-backoff on throttle errors?
- Is there a `BindToClose` flush on server shutdown?
- On load failure, does the code refuse-to-grant-state rather than giving a fresh save (which would let players "reset" by triggering load failures)?
- Is data sanitised on load (in case a corrupted save shipped a value out of bounds)?

Missing protection → **High**. Refusing to handle load failure correctly → **Critical** (rollback exploit).

### 5. MarketplaceService receipts

Walk `ProcessReceipt`:
- ✅ Idempotent on `PurchaseId` (Roblox retries) — same `PurchaseId` must produce the same outcome, no double grant.
- ✅ `PurchaseGranted` returned **only** after the grant is durably persisted to DataStore.
- ✅ On grant failure, returns `NotProcessedYet` so Roblox retries later.
- ✅ Receipts processed even for offline players (use `MessagingService` or queue if needed).

Each missing protection on a receipt path is at least **High**, often **Critical** for real-money flows.

### 6. Trading & player-to-player transfer

If trading or gifting exists:
- Lock state once both confirm — no client input accepted after lock.
- Atomic dual-update on resolution: both sides update or neither does.
- Server validates **both** sides' offers against server-canonical inventory at resolution time, not at offer time.
- Trade cancellation safely returns offered items to original owners.
- No way to mid-trade disconnect and dupe.
- Rate-limit on trade requests (anti-spam).
- No way for a third party to inject into the trade session.

Any gap → **Critical**.

### 7. Rate-limit completeness

For every player-facing remote, persistent action, expensive query:
- Per-player rate-limit on the server.
- Limit survives reconnect (track by `userId`, not socket).
- Cooldowns enforced before the work, not after.
- Multi-account abuse: if rate-limits trivially defeated by alt accounts, the design itself is weak — flag as **Medium** with design discussion needed.

### 8. Replication leakage

Walk what the client receives:
- Are server-only secrets (admin lists, exploit-detection thresholds, anti-cheat code, server tokens) accidentally placed in `ReplicatedStorage` or `Workspace`?
- Are server-only ModuleScripts referenced from client scripts (they won't run, but the source is replicated)?
- Are debug / admin RemoteEvents exposed to all clients (anyone with the right payload triggers admin actions)?

Anything leaked → **High** to **Critical** depending on sensitivity.

### 9. RemoteFunction server→client

`RemoteFunction:InvokeClient` is dangerous: the server yields on the client. A malicious client can:
- Yield forever → stall the server thread that called it.
- Throw arbitrary errors → propagate as server-side errors.

Any `:InvokeClient` call → **High** unless wrapped in `task.spawn` + timeout, and even then question whether it's needed.

### 10. Anti-cheat surface (optional, advanced)

If the game has competitive / leaderboards / PvP, also audit:
- Server-authoritative movement (or at minimum sanity-checked speed / teleport detection).
- Server-authoritative damage with reachability + cooldown + weapon-equipped checks.
- Anomaly detection (impossible XP gain rate, impossible currency gain rate).
- Logging for forensics — when something looks exploited later, can you tell who did what?

## Output format

```markdown
## Security Review — <system / PR>

**Verdict:** CLEAR / FIX BEFORE LAUNCH / DO NOT SHIP

### Critical
1. **Trade dupe** — `src/server/Trade/TradeService.server.lua:88` — Grant is non-atomic with remove. A disconnect between lines 88 and 92 leaves the giver with the item AND the receiver gets a copy. **Fix:** Wrap grant + remove in a pcall with explicit rollback, or use a transaction-style state buffer.

2. **Receipt double-grant** — `src/server/Marketplace/ReceiptHandler.server.lua:34` — `PurchaseGranted` returned before DataStore write resolves. If write fails, Roblox does NOT retry. **Fix:** Persist first, return `PurchaseGranted` only after `UpdateAsync` returns successfully.

### High
1. **Missing rate-limit** — `src/server/Inventory/UseItem.server.lua:12` — `UseItemRemote.OnServerEvent` has no rate-limit. Auto-fire client can drain consumables on alts. **Fix:** Add per-player rate-limit at 5/sec (or item-specific).

### Medium
- ... (per-remote findings)

### Low
- ... (theoretical / design discussion)

### Findings cleared
- All persistence uses `UpdateAsync` with retry.
- Trade lock state is server-controlled, not client-controlled.
- No `:InvokeClient` calls.
- No server-only modules in `ReplicatedStorage`.
```

## Anti-pattern checks (meta)

- ❌ Pattern-matching code without thinking about what the attacker actually wants.
- ❌ "It's not exposed yet" — if the remote exists, it's exposed.
- ❌ Trusting `RunService:IsStudio()` as a security gate — clients can fake it client-side, irrelevant on server but still confusing.
- ❌ Hashes / "obfuscation" of client-side values — not security; remove the value from client entirely if it matters.
- ❌ Claiming "this is fine, only friends can call it" — friend-only access doesn't exist on the network layer.

## Roblox-specific framing

The biggest difference from generic security review:
- **No SQL / no XSS** — there are no SQL databases or HTML targets.
- **Trust boundary is client-server** — and the client is fully compromised by default.
- **Most exploits are about state mutation paths**, not data exfiltration.
- **DataStore is the database** — corruption / rollback / race is the persistence-layer threat model.
- **Roblox retries `ProcessReceipt`** — idempotency on `PurchaseId` is not optional.

The checklist in `references/roblox-security-audit-checklist.md` is the canonical source. Skills do not duplicate that content; review it directly.

## Handoff

- **CLEAR** → ship.
- **FIX BEFORE LAUNCH** → hand back with the findings list; iterate with `roblox-forge`.
- **DO NOT SHIP** → critical findings exist that change the design, not just the code. May need `roblox-blueprint` revision.
- For runtime-verifying that fixes actually closed the hole → `roblox-ultraqa` with adversarial test cases.
