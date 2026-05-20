---
name: roblox-brief
description: Use at the start of any Roblox creator request to clarify intent (genre, audience, scale, multiplayer, monetization) before planning or building. Use when the user says "I want to build...", "Help me design...", "I have an idea for a Roblox game...", or any open-ended creator ask.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Brief

The first lane in the Roblox creator workflow. Turn a vague idea into a structured brief that the planning lane (`roblox-blueprint`) can act on.

Use `roblox-brief` whenever the user describes a Roblox project, feature, or system without already supplying genre, audience, scale, server topology, and monetization intent. **Do not** skip ahead to planning or implementation when these are unclear — a brief mistake at this stage cascades into wasted blueprint and forge cycles.

## When to use

- The user describes a Roblox idea for the first time.
- The user wants to "design" / "plan" / "build" something but the scope and target audience are undefined.
- A prior brief exists but the user has materially changed direction (new genre, new audience, new monetization).
- Before any `roblox-blueprint` call when scope is still soft.

## When not to use

- The user has already given a complete brief (genre, audience, scope, multiplayer, monetization all clear).
- The task is a precise file-level fix or refactor with no design ambiguity.
- The user explicitly says "skip the brief, just plan it" — but flag any obvious gap before continuing.

## What this skill produces

A brief document covering:

1. **Core creator outcome** — one sentence: what the player experience is.
2. **Genre** — simulator / combat / social / tycoon / obby / roleplay / sandbox / racing / horror / other.
3. **Target audience** — age band, region hints, expected session length, social context.
4. **Scale** — single-server / cross-server / persistent world / event-driven.
5. **Multiplayer model** — solo / co-op / PvE / PvP / massive social.
6. **Dominant player drivers** — 1 primary + 1–2 supporting from {Progression, Status, FOMO, Mastery, Community}.
7. **Monetization intent** — none / cosmetic / gamepass / developer products / season pass / mixed.
8. **Constraints** — anything fixed (existing codebase, art style, IP, platform restrictions, deadline).
9. **Out-of-scope** — what the user explicitly does **not** want.
10. **Open questions** — anything still unclear after asking.

Save to `briefs/<task-slug>-<YYYYMMDD>.md` if persistence is appropriate; otherwise inline.

## Method

1. **Restate** what you heard in 1–2 sentences and ask the user to confirm. Catches misreads early.
2. **Ask the minimum questions** to fill the brief. Group small ones; pick the highest-leverage question first. Do **not** dump a 10-question form.
3. For genre / audience / monetization gaps, propose a small multiple-choice set instead of open prompts — easier to answer.
4. For player-driver selection, use the framework in `references/psychology-framework.md`. If the user can't pick, ask: *"When players talk about this game to their friends, what do you want them to say first?"* The answer maps to a driver.
5. **Surface obvious red flags** before completing the brief:
   - Pay-to-win in a competitive context.
   - Real-money trading mechanics (against TOS).
   - Audience mismatch (e.g. "horror experience for under-13").
   - Persistence requirements with no failure-mode plan.
6. **Output the brief** in the structure above. Mark unanswered fields explicitly as `OPEN: …`.

## Roblox-specific framing

- Roblox players switch experiences fast — the brief must answer "what hooks them in the first 60 seconds?".
- Genre choice constrains a lot: a simulator brief implies different defaults (idle progression, sinks, prestige) than a combat brief (skill expression, balance, anti-cheat).
- Monetization intent affects architecture early — gamepass-gated zones need TeleportService planning; developer-product purchases need ProcessReceipt design.
- Social context matters: a party-of-friends loop has different UI demands than a strangers-in-a-hub loop.

## Handoff

When the brief is complete (no `OPEN:` fields, or the user explicitly accepts open questions as deferred):

> "Brief complete. Recommend running `roblox-blueprint` next to turn this into an architecture plan."

If the user wants to skip ahead directly to a small focused build, note the brief gaps as risks but allow the skip.

## Variants

- **`roblox-brief-audience`** — deep-dive on target-audience profiling when the audience answer needs more nuance.
- **`roblox-brief-motivation`** — deep-dive on player-driver selection when the user is uncertain which psychology to lean on.

## Example output

```markdown
# Brief: cross-server-party-tycoon (2026-05-20)

**Outcome:** Friends queue together into a shared tycoon server, build a base, defend it from periodic raids, and showcase upgrades to visitors.

- **Genre:** tycoon + light combat (raid defense)
- **Audience:** 10–16, mixed regions, 20–40 min sessions, plays with friends
- **Scale:** cross-server (party teleport into instanced server)
- **Multiplayer model:** co-op (parties of 2–4); visitors can drop in
- **Dominant drivers:** Community (primary) + Progression (supporting) + Status (visitor showcase)
- **Monetization:** cosmetic + developer products for base accelerators
- **Constraints:** existing combat module in `ReplicatedStorage.Combat`; must reuse
- **Out-of-scope:** PvP between parties; full open-world map; player trading
- **Open questions:**
  - `OPEN:` should raids include other-player invaders or AI only?
```
