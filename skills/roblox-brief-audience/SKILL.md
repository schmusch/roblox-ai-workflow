---
name: roblox-brief-audience
description: Use to deep-dive on target-audience profiling when the brief's audience answer needs more nuance — age band, region hints, session length, social context, device mix, content rating. Use when the user is unsure who the game is for, when audience materially affects design decisions, or when the brief is too vague on audience.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Brief — Audience

Sub-skill of `roblox-brief`. Use to build a sharp target-audience profile when "who is this for" remains fuzzy after the main brief, or when downstream choices (content rating, UI scale, social mechanics, monetization) depend on a more specific answer.

## When to use

- The main brief lists audience as "everyone" or "Roblox players" — too broad.
- The user is unsure of the target age band.
- The plan requires content-rating decisions (Experience Guidelines).
- Monetization choices depend on knowing under-13 share.
- Social mechanics depend on whether players play with strangers or known friends.

## When not to use

- The audience is already concrete (e.g. "13–17, North America, 30-min sessions, plays with school friends").
- The change is mechanical and audience-agnostic.

## What this skill produces

An audience profile covering:

1. **Primary age band** — Roblox's primary distribution: under-9, 9–12, 13–16, 17+. Pick one primary + one secondary.
2. **Content rating target** — Experience Guidelines: Minimal / Mild / Moderate / Restricted. (Restricted = 17+, gates VR, age verification, etc.)
3. **Region mix** — global / Anglo-only / specific region(s). Affects localization budget, server placement, event timezone.
4. **Device mix** — PC / mobile / console / VR share guess. Affects UI scale, input model.
5. **Session length expectation** — 5–10 min snacks, 20–40 min mid, 60+ min long. Affects loop pacing and save frequency.
6. **Social context** — solo / with-friends / with-strangers / mixed. Affects social mechanic depth.
7. **Onboarding tolerance** — under-9 = near-zero tolerance for tutorial weight; teens accept more depth. Affects "fast to fun" budget.
8. **Spending profile guess** — free-only / cosmetic-only / occasional / whale-friendly. Constrains monetization layer.

## Method

1. Ask the highest-leverage question first. Usually age band — it cascades.
2. For each subsequent field, propose 2–3 multiple-choice options grounded in the primary age band.
3. Flag the **content-rating consequences** explicitly when the primary age band is under-13:
   - no real-money trading
   - no chat opt-in via age verification
   - constrained advertising rules
   - paid item lockouts in certain regions
4. Flag the **device mix consequences** when mobile share is high:
   - UI must scale to small screens
   - input model can't rely on hover / right-click
   - performance budget tightens (lower polycount, simpler shaders)
5. Output the profile as a section that the main brief can absorb.

## Roblox-specific framing

- Under-13 is a hard regulatory line: no real-money trading, restricted chat, COPPA-relevant data handling.
- The "shared family device" pattern is real: a 9-year-old may be playing on a parent's account. Don't assume reported age = playing age.
- VR audience is small but loyal — only profile this if the experience targets VR explicitly.
- Mobile share is dominant on Roblox — assume mobile-first unless told otherwise.

## Handoff

Audience profile feeds back into `roblox-brief`. After completion:

> "Audience profile complete. Returning to the main brief — the remaining open fields are: …"

Or, if the audience was the only blocker:

> "Audience profile complete. The brief is now ready for `roblox-blueprint`."
