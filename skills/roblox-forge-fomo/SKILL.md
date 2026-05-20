---
name: roblox-forge-fomo
description: Use when implementing timed events, rotating shops, seasonal ladders, or limited-time content in Roblox. Builds urgency mechanics with fair re-entry, legible countdowns, and anti-burnout guardrails. Use when the user says "add a timed event", "implement rotating shop", "build the season", "forge FOMO".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — FOMO

Execution skill for the **FOMO** driver. Implements timed events, rotating shops, seasonal ladders, comeback rewards — with fair, legible urgency and explicit anti-burnout guardrails.

## When to use

- The blueprint includes timed content: events, shop rotations, season passes, limited cosmetics.
- The user wants to ship a seasonal arc, weekend event, or limited drop.

## Default implementation pattern

### Event window (server-authoritative)

```luau
-- src/shared/Events/EventConfig.lua
return {
    activeEvent = "winter_2026",
    startUtc = 1740960000,  -- 2026-03-03 00:00 UTC
    endUtc   = 1742342400,  -- 2026-03-19 00:00 UTC
}
```

Server reads `os.time()` and gates content:

```luau
function EventService.isActive(eventId)
    local cfg = EventConfig[eventId] or EventConfig
    local now = os.time()
    return now >= cfg.startUtc and now < cfg.endUtc
end
```

**Never trust client time** — only `os.time()` on the server.

### Rotating shop

- Server picks the current shop slot set from a config + seeded rotation key.
- Rotation seed = `floor(os.time() / rotationPeriodSeconds)` — same across servers, deterministic.
- Catalog config can use weighted random with the seed (`Random.new(seed)`).
- Player can preview "next rotation in MM:SS" — server pushes `nextRotationUtc` to client.

### Countdown UI

- Server pushes `endUtc` to client once on event start.
- Client computes `endUtc - now` locally for the visible countdown (cheap render).
- Resync every minute via a server tick to drift-correct.

### Limited cosmetics

- Tag cosmetic config with `availableUntilUtc`.
- Server refuses to grant after the timestamp.
- Already-granted cosmetics keep their visible "EVENT 2026" badge → flex value preserved.

### Comeback / re-entry reward

When a player who hasn't logged in for ≥ N days returns:
- Server detects `now - lastSessionUtc > thresholdDays * 86400`.
- Grants "we miss you" pack → small currency + free claim on tomorrow's daily.
- Logs `comeback_granted` to analytics.

This **anti-FOMO** pattern offsets the punishment feel of missing the event.

## Anti-burnout guardrails (mandatory)

- **Pass progress cap per session** — can't complete the whole pass in one play; encourages multi-session pacing.
- **Daily energy / claim limits** — only N claim slots per UTC day.
- **No "miss = permanent loss" without recovery** — see comeback pattern.
- **End-of-event grace** — for 24h after `endUtc`, allow claiming already-earned but un-claimed rewards. Don't strip earned-but-unclaimed.

## Anti-pattern checks

- ❌ Countdown driven by client time (`tick()`) — clock-skew exploitable.
- ❌ Shop rotation derived from client RNG — duplicate items per player.
- ❌ Event item granted via client-claim without server-side `isActive` check.
- ❌ "Daily login chain that resets entirely on a missed day" → trust-eroding.
- ❌ Limited cosmetic re-released for sale 3 months later → trust collapse.

## Verification

- Set Studio clock forward (via `os.time` mocked in tests) to event end + 1 sec → server rejects grant.
- Set clock back to event start → server allows grant.
- Two clients in different timezones see the same `endUtc` and converge on the same visible countdown.
- Adversarial: client fires `ClaimEventRewardRemote` after `endUtc` → server rejects silently.
- Comeback test: simulate 14-day lapse → comeback pack granted on next join.

## Roblox-fit notes

- Mobile session-length is short — design at least one event reward claimable in ≤ 5 minutes of play.
- Cross-region timezones — `endUtc` should not land at "3 AM in target region". Pick start/end times that align with peak target-region hours.
- Marketplace cooldowns — if monetization includes a limited gamepass, Roblox's marketplace listing flow takes hours to update. Plan ship windows accordingly.
- Notification limit — Roblox does not push notifications externally. Returning players see the event only when they join. Make the join-time UI surface the event prominently.
