---
name: roblox-brief-motivation
description: Use to identify which player drivers (Progression, Status, FOMO, Mastery, Community) the Roblox experience should lean on when the brief's "dominant driver" answer is uncertain. Use when the user can't pick a primary driver, when the experience seems to want all of them at once, or before applying the psychology framework in planning.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Brief — Motivation

Sub-skill of `roblox-brief`. Use to identify the dominant player driver(s) of the experience when the user can't articulate "what do players actually want here?". Maps the brief into the 5-driver framework from `references/psychology-framework.md`.

## When to use

- The user lists too many goals ("XP, leaderboards, daily events, guilds, combat depth") and can't say which is primary.
- The user says "I want everyone to love it" without naming a desire.
- The brief is otherwise complete except for `dominant driver`.
- A prior plan feels unfocused — usually a driver-clarity problem.

## When not to use

- The user has already named a clear primary driver.
- The task is mechanical / refactor / bugfix (driver doesn't matter).

## What this skill produces

A motivation profile:

1. **Primary driver** — one of {Progression, Status, FOMO, Mastery, Community}.
2. **Supporting drivers** — zero to two more.
3. **Player-statement test** — one sentence in the player's voice: "When I play this, I…".
4. **Friend-pitch test** — one sentence: "Tell your friends about this game in one line".
5. **Driver alignment notes** — which mechanics in the brief actually serve the chosen primary, which are noise.
6. **Driver tension warnings** — any cross-driver tensions to flag (see psychology framework's "Cross-driver tensions" section).

## Method

### 1. Apply the friend-pitch test

Ask: *"If a player loves this game, how would they describe it to a friend in one sentence?"*

Then map the verbs in the answer to a driver:

| Verbs in the pitch | Likely primary driver |
|---------------------|----------------------|
| "level up", "get stronger", "unlock more" | Progression |
| "flex", "show off", "rare", "leaderboard" | Status |
| "limited", "event", "before it ends" | FOMO |
| "skill", "combo", "discover", "outplay" | Mastery |
| "with friends", "guild", "team", "trade" | Community |

If the answer contains two equally strong verbs, the secondary verb maps to a supporting driver.

### 2. Apply the friction-tolerance test

For the candidate primary driver, ask: *"What would the player put up with to get this?"*

- Progression: long grinds, daily logins, repetitive farming
- Status: high prices, exclusive events, complex craft chains
- FOMO: scheduled play, missed sleep, urgent shop visits
- Mastery: failure, learning curve, mechanical depth
- Community: dealing with people, drama, group coordination

The tolerance answer must be **plausible for the audience** (from `roblox-brief-audience`). Under-9 won't tolerate combat learning curves; 17+ won't tolerate daily-login chains they perceive as manipulative.

### 3. Audit the brief's mechanics against the chosen driver

For each mechanic the user listed:
- does it directly satisfy the primary driver? → keep
- does it satisfy a supporting driver? → keep, mark as supporting
- does it serve a different driver? → flag as misaligned, ask the user to drop or rejustify

This is where unfocused designs get tightened.

### 4. Flag cross-driver tensions

From `references/psychology-framework.md`:
- **Progression × Mastery** — progression can solve mastery before depth lands; needs prestige resets / build variants
- **Status × Community** — solo flex can crowd out group feel; needs group-status surfaces
- **FOMO × anything** — over-FOMO erodes trust; needs fair re-entry

Note these explicitly in the motivation profile so blueprint can address them.

### 5. Output the motivation profile

```markdown
## Motivation

- **Primary:** Community
- **Supporting:** Progression, Status (light)
- **Player statement:** "When I play, I team up with my friends to build something we can show off."
- **Friend pitch:** "It's a co-op base-builder where your party defends raids and visitors come see your stuff."
- **Mechanic alignment:**
  - Party queue + raid defense → Community ✓
  - Base upgrades visible to visitors → Status + Progression ✓
  - Daily login chain → ⚠ misaligned (FOMO mechanic in a Community game) — propose: weekly party-quest instead
- **Tensions:**
  - Status × Community: leaderboards must show party / guild ranks, not just solo
```

## Roblox-specific framing

- Roblox is **socially native** — Community as a primary or strong supporting driver is almost always available. Don't ignore it.
- Mastery as primary on Roblox is rare and hard — players bounce fast, complex tech is a hard sell unless backed by strong onboarding. Possible (Phantom Forces, Combat Initiation) but expensive.
- FOMO as primary is fragile — it depends on consistent LiveOps; if the user is solo dev, FOMO-primary is high-risk.
- Progression as primary is the safest default for simulators / tycoons. Status pairs with it naturally.

## Handoff

> "Motivation profile complete. Returning to the main brief. Recommend running `roblox-blueprint-psychology` during planning to validate driver fit."
