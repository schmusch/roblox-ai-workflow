---
name: roblox-forge-mastery
description: Use when implementing combo systems, build paths, skill expression mechanics, combat tech, or optimization loops in Roblox. Builds depth that rewards skilled play without walling beginners. Use when the user says "add combos", "implement build system", "design combat depth", "forge mastery".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Mastery

Execution skill for the **Mastery** driver. Implements depth that rewards skilled play (combos, build paths, routing, combat tech) while keeping the onboarding gentle.

## When to use

- The blueprint includes mechanics whose value is skill expression, not progression.
- The user wants to add combo systems, build variants, optimization loops, combat tech.

## Default implementation pattern

### Layered depth

Layer depth, don't front-load it:

1. **Surface layer** (first 5 minutes) — one-button core action that works.
2. **Discoverable layer** (15–30 min) — modifiers, light combos, basic build choices.
3. **Tuning layer** (multi-session) — optimization, advanced combos, niche builds.

Design each layer separately. Don't expose layer-3 in the first session UI.

### Combo system (combat example)

```luau
-- src/shared/Combat/ComboConfig.lua
return {
    light = { damage = 10, recovery = 0.2 },
    light_light = { damage = 12, recovery = 0.25, window = 0.4 },
    light_light_heavy = { damage = 25, recovery = 0.6, window = 0.5, launches = true },
}
```

Server tracks the player's recent inputs (last N strikes within window) and matches against the combo table at strike time.

**Server-authoritative timing** — the client may render predicted animations, but the server determines the actual combo state. Otherwise lag becomes a balance hole.

### Build paths

- Configurable skill tree as data (`src/shared/Builds/SkillTreeConfig.lua`).
- Each node: prerequisites, cost (skill points), effect (multiplier, unlock).
- Server resolves build effects → applies to gameplay calculations.
- Client sees the tree as a UI graph; respec is a server RemoteEvent with currency cost.

### Hidden vs surfaced math

- **Surface the visible variables:** damage, cooldown, range, crit rate.
- **Hide the math:** internal damage formula scales, hidden status effects, balance multipliers.

Players need to optimize within a transparent system, not reverse-engineer a black box. If a tooltip says "+10% damage", the actual effect must be +10% in the formula. Hidden multipliers that contradict the tooltip break the driver.

### Skill expression telemetry

Log skill-related events to inform balance:
- `combo_completed { combo_id, damage_total }`
- `build_respec { from_build, to_build }`
- `combat_engagement { duration, damage_dealt, damage_taken, combos_used }`

## Anti-pattern checks

- ❌ Hidden math that contradicts visible tooltips (most-trust-eroding pattern).
- ❌ Combo windows derived from client input timestamps (exploit window).
- ❌ Build paths hardcoded in service code (un-tunable, un-extendable).
- ❌ Mastery layer fully exposed in the first session UI → overwhelms new players.
- ❌ Pay-to-win bypass of skill (e.g. a "+50% damage" gamepass nullifies mastery).
- ❌ No respec → skill experimentation blocked → players play conservatively.

## Verification

- Combo: server resolves combos identically regardless of client-reported latency.
- Build: respec applies new effects immediately and persists across sessions.
- Adversarial: client fires combo RemoteEvent with fake combo ID → server rejects.
- Onboarding test: new player can complete first session without seeing the mastery layer UI.
- Balance test: combat encounter analytics show varied combo / build choices, not a single dominant strategy.

## Roblox-fit notes

- **Fast-to-fun onboarding** — Roblox players bounce in < 60 seconds if the core action feels bad. Layer-1 must be tight before layer-2 ships.
- **Server-tick rate** — combat timing must be tuned to Roblox's 60 Hz server cap. Sub-frame combo windows aren't reliable.
- **Mobile inputs** — combo systems on mobile need on-screen-button design from day one. Don't ship a keyboard-only combo system.
- **Replication budget** — heavy combo VFX replicated to 30 players can degrade performance. Use streaming + culling.
