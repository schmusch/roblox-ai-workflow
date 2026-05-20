---
name: roblox-blueprint-retention
description: Use during blueprint planning when retention is the success metric. Builds D1, D7, D30 retention plans with explicit hooks, fail-state recovery, and anti-churn guardrails. Use when the user asks "why will players come back", "how do we improve retention", "what's the D7 hook", or when designing systems whose success depends on multi-session engagement.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Blueprint — Retention

Blueprint deepening skill focused on **multi-session retention**: what brings a player back tomorrow (D1), in a week (D7), in a month (D30)?

## When to use

- The feature's success is measured in retention metrics.
- The plan implies repeat sessions (daily loops, weekly quests, season pass, social systems).
- The user explicitly asks about retention or churn.

## When not to use

- One-shot features with no retention purpose (cosmetic shop, single-event quest).
- Pure infrastructure work.

## What this skill produces

A retention plan covering:

1. **D1 hook** — what brings the player back tomorrow specifically.
2. **D7 hook** — what brings the player back a week from now.
3. **D30 hook** — what brings the player back a month from now.
4. **Churn risks** — known patterns that drive churn for this feature / genre.
5. **Anti-churn guardrails** — concrete mechanics that mitigate the risks.
6. **Re-entry friction audit** — how fast can a returning player get back into the loop.
7. **Catch-up provision** — what supports late returners / missed-window players.
8. **Retention measurement plan** — what to log to verify retention actually happened (analytics events / DataStore counters).

## Method

### 1. Identify the time-based hooks

For each retention window, the hook must be:
- **concrete** — a specific in-game thing
- **legible** — the player understands why they're coming back
- **owned by the right driver** — aligned with the brief's primary driver

**D1 hook examples:**
- Daily login reward (streak-based)
- Daily quest rotation
- Cooldown completion (energy refill, building finished)
- Friends online (social pull)

**D7 hook examples:**
- Week-7 streak capstone reward
- Weekly quest completion + rotation
- Weekend event start / end
- Limited-time shop rotation

**D30 hook examples:**
- Season pass progress + tier unlocks
- Monthly event arc (start/peak/sunset)
- Long-term progression milestone (prestige, evolution)
- Guild / community goal completion

### 2. Map hooks against the primary driver

A retention plan for a **Community-driven** game looks different from a **Progression-driven** one:
- Community: D1 = friends online cue; D7 = guild event; D30 = guild season
- Progression: D1 = daily XP bonus; D7 = unlock tier; D30 = prestige
- Status: D1 = leaderboard refresh; D7 = weekly top showcase; D30 = season trophy
- FOMO: D1 = today's limited shop; D7 = event end; D30 = season pass deadline
- Mastery: D1 = daily challenge; D7 = leaderboard reset; D30 = expansion / new mechanic drop

If the hooks don't align with the primary driver, the retention plan won't compound — fix the alignment.

### 3. Audit known churn risks

Genre-typical churn risks:
- **Simulator:** grind wall after first prestige; idle reward inflation; sink scarcity.
- **Combat:** skill ceiling too low; matchmaking unfair; meta stale.
- **Social:** friend dependency (single point of failure); harassment exposure; guild deadweight.
- **Tycoon:** plateau after main upgrade tree; no late-game depth.
- **Obby / showcase:** content exhausted after one playthrough.

For each risk present in this feature, name a concrete mitigation.

### 4. Anti-churn guardrails

Common patterns:
- **Catch-up multipliers** for returning players (lapsed-day bonus, free first claim).
- **Streak forgiveness** — auto-freeze on missed day instead of reset.
- **Quest rerolls** for unwanted daily quests.
- **Soft fail** everywhere (see `roblox-blueprint-loops`).
- **Progress decay caps** — never zero out long-term progress on a single miss.

### 5. Re-entry friction audit

Imagine a player returning after 7 days. From the moment they tap "join":
- How many taps / screens before they're in the loop again?
- Does the UI orient them ("here's what changed", "your party leveled up")?
- Are they bombarded with notifications / popups (bad) or smoothly re-introduced (good)?

If re-entry takes more than ~30 seconds to "back in the action", design a faster path.

### 6. Retention measurement plan

For each hook, define what to log so retention can be verified:
- **DataStore counter:** `lastSessionUtc`, `consecutiveSessions`, `lifetimeSessions`.
- **Event log:** `daily_claim`, `quest_complete`, `season_tier_unlocked`.
- **Roblox analytics:** standard ExperienceAnalytics events where applicable.
- **Custom dashboard:** if the user has a data pipeline, name the metrics.

## Output format

```markdown
## Retention plan

### Hooks
- **D1:** daily login chain → 100c → 200c → 500c progressive
- **D7:** week-7 streak capstone → rare cosmetic + party-trophy emblem
- **D30:** season pass tier 30 → exclusive base wallpaper + title

### Driver alignment
Primary driver = Community. Hooks layered:
- D1 also surfaces "your party leveled up while you were gone" toast → Community pull
- D7 capstone is a party-trophy → shared identity

### Churn risks
- Grind wall after week 4 (progression risk) → add weekly party-quest with rotating goal
- Friend dependency (community risk) → make some content viable solo with reduced rewards
- Single-point churn: if a friend churns, the player may follow → guild fallback layer

### Anti-churn guardrails
- Streak forgiveness: 1 missed day freezes, doesn't reset
- Lapsed-7-day return bonus: free starter pack
- Daily quest reroll: 1 free reroll per day

### Re-entry friction
- Returning player after 7 days:
  - tap join → spawn at party hub (auto)
  - toast: "Party leveled up to 12 while away" + "3 raids this week"
  - quick-rejoin button → instant raid party queue
- Target: under 20 seconds to be in active gameplay

### Measurement
- Log `daily_claim`, `weekly_capstone`, `season_tier`, `party_raid_complete`
- DataStore: `lastSessionUtc`, `consecutiveDays`, `weeksActive`
- Verify D1/D7/D30 cohort retention from these events
```

## Roblox-specific framing

- Roblox players **switch experiences fast** — D1 retention on Roblox is hard. The first session must end on a hook ("come back tomorrow for X").
- **Mobile-first** — claim flow must work on phone in 2 taps.
- **Cross-platform** — a player may have played on PC yesterday, mobile today. Retention state must replicate.
- **Notification limits** — Roblox doesn't have unrestricted push notifications. Retention can't rely on external pings; it must be in-game-discoverable.

## Handoff

Retention plan slots into the main blueprint. After completion:

> "Retention plan complete. Recommend `roblox-blueprint-social` next if social hooks are involved, or hand off to `roblox-forge` for implementation."
