---
name: roblox-blueprint-psychology
description: Use during blueprint planning to apply the 5-driver player-psychology framework (Progression, Status, FOMO, Mastery, Community) as a design lens. Use when verifying that the architecture actually serves the dominant driver, when checking for cross-driver tensions, or when auditing UI / feedback / monetization for driver alignment.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Blueprint — Psychology

Blueprint deepening skill. Applies the 5-driver framework from `references/psychology-framework.md` as a design lens on the blueprint plan: does the architecture actually serve the primary driver, where are the feedback surfaces, what's the monetization alignment, what tensions need resolving?

## When to use

- During `roblox-blueprint`, before finalizing the plan, when the feature touches player desire (almost always).
- When auditing an existing system for driver alignment.
- When the brief identified a primary driver and the plan must reflect it concretely.

## When not to use

- Mechanical refactors with no player-facing impact.
- Pure infrastructure work (replication plumbing, DataStore migrations) where driver is downstream.

## What this skill produces

A psychology audit section in the blueprint:

1. **Driver alignment check** — does each architectural choice serve the named primary driver?
2. **Feedback surface map** — which UI elements / particles / sounds / replications signal each desire moment?
3. **Loop integrity check** — fail state? recovery path? burnout guardrail?
4. **Monetization alignment** — does the paid layer amplify or replace the driver?
5. **Social visibility check** — when status / progression matters, can other players actually see it?
6. **Cross-driver tension notes** — explicit callouts for known tensions (Progression × Mastery, Status × Community, FOMO × anything).

## Method

### 1. Pull the primary + supporting drivers from the brief

If they're not in the brief, run `roblox-brief-motivation` first.

### 2. Walk the architecture against the driver checklist

For each driver in scope, work through the rows of the framework:
- mechanics → does the plan implement at least one?
- UI / feedback → does the plan name the visible surface?
- economy implications → does the plan handle sinks, inflation, catch-up?
- retention implications → does the plan map to a retention beat?
- monetization implications → are the paid hooks aligned?
- abuse / risk → does the plan handle the listed risks?
- Roblox-fit → does the plan respect Roblox-specific constraints (fast-to-fun, mobile, switching tolerance)?

### 3. Loop integrity audit

Every loop in the plan must have:
- **Fail state** — what happens when the player loses / fails / misses?
- **Recovery path** — how do they get back in?
- **Burnout guardrail** — what stops players from grinding to exhaustion?

If any of these are missing, the loop is incomplete. Flag and propose a fix.

### 4. Monetization audit

For each paid hook in the plan:
- which driver does it serve?
- does it **amplify** the desire (good) or **replace** the in-game effort (pay-to-win risk)?
- is the paid surface **visible** to other players (status alignment) or invisible (status hole)?

### 5. Social visibility audit

When the plan involves status or progression:
- where can other players see the player's status / progress?
- hubs, lobbies, match results, party-list, profile?
- if the answer is "nowhere visible", the status driver is broken — propose a visibility surface

### 6. Cross-driver tension callout

Apply the known tensions:
- **Progression × Mastery** — does the progression curve let the player skip past mastery depth?
- **Status × Community** — do the leaderboards / showcases reward solo flex over group identity?
- **FOMO × anything** — does the urgency cadence feel fair or punishing?
- **Monetization × any driver** — does the paid layer break the driver's promise?

Each tension found should produce an explicit blueprint adjustment.

## Output format

Add a section to the blueprint:

```markdown
## Psychology audit

### Driver alignment
- Primary (Community): ✓ party queue, ✓ raid co-op, ⚠ no visible group-progress board → ADD
- Supporting (Progression): ✓ base upgrade tree, ✓ unlock pacing
- Supporting (Status): ⚠ visitor showcase exists but no leaderboard surface → ADD

### Feedback surfaces
- Upgrade complete → toast + particle (server pushes to party)
- Raid won → group cheer animation + reward UI (replicated to party)
- Visitor reactions → emote prompts to visitor, visible to host

### Loop integrity
- Fail state: raid lost → base damage but no progress loss
- Recovery: rebuild damaged sections at half cost
- Burnout: raid cooldown of 12 min, no infinite back-to-back

### Monetization alignment
- Base accelerator (gamepass) → amplifies Progression ✓
- Cosmetic skins (developer products) → serves Status, visible in hubs ✓
- No pay-to-defend-raid → no P2W risk ✓

### Social visibility
- Base "trophy room" visible to visitors via showcase Model → Status ✓
- Party leaderboard in hub → Community + Status ✓

### Cross-driver tensions
- Status × Community: visitor showcases are individual — add party-trophy-room to balance group identity
```

## Roblox-specific framing

- Progression: **first upgrade payoff must arrive within minutes**, not after a tutorial.
- Status: needs **visible in hubs, parties, lobbies** — if status is "in a menu only", it doesn't work.
- FOMO: urgency must be **legible and fair** — many players arrive in short bursts.
- Mastery: **fast-to-fun onboarding** — start simple, layer depth.
- Community: **reduce friction to playing together fast** — party-up, invite, drop-in must be one tap.

## Handoff

The psychology audit slots back into the main `roblox-blueprint` document. After completion:

> "Psychology audit added. Recommend running `roblox-blueprint-loops` next if the feature includes reward / daily / event loops, or hand off to `roblox-forge`."
