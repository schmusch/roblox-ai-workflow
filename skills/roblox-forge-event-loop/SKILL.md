---
name: roblox-forge-event-loop
description: Use when implementing seasonal events, weekend arcs, or bounded-window content in Roblox. Builds start-peak-sunset event mechanics with fair re-entry and grace periods. Use when the user says "implement the winter event", "build the season arc", "add a weekend event", "forge event loop".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Event Loop

Execution skill for **bounded-window event arcs**: seasonal events, weekend events, raid weeks, holiday content. Uses the loop spec from `roblox-blueprint-loops`.

## When to use

- A blueprint includes an event with a start and end window.
- The user wants to ship a seasonal arc, weekend event, or limited-time series.

## Default implementation pattern

### Event config

```luau
-- src/shared/Events/EventCatalog.lua
return {
    winter_2026 = {
        startUtc = 1740960000,
        peakUtc  = 1741737600,     -- midpoint, used for difficulty / reward scaling
        endUtc   = 1742342400,
        graceUtc = 1742428800,     -- 24h post-end for claiming earned rewards
        rewardTrack = {
            -- tier => { progressNeeded, reward, displayName }
            { 100,  { type = "currency", amount = 500 },    "Frost Coins" },
            { 250,  { type = "cosmetic", id = "frost_hat" }, "Frost Hat" },
            { 500,  { type = "currency", amount = 2000 },   "Major Frost Cache" },
            { 1000, { type = "cosmetic", id = "frost_aura"}, "Frost Aura (rare)" },
        },
    },
}
```

### Event service

```luau
-- src/server/Events/EventService.server.lua
function EventService.phaseOf(eventId)
    local cfg = EventCatalog[eventId]
    local now = os.time()
    if now < cfg.startUtc then return "upcoming" end
    if now < cfg.peakUtc  then return "rising" end
    if now < cfg.endUtc   then return "peak" end
    if now < cfg.graceUtc then return "grace" end
    return "ended"
end

function EventService.grantProgress(player, eventId, amount, reason)
    local phase = EventService.phaseOf(eventId)
    if phase ~= "rising" and phase ~= "peak" then return end  -- no progress in grace
    local data = EventService._cache[player.UserId][eventId] or { progress = 0, claimedTiers = {} }
    data.progress += amount
    EventService._cache[player.UserId][eventId] = data
    EventProgressRemote:FireClient(player, eventId, data)
    AnalyticsService:log(player, "event_progress", { event = eventId, amount = amount, reason = reason })
end

function EventService.claimTier(player, eventId, tierIndex)
    local phase = EventService.phaseOf(eventId)
    if phase == "ended" then return false, "ended" end  -- can't claim after grace
    if phase == "upcoming" then return false, "not_started" end
    local data = EventService._cache[player.UserId][eventId]
    if data.claimedTiers[tierIndex] then return false, "already_claimed" end
    local tier = EventCatalog[eventId].rewardTrack[tierIndex]
    if data.progress < tier[1] then return false, "insufficient_progress" end
    data.claimedTiers[tierIndex] = os.time()
    GrantService.grant(player, tier[2], "event_claim:" .. eventId)
    return true
end
```

### Phase-driven content

Use phases to gate content / difficulty / spawn rates:
- `upcoming` — teaser UI only, no rewards available
- `rising` — full participation, baseline rewards
- `peak` — boosted rewards, optional difficulty bump (boss spawns more often)
- `grace` — no new progress, but earned tiers still claimable
- `ended` — fully closed; UI shows "until next year"

### UI surfaces

- Hub-world banner showing current phase + time-to-next-phase
- HUD progress bar during gameplay (`progress / nextTierProgress`)
- Event tab in main menu with reward track, claimed/unclaimed indicators
- Comeback toast for returning players: "Event ends in 2 days — N tiers unclaimed"

### Grace period (mandatory)

Earned but unclaimed rewards must remain claimable for ≥ 24h after `endUtc`. Don't strip what the player earned.

After `graceUtc`, the event closes fully. Unclaimed rewards are archived (optional) or forfeited (with prior in-game warnings).

### Persistence

- `EventProgress/{userId}/{eventId}` — keyed by event ID so multiple events can coexist.
- On event end + 7 days, archive the user-progress key to free DataStore quota.

## Anti-pattern checks

- ❌ Hard cutoff at `endUtc` with no grace → players who earned tier-9 lose it. Trust crash.
- ❌ Event progress grant from client RemoteEvent without server validation.
- ❌ Phase derived from client time.
- ❌ Reward track config inline in service code (un-tunable, un-extendable).
- ❌ Returning player after the event has no UI surface showing what they missed.
- ❌ Player can claim tiers during `upcoming` phase → exploit.

## Verification

- Set clock to each phase boundary → server returns correct phase.
- Claim tier with insufficient progress → reject.
- Claim tier in `upcoming` phase → reject.
- Claim earned tier in `grace` phase → succeed.
- Claim tier in `ended` phase → reject.
- Adversarial: client fires `GrantProgressRemote` directly → server rejects (no such remote — progress is server-granted only).
- Persistence: earn tier, leave, rejoin → tier still claimable.

## Roblox-fit notes

- **Event marketing happens outside the game** (DevForum, social media, Roblox event panels). Build the in-game UI to make the event obvious to walk-up players who haven't seen marketing.
- **Time zones** — set `startUtc` and `endUtc` at times that align with the target audience's peak hours. 00:00 UTC = late evening EU, midday US.
- **Server restart implications** — server restarts can lose in-memory state. Reload from DataStore on player join.
- **MessagingService for event-wide announcements** — e.g. "Boss spawning in 5 minutes" cross-server.
