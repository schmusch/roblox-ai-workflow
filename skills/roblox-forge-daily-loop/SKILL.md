---
name: roblox-forge-daily-loop
description: Use when implementing daily login bonuses, daily quests, or streak systems in Roblox after a blueprint is approved. Builds UTC-aware, cross-server-safe daily mechanics with soft-fail recovery. Use when the user says "implement daily login", "build the streak system", "add daily quests", "forge daily loop".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Daily Loop

Execution skill for **daily-cadence** engagement: login bonuses, daily quests, streaks. Uses the loop spec from `roblox-blueprint-loops`.

## When to use

- A blueprint includes a daily login chain, daily quest rotation, or streak system.

## Default implementation pattern

### State

```luau
-- src/server/DailyLoop/DailyLoopService.server.lua
type DailyLoopData = {
    lastClaimUtc: number,
    streakCount: number,
    pendingReward: number?,    -- if cycle rolled but not yet claimed
    lifetimeClaims: number,
}
```

DataStore key: `PlayerData/{userId}/DailyLoop`. Cached in-memory during session.

### Claim detection

```luau
local function utcDayOf(unixTime) return math.floor(unixTime / 86400) end

function DailyLoopService.checkClaimable(player)
    local data = DailyLoopService._cache[player.UserId]
    local today = utcDayOf(os.time())
    local lastDay = utcDayOf(data.lastClaimUtc)
    if today == lastDay then return false end  -- already claimed today
    if today == lastDay + 1 then
        return true, "continue"
    else
        return true, "reset"  -- gap of 1+ day, soft-fail to streak 1
    end
end
```

### Claim flow

```luau
ClaimDailyRemote.OnServerEvent:Connect(function(player)
    if not rateLimit(player, "claim_daily", 1) then return end
    local claimable, mode = DailyLoopService.checkClaimable(player)
    if not claimable then return end
    
    local data = DailyLoopService._cache[player.UserId]
    if mode == "continue" then
        data.streakCount += 1
    else  -- reset (but soft-fail to 1, not 0)
        data.streakCount = 1
    end
    
    local rewardTier = math.min(data.streakCount, #DailyConfig.rewards)
    local reward = DailyConfig.rewards[rewardTier]
    GrantService.grant(player, reward, "daily_claim")
    
    data.lastClaimUtc = os.time()
    data.lifetimeClaims += 1
    DailyLoopService.persist(player)
    DailyStateRemote:FireClient(player, data)
end)
```

### Cross-server safety

If a player hops servers within seconds of claiming, the second server might re-read stale DataStore data and re-allow claim. Mitigations:
- Use `UpdateAsync` for the claim write (transactional).
- Inside the UpdateAsync callback, re-check `lastClaimUtc` against `today` → reject if already claimed.

```luau
local function claimSafe(userId)
    local success, result = pcall(function()
        return store:UpdateAsync(tostring(userId), function(existing)
            existing = existing or { lastClaimUtc = 0, streakCount = 0, lifetimeClaims = 0 }
            local today = utcDayOf(os.time())
            if utcDayOf(existing.lastClaimUtc) == today then return nil end  -- abort write
            -- compute new streak, write back
            ...
            return existing
        end)
    end)
    ...
end
```

`UpdateAsync` returning `nil` aborts the write — that's the cross-server-safe pattern.

### Daily quest rotation

- Quest pool in `src/shared/DailyQuests/QuestPool.lua`.
- Server picks the player's daily quests using `Random.new(playerUserId + utcDayOf(now))` for stable per-player-per-day selection.
- Same seed in two servers → same quests → no duplicate-quest issue.

### UI

- Login → server detects claimable → push `DailyStateRemote` to client.
- Client shows toast: "Daily reward ready!"
- Claim modal: shows today's reward + tomorrow's preview + current streak count.

## Streak forgiveness (anti-burnout)

Default to **soft fail**: missed day → streak resets to 1, not 0. The user keeps lifetime claim count, just loses the multiplier.

Optional pro-pattern: **1 free freeze per week** — a missed day doesn't reset the streak the first time per week. Tracks `weeklyFreezeUsed` in state.

## Anti-pattern checks

- ❌ Client computes "is claimable" based on client time → easy exploit.
- ❌ `SetAsync` instead of `UpdateAsync` → cross-server double-claim.
- ❌ Missed-day = streak-to-0 → trust-eroding.
- ❌ Daily quest from client RNG → players reroll until they get easy quests.
- ❌ Reward computed client-side and sent to server for grant → grant-anything.

## Verification

- Claim once, attempt claim again immediately → second rejected.
- Set clock forward 24h → claim allowed, streak +1.
- Set clock forward 48h → claim allowed, streak resets to 1.
- Cross-server simulated: two parallel claim attempts → only one writes.
- Persistence: claim, leave, rejoin same day → already-claimed state preserved.

## Roblox-fit notes

- **UTC rollover** for the daily boundary is the canonical choice. Per-player local-time is harder to verify and exploit-prone.
- Surface the rollover time in the UI: "Resets in 4h 32m". Use server-pushed `nextRolloverUtc` + client-side countdown.
- Mobile claim flow: 2 taps max from join to grant.
- Quest reroll: optional — if implemented, server-side only, with a cost (currency or free-once-per-day).
