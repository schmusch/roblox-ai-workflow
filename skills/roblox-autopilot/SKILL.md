---
name: roblox-autopilot
description: Use to run long-running autonomous Roblox execution — roblox-forge with autonomy turned up, minimal user checkpoints, runs until verified-complete or hard-blocked. Use when the user says "autopilot this", "run it end-to-end", "don't ask me, just build it", "keep going until done", or when an approved plan is small enough to execute without per-step approval.
domain: process
audience: creator
artifact-type: skill
---

# Roblox Autopilot

Long-running autonomous execution. `roblox-forge` with autonomy turned up: minimal user checkpoints, runs until verified-complete or hard-blocked. Reports progress at the end (or at hard blocks), not in between.

This is for the creator who said "just build it, I trust the plan" — autopilot is appropriate **when an approved plan exists** and **when the work is bounded**. It is not for vague briefs.

## When to use

- An approved `roblox-blueprint` and `roblox-plan` exist.
- The work is bounded (estimable in scope, not open-ended).
- The user explicitly invokes autopilot: "autopilot this", "run end-to-end", "don't interrupt me", "just build it", "keep going until done".
- Verification path is defined in the plan and runnable autonomously.

## When not to use

- No plan exists → run `roblox-plan` first; never autopilot from a vague brief.
- Plan has ambiguous steps → autonomy will make wrong choices.
- Security-sensitive work without explicit user authorization to autopilot → always require user gate on monetization, persistence migration, or remote-surface changes.
- Brand-new system that needs creator-vision validation → don't autopilot decisions that affect feel / direction.
- User wants step-by-step visibility — that's `roblox-forge`, not autopilot.

## What this skill produces

A full execution run:
- **Pre-flight check** — plan loaded, preconditions met, verification path runnable.
- **Execution log** — every step taken, file touched, test result, with timestamps.
- **Hard-block events** — any place autopilot stopped to wait for user (with reason).
- **Final summary** — what's done, what's verified, what was deferred, what touched files.

## Method

### 1. Pre-flight check (mandatory)

Before any autonomous step:

- **Plan loaded** — concrete steps with verification gates exist (output of `roblox-plan`).
- **Blueprint approved** — architecture is decided.
- **Verification path is runnable** — tests exist or are part of the plan; `roblox-ultraqa` gates are defined; Studio MCP (if relied on) is available.
- **No open creator-vision questions** — anything left vague in `roblox-brief` / `roblox-deep-interview` is a blocker. Autopilot does not guess creator vision.
- **Server-authority guardrails defined** — for any remote / persistence work, the plan must specify what server validation, rate-limiting, and persistence patterns to apply.
- **User explicitly authorized autopilot for this scope** — "build feature X" is not authorization to also refactor Y.

If any check fails → stop. Report the gap. Do not proceed.

### 2. Define hard-block conditions upfront

Autopilot must stop and report (not guess) when:
- A step requires a creator-vision decision not in the plan.
- A test fails for a reason the plan didn't anticipate.
- A security-relevant surface change is not pre-authorized.
- The build is broken in a way `roblox-build-fix` can't resolve autonomously.
- Repeated retry on the same step (>3 attempts) without progress.
- The user explicitly said "stop" or asked a clarifying question mid-run.

State these conditions before starting. The user sees the autopilot's stop rules.

### 3. Execute step-by-step

For each step in the plan:
- Implement the step deliverable using `roblox-forge` discipline (smallest slice, verify, iterate).
- Hit the step's verification gate. If green → next step.
- If red → debug per `roblox-build-fix` (toolchain) or `systematic-debugging` (runtime).
- If still red after 2-3 attempts → hard block; report.

Log every action concisely. Do not stop to ask the user "is this OK" for steps already in the plan.

### 4. Apply guardrails throughout

Even on autopilot, do not skip:
- **Server authority** — see `references/server-authority-rules.md`. Every remote handler must validate.
- **Anti-slop** — see `references/roblox-vocabulary.md`. Generated code must read Roblox-native.
- **Verification gates** — runtime evidence per step, captured.

Autopilot is **disciplined autonomy**, not "just type until done".

### 5. Periodic self-review (every N steps)

Every 3-5 steps:
- Re-read the original plan — are you still building what was agreed?
- Run the cumulative test suite — anything regressed?
- Sanity-check the touched files list — anything outside scope?

If scope drift detected → hard block, ask.

### 6. Final verification

After the last planned step:
- Run the full verification path defined in the plan.
- Run `roblox-ultraqa` for runtime evidence.
- If security-sensitive surfaces were touched → run `roblox-security-review`.
- Run `roblox-code-review` for cumulative diff.

### 7. Report

Final report includes:
- All steps completed (with their verification evidence).
- Hard-block events (if any).
- Final test / lint / typecheck status.
- Touched files summary.
- Deferred items / known risks / follow-ups.

User now reviews and accepts / requests changes.

## Output format

```markdown
# Autopilot run — <feature>

## Pre-flight
- Plan: `plans/<feature>.md` (loaded)
- Blueprint: `docs/blueprints/<feature>.md` (approved <date>)
- Verification: TestEZ suite + roblox-ultraqa gate

## Execution log
- 14:02 — Step 1 (WalletService skeleton): created `src/server/Wallet/WalletService.server.lua`, test green ✓
- 14:08 — Step 2 (currency types): created `src/shared/Wallet/WalletTypes.lua`, test green ✓
- 14:15 — Step 3 (PurchaseRemote validation): ... ✓
...
- 14:55 — Step 9 (full test suite): 24/24 ✓
- 14:58 — roblox-ultraqa: VERIFIED (server, replication, persistence, adversarial)

## Hard-blocks
- None.

## Final state
- All planned steps complete.
- Tests: 24/24
- Lint: clean
- Touched files: 12 (listed)
- Deferred: WalletService cross-server sync via MessagingService (out of scope per plan)

## Ready for review
- `roblox-code-review` recommended (cumulative diff is non-trivial)
- `roblox-security-review` recommended (touches monetization surface)
```

## Anti-pattern checks

- ❌ Autopilot from a vague brief — produces wrong things fast.
- ❌ Skipping the pre-flight check because "the plan looks fine" — caught issues are cheaper than rework.
- ❌ Suppressing test failures to "make progress" — autopilot becomes a slop factory.
- ❌ Skipping the periodic self-review — scope drift compounds.
- ❌ Hard-block events the user never sees — invisible failures are worse than visible ones.
- ❌ Treating autopilot as "no review needed" — final review is still mandatory.
- ❌ Autopiloting through security-relevant changes without user gate.

## Roblox-specific framing

Generic autonomous execution assumes a hosted target with a clear "deploy" event. Roblox autopilot:
- Requires `roblox-ultraqa` runtime verification at gates, not just unit tests.
- Cannot autopilot through `MarketplaceService` / persistence migrations without explicit user gate (real-money risk).
- Server-authority guardrails are mandatory at every state-mutation step.
- Studio MCP availability changes the autonomy ceiling — with Studio access, runtime verification can happen autonomously; without it, autopilot must defer verification to the user.

## Handoff

- Autopilot complete + verified → user review and acceptance.
- Hard block → user reads the report, decides whether to clarify / re-plan / take over manually.
- Autopilot revealed plan gaps → `roblox-plan` revision before next attempt.
- Autopilot ran into recurrent build issues → `roblox-build-fix` for the toolchain, then retry.
