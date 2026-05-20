---
name: roblox-ultraqa
description: Use to verify Roblox work is actually complete via runtime evidence, not static inspection. Use when about to claim a feature is "done", before merging, before declaring a bug fixed, when the user says "verify this works", "prove it's done", "test it for real", "ultraqa", or any time replication / persistence / remote behavior is in scope.
domain: quality
audience: creator
artifact-type: skill
---

# Roblox UltraQA

Verification before completion. Replaces the temptation to declare "done" from static inspection with a discipline of runtime evidence.

The principle: **evidence before assertions, always.** If a feature depends on replication, remotes, or DataStore, you have not verified it from static inspection. You must run it.

## When to use

- About to claim a feature, fix, or change is complete.
- Before merging an AI-assisted change.
- Before declaring a bug fixed.
- The user says "verify it works", "prove it", "test it for real", "actually run it".
- The change touches: remotes, persistence, replication, economy, combat, MarketplaceService, trading, or any cross-context behavior.

## When not to use

- Purely cosmetic asset / UI tweak with no logic change → a screenshot is enough, no full QA needed.
- Static-only refactor where the lint / typecheck / unit tests already cover the behavior change exhaustively.
- The change is so trivial (single-line typo, comment edit) that runtime verification adds noise.

## What this skill produces

A verification report:
- **Verification path** — what was tested and how.
- **Evidence** — actual outputs: console logs, screenshots, test results, state snapshots.
- **Adversarial path** — what malicious / unexpected input was tested (if the feature has a security surface).
- **Verdict** — VERIFIED / PARTIAL / NOT VERIFIED.

Plus a list of **untested gaps** so the user / next iteration can decide whether to deepen.

## Method

### 1. Re-read the change

Before verifying, re-read what changed. Pull the diff or list of touched files. Understand the **behavior** the change asserts, not just the lines.

### 2. List the verification surfaces

For the changed behavior, what is the runtime evidence you'd need to convince a skeptical reviewer?

- **Unit / module tests** — pure logic
- **Lint / typecheck** — `selene`, `luau-lsp`, `stylua`
- **Runtime in-Studio probe** — `execute_luau` for server-state changes
- **Replication check** — does the client actually receive what the server intended to push?
- **Persistence check** — leave, rejoin, confirm state restored
- **UI check** — `screen_capture` for visual changes; `roblox-visual-verdict` for reference comparisons
- **Console check** — `get_console_output` for warnings / errors / unexpected prints
- **Adversarial check** — invalid payload, missing parameter, malicious value (server should reject cleanly)

Pick the **minimum sufficient set** for the change. Do not test the entire game when one feature changed.

### 3. Run each surface and capture evidence

Use available Roblox Studio integration if present. Common patterns (see `references/studio-mcp-cheatsheet.md`):

- **Server state check** — `execute_luau` in server context calling the changed function and printing the result; capture output.
- **Replication check** — call the server function, then `execute_luau` in client context to read the replicated attribute / value.
- **UI check** — start Play Solo via `start_stop_play`, then `screen_capture`.
- **Console check** — `get_console_output` after triggering the behavior.
- **Persistence check** — write something, stop Play, restart Play, read it back.

If Studio MCP is unavailable: write the verification steps as concrete instructions the user runs, and ask for paste-back of console / screenshots.

### 4. Run the adversarial path (mandatory for security-touching changes)

If the change touches: a `RemoteEvent` / `RemoteFunction`, persistence, currency, inventory, trading, marketplace, combat damage — you **must** run at least one adversarial test:

- Call the remote with the wrong type (string where number expected).
- Call with out-of-range value (negative qty, zero price).
- Call referencing an entity the player doesn't own.
- Call faster than the rate-limit allows.

Expected outcome: **server rejects cleanly** (silent return or structured error), no state mutation, no crash.

If the adversarial path mutates state → **NOT VERIFIED**, the change has a server-authority hole. Loop back to `roblox-forge` or `roblox-security-review`.

### 5. Capture evidence inline

Don't claim a check passed without quoting the evidence. Even a one-line console output beats a vague "tested fine".

```text
> execute_luau (server): print(WalletService:GetBalance(testPlayer))
< 1500

> Adversarial: WalletRemote:FireServer("not a number")
< Server console: [WalletService] Rejected invalid amount: "not a number"
< Server state: balance unchanged (still 1500) ✓
```

### 6. Synthesize the verdict

- **VERIFIED** — all relevant surfaces tested with evidence, adversarial path clean (if applicable).
- **PARTIAL** — some surfaces tested, others remain. List the gaps.
- **NOT VERIFIED** — runtime check failed, or critical surface not testable yet. Stop. Do not claim done.

## Output format

```markdown
## UltraQA — <feature / change>

**Verdict:** VERIFIED / PARTIAL / NOT VERIFIED

### Verification path
- Unit tests: `TestEZ ProgressionTests` — 8/8 passed
- Lint: `selene` clean, `luau-lsp` clean
- Runtime (server): `execute_luau` called `ProgressionService:GrantXp(testPlayer, 500, "qa")` → returned, Player.Level attribute changed from 3 → 4
- Replication: `execute_luau` (client) read `LocalPlayer:GetAttribute("Level")` → 4 ✓
- Console: no warnings or errors
- Persistence: stopped Play, restarted, level still 4 ✓
- Adversarial: `ProgressionService:GrantXp(testPlayer, -100, "exploit")` → server logged rejection, no state change ✓

### Untested gaps
- Cross-server XP grant via `MessagingService` not yet exercised — would need second server.
- Rebirth flow not tested in this pass (out of scope of this change).

### Evidence captured
- console output above
- screenshot of HUD level display: `qa/progression-level4.png`
```

## Anti-pattern checks (meta)

- ❌ "Static review looks good, marking done." — not verified.
- ❌ Running only the happy path. Adversarial input is part of the contract.
- ❌ Capturing a screenshot of code, not of behavior.
- ❌ Verifying in dev with cached state from a previous test — restart the relevant Studio session for cleanliness.
- ❌ Claiming "all tests pass" without naming which tests ran.
- ❌ Verifying server changes only in server context when client-replication is also part of the behavior.

## Roblox-specific framing

Generic verification typically means: run the unit tests, check the lint, mark done. **Roblox verification additionally requires** confirming:
1. Replication boundary actually moved state correctly across server/client.
2. DataStore actually persists and restores correctly.
3. Remote handlers reject adversarial input cleanly.

These three are runtime-only. No static analysis catches them all. You must run code in Studio (or coordinate with the user to do so).

## Handoff

- **VERIFIED** → ready to claim done; hand back to the user or the next workflow step (review / commit / ship).
- **PARTIAL** → list gaps, decide with the user whether to deepen now or defer with explicit acknowledgement.
- **NOT VERIFIED** → loop back to `roblox-forge` (implementation) or `roblox-build-fix` (debugging) with the failing evidence.
- For deeper code-shape critique alongside verification → run `roblox-code-review`.
- For deeper exploit-vector audit on security-touching changes → run `roblox-security-review`.
