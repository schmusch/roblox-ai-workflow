---
name: roblox-ultrawork
description: Use for extreme-verification Roblox execution — every step gets the full roblox-ultraqa runtime + adversarial proof before continuing. Use when the user says "ultrawork", "extreme verification", "I can't afford bugs in this", "do this right, no shortcuts", or for changes touching real-money monetization, persistence migration, competitive PvP integrity, or any surface where a bug ships harm.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Ultrawork

`roblox-forge` with extreme verification turned on. Every step gets the full `roblox-ultraqa` runtime + adversarial verification before moving to the next. Slower, but produces ship-ready output for surfaces where bugs cause real harm:

- **Monetization** — receipt mishandling can charge players without granting, or grant without charging.
- **Persistence migration** — wrong shape change wipes player data.
- **Competitive PvP** — server-authority gaps create unfair games.
- **Trading / economy** — dupe paths damage market integrity.

For everything else, regular `roblox-forge` with `roblox-ultraqa` at the end is enough.

## When to use

- Changes to `ProcessReceipt`, `MarketplaceService` flows, gamepass / dev-product grants.
- Persistence schema migrations (changing the shape of saved data).
- Competitive game systems (PvP combat, ranked leaderboards).
- Trading / player-to-player transfer logic.
- Any change the user said "no bugs in this", "ultrawork", "extreme care".
- Any change to systems that, if broken, would require a manual rollback or refund.

## When not to use

- Normal feature work → `roblox-forge` + `roblox-ultraqa` at the end is the right cost.
- Pure UI / cosmetic / asset work — overkill.
- Prototype work — extreme verification on throwaway code wastes time.
- The change has no plan yet — `roblox-plan` first.

## What this skill produces

Per-step verified execution:
- Each step's deliverable.
- **Each step's runtime + adversarial proof** (not deferred to the end).
- Cumulative state of the test suite + lint + Studio runtime.
- Defensive evidence trail — what was tested, what passed, what was deferred (and why).

## Method

The execution loop is `roblox-forge`'s, but the verification gate after each step is `roblox-ultraqa` in full, not just a quick check.

### 1. Pre-flight

Same as `roblox-autopilot`'s pre-flight, plus:
- The user understands this is slow — extreme verification ≠ extreme speed.
- The plan's verification gates are realistic (a `MarketplaceService` test can't be fully simulated in Studio without a test product; design verification accordingly).
- Adversarial test inputs are defined upfront — see `references/roblox-security-audit-checklist.md` for the standard set per attack surface.

### 2. Per-step execution

For each step in the plan:

1. **Implement the step** — minimal slice, server-authoritative, anti-slop.
2. **Run static verification** — lint, typecheck, unit tests.
3. **Run runtime verification** — `execute_luau` server probe, replication check, persistence check (per `roblox-ultraqa` method).
4. **Run adversarial verification** — invalid type, out-of-range, unauthorized, rate-limit overflow, race conditions.
5. **Capture evidence** for all three above. No "I'm sure it works" claims — show the output.
6. **Document deferred items** — anything you can't verify autonomously gets a deferred-item note. The user sees it and decides.

If any verification step fails → fix and re-verify the **same step** before continuing. Do not move forward with red.

### 3. Per-step adversarial set

For the typical attack surfaces, the standard adversarial set is:

**Remote handler:**
- `nil` payload
- Wrong-type payload (string for number, table for string)
- Out-of-range value (negative qty, zero, very large)
- Reference to entity not owned by caller
- Reference to non-existent entity
- Rapid-fire (rate-limit overflow)
- Concurrent fire from two clients (race condition)

**Persistence:**
- Load fail (simulate `pcall` failure)
- Concurrent write from same userId (two servers)
- Save during shutdown (`BindToClose` flush)
- Corrupted load value (out of bounds)

**Marketplace `ProcessReceipt`:**
- Duplicate `PurchaseId` (Roblox retry simulation)
- Persistence failure between charge and grant
- Player offline at process time

