---
name: roblox-blueprint-loops
description: Use during blueprint planning when the feature is a reward, daily, or event loop. Designs the loop structure as a composable spec — entry condition, beat sequence, reward schedule, fail state, recovery path, burnout guardrail. Use when the user says "design the daily login", "plan the event arc", "set up the reward schedule", or any time-cadenced engagement system.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Blueprint — Loops

Blueprint deepening skill for **time-cadenced engagement loops**: reward loops (per-action), daily loops (per-day), event loops (per-event-window).

## When to use

- The feature is or contains a reward schedule, daily login chain, weekly quest, season pass, limited event, comeback bonus, streak system.
- The plan needs explicit reward cadence + fail recovery design before forge can implement.

## When not to use

- The feature is a one-shot transaction (purchase, single craft).
- No time / event cadence is involved.

## What this skill produces

A loop spec per loop in scope:

1. **Loop type** — reward / daily / event / streak / hybrid.
2. **Entry condition** — what triggers the player into the loop.
3. **Beat sequence** — the ordered touchpoints (e.g. login → claim → mission → reward → progress bar).
4. **Reward schedule** — what reward, at what beat, at what magnitude.
5. **Fail state** — what happens on miss / loss / disconnect.
6. **Recovery path** — how the player gets back in after a fail.
7. **Burnout guardrail** — what stops engagement from becoming exhausting / manipulative.
8. **End condition** — when the loop closes (event end, season reset, prestige).
9. **Replication / persistence shape** — server-authoritative state shape, DataStore keys, attributes replicated to client.
10. **UI surfaces** — what the player sees, where, and when.

## Method

### 1. Identify the loop type

- **Reward loop** — micro-cadence per action (kill → XP, craft → progress, mission → currency).
- **Daily loop** — once-per-day cadence (login bonus, daily quest, streak).
- **Event loop** — bounded window cadence (weekend event, season, raid week).
- **Streak loop** — escalating reward tied to consecutive engagement; can layer on top of daily or reward.

A feature may stack multiple — note explicitly.

### 2. Design the beat sequence

Sketch the player journey through one cycle. Example for a daily loop:
1. Player joins → login detected → server checks last claim date
2. If claimable → UI toast + claim button
3. Player clicks claim → server validates + writes to DataStore + grants reward
4. Server pushes updated streak count
5. Client UI shows new streak + tomorrow's preview reward

Each beat is a verification point.

### 3. Design the reward schedule

For a streak / cadence loop, lay out the schedule explicitly:

| Day | Reward | Notes |
|-----|--------|-------|
| 1 | 100 coins | low barrier |
| 2 | 200 coins | |
| 3 | 500 coins + booster | first significant payoff |
| 4 | 800 coins | |
| 5 | 1500 coins | mid-anchor |
| 6 | 2000 coins | |
| 7 | rare cosmetic | week capstone |

Then repeat / scale / reset per the loop type.

### 4. Define fail state + recovery

- **Daily loop:** miss a day → does the streak reset entirely, freeze, drop one tier, or auto-forgive?
- **Event loop:** can't complete during window → progress lost? carries over? partial reward?
- **Reward loop:** failed mission → currency cost / cooldown / nothing?

**Default recommendation:** soft fail (freeze, drop one tier, partial credit) over hard fail (reset to zero). Hard fail erodes trust quickly on Roblox.

### 5. Define burnout guardrail

- Daily caps on rewards (per-day claim limit).
- Cooldowns between high-value rewards.
- Event-pass progress caps so a single play session can't complete the whole pass.
- "Catch-up" mechanic so missed days don't permanently lock out late joiners.

### 6. Define end condition

- Streak: indefinite or capped at N days then resets / unlocks prestige tier?
- Daily quests: rotate at server midnight UTC (or per-player local midnight)?
- Event: hard end timestamp; what happens to incomplete pass slots?

### 7. Replication / persistence shape

For each loop, name the data the server owns:

```luau
type DailyLoopState = {
    lastClaimUtc: number,      -- os.time() of last claim
    streakCount: number,       -- consecutive days
    pendingReward: number?,    -- if cycle rolled but not yet claimed
    totalLifetimeClaims: number,
}
```

DataStore keys are scoped per player (`PlayerData/{userId}/DailyLoop`).

Client gets read-only mirror via attribute or replicated state.

### 8. UI surfaces

For each beat, name the UI:
- toast on login
- claim button in HUD
- streak counter visible in profile / hub
- preview of next-day reward
- end-of-loop celebration when capstone hits

## Output format

Add a section to the blueprint:

```markdown
## Loop spec: daily-login-streak

- **Type:** daily + streak
- **Entry:** PlayerAdded → server reads `lastClaimUtc`
- **Beat sequence:** join → server check → toast → claim button → grant → push streak
- **Reward schedule:** 7-day cycle (see table)
- **Fail state:** missed day → streak drops to 1 (soft fail; not zero)
- **Recovery:** can re-claim immediately on return
- **Burnout guardrail:** one claim per UTC day, hard cap
- **End condition:** week-7 capstone → resets streak to 1, grants cosmetic, increments lifetimeWeeks
- **Persistence:** `PlayerData/{userId}/DailyLoop` (DataStore)
- **Replication:** `streakCount` as player attribute (auto-replicate)
- **UI:** login toast, hub HUD counter, claim modal, preview-tomorrow tile
```

## Roblox-specific framing

- **UTC vs local time:** server-side claim check must use `os.time()` (UTC). Don't trust client-reported local time.
- **Cross-server consistency:** if the player hops servers, the next server reads the same DataStore — make sure both servers don't double-grant. Use `UpdateAsync` with a single-flight key, or stamp the claim with a UUID.
- **Mobile claim experience:** the claim flow must work on a phone in 2 taps max.
- **No punishment patterns:** miss-a-day = reset-to-zero feels punishing and erodes trust. Default to soft fail.

## Handoff

Loop spec slots into the main blueprint. After completion:

> "Loop spec complete. Recommend running `roblox-blueprint-retention` to verify D1/D7/D30 alignment, or hand off to the matching `roblox-forge-*` skill (`roblox-forge-daily-loop`, `roblox-forge-event-loop`, `roblox-forge-reward-loop`)."