**Trade:**
- Disconnect mid-trade
- Modify offer after lock (should reject)
- Third-party tries to inject into session
- Concurrent same-item offer from both sides

For each, **the expected outcome is "server rejects / handles gracefully, state remains consistent"**. If state mutates inappropriately → blocker.

### 4. Cumulative checkpoint every N steps

Every 3 steps, run:
- Full test suite.
- Lint + typecheck.
- A "soak test" — run the full happy-path flow once end-to-end in Studio.

If anything regressed → stop. Find the cause. Fix. Re-verify. Don't accumulate red.

### 5. Final verification

After the last step:
- Full `roblox-ultraqa` pass on the whole feature.
- `roblox-security-review` if any security-sensitive surface was touched (almost always true in ultrawork scope).
- `roblox-code-review` on the cumulative diff.

### 6. Report

Report includes:
- Per-step verification evidence.
- Adversarial set results.
- Cumulative checkpoints.
- Final review verdicts.
- Deferred items with rationale.

## Output format

```markdown
# Ultrawork run — <feature>

## Step 1: ProcessReceipt skeleton
- Deliverable: `src/server/Marketplace/ReceiptHandler.server.lua` with handler stub
- Static: selene clean, luau-lsp clean, unit test (mock receipt) ✓
- Runtime: `execute_luau` invoked `ReceiptHandler:Process(testReceipt)` → returned `NotProcessedYet` (correct, no grant config yet) ✓
- Adversarial:
  - Receipt with missing `PurchaseId` → handler returned `NotProcessedYet` cleanly ✓
  - Receipt with unknown `ProductId` → handler logged + returned `NotProcessedYet` ✓
- Status: GREEN

## Step 2: Grant flow + persistence
- Deliverable: ...
- Static: ...
- Runtime: ...
- Adversarial:
  - Persistence failure (mocked DataStore error) → handler returned `NotProcessedYet` (Roblox will retry) ✓
  - Duplicate `PurchaseId` (called twice with same ID) → only one grant ✓
- Status: GREEN

... (per step)

## Cumulative checkpoint after step 3
- Suite: 18/18 ✓
- Soak test (happy path): 5 purchases processed end-to-end, all granted, all persisted ✓

## Final
- ultraqa: VERIFIED
- security-review: CLEAR
- code-review: APPROVE
- Touched files: 6
- Deferred: cross-server receipt processing for offline-at-process-time players (out of scope per plan; tracked as follow-up)
```

## Anti-pattern checks

- ❌ Saying "I ran the adversarial set" without quoting the actual evidence per case.
- ❌ Batching verification to the end "to save time" — defeats the per-step discipline.
- ❌ Skipping the cumulative checkpoint — regressions compound silently.
- ❌ Treating "test was hard to set up" as a valid reason to skip — for ultrawork-scope changes, the test setup is part of the work.
- ❌ Deferring the security review on a monetization / persistence change — exactly when security review matters most.
- ❌ Adversarial set that's "I checked it works" — adversarial means the worst-case input set, written out.

## Roblox-specific framing

Generic extreme-verification is "more tests, more checks". Roblox-specific overlays:
- **Per-attack-surface adversarial set** is well-known and reusable; see `references/roblox-security-audit-checklist.md`.
- **`MarketplaceService` idempotency** is a non-negotiable check — Roblox retries `ProcessReceipt` and the code must handle that correctly.
- **Persistence migration tests** require simulating both load-success and load-failure paths; both branches must be safe.
- **Studio runtime is the only proof for replication / persistence / receipt behavior** — static analysis cannot catch these failures.

## Handoff

- Ultrawork complete, all reviews CLEAR / APPROVE → ready to ship.
- Some step's adversarial set failed → loop back to the failing step. Do not advance.
- Plan revealed gaps mid-execution → return to `roblox-plan` for revision.
- Final review found blockers → loop to `roblox-forge` for fixes, then re-verify the affected steps.
