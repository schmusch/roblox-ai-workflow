---
name: roblox-forge-reward-loop
description: Use when implementing reward schedules — per-action drops, loot tables, currency grants, RNG rolls in Roblox. Builds server-authoritative reward distribution with verifiable drop rates and anti-grind guardrails. Use when the user says "implement loot drops", "build the reward schedule", "add the drop table", "forge reward loop".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Reward Loop

Execution skill for **per-action reward distribution**: drops, loot tables, currency grants, RNG rolls, mission rewards.

## When to use

- A blueprint specifies a reward schedule per action.
- The user wants to implement drop tables, RNG rolls, or per-mission rewards.

## Default implementation pattern

### Loot table config

```luau
-- src/shared/Loot/LootTable.lua
return {
    common_mob = {
        currency = { min = 5, max = 12 },
        drops = {
            { id = "scrap",     weight = 70, qty = {1, 3} },
            { id = "gear_low",  weight = 25, qty = {1, 1} },
            { id = "gear_mid",  weight = 4,  qty = {1, 1} },
            { id = "gear_high", weight = 1,  qty = {1, 1} },
        },
        xp = { min = 10, max = 20 },
    },
    -- ... other tables
}
```

Weights are explicit integers; total can be any number — server picks one entry by weighted random.

### Grant service

```luau
-- src/server/Rewards/RewardService.server.lua
local rng = Random.new()

function RewardService.rollLoot(tableId)
    local table_ = LootTable[tableId]
    if not table_ then return nil end
    local currency = rng:NextInteger(table_.currency.min, table_.currency.max)
    local xp = rng:NextInteger(table_.xp.min, table_.xp.max)
    
    local totalWeight = 0
    for _, drop in ipairs(table_.drops) do totalWeight += drop.weight end
    local roll = rng:NextInteger(1, totalWeight)
    local picked
    for _, drop in ipairs(table_.drops) do
        roll -= drop.weight
        if roll <= 0 then picked = drop; break end
    end
    
    local qty = rng:NextInteger(picked.qty[1], picked.qty[2])
    return { currency = currency, xp = xp, item = { id = picked.id, qty = qty } }
end

function RewardService.grantFromTable(player, tableId, source)
    local roll = RewardService.rollLoot(tableId)
    if not roll then return end
    CurrencyService.grant(player, roll.currency, source)
    InventoryService.grant(player, roll.item.id, roll.item.qty, source)
    ProgressionService.grantXp(player, roll.xp, source)
    AnalyticsService:log(player, "loot_rolled", { table = tableId, source = source, roll = roll })
end
```

**Key rules:**
- `Random.new()` instance is server-side and not exposed to clients.
- Loot table config is data, not code — designers can tune without code changes.
- Every grant logs the source (e.g. `"mob_kill:goblin"`) for balance analysis.

### Drop-rate transparency

Players resent hidden drop rates more than low drop rates. Surface the rates where appropriate:
- In-game lore book or "rare items" tab can show the table.
- For "X% chance" UI, the displayed number must match the actual weighted probability.
- If you change a drop rate post-launch, log the change in patch notes.

### Anti-grind / anti-fatigue

- **Daily rare-drop cap** — limit "Legendary" drops to N per day per player, then drops automatically swap to currency-equivalent.
- **Pity timer** — guaranteed rare after N consecutive non-rare rolls. State: `consecutiveNonRare` counter per player.
- **Diminishing returns on same-mob farming** — after killing the same mob type N times in T minutes, reward drops by X%. Resets on cooldown.

```luau
-- pity timer example
function RewardService.rollLootWithPity(player, tableId)
    local pity = pityState[player.UserId] or { count = 0 }
    if pity.count >= PITY_THRESHOLD then
        pity.count = 0
        pityState[player.UserId] = pity
        return forceRareRoll(tableId)
    end
    local roll = RewardService.rollLoot(tableId)
    if isRare(roll) then pity.count = 0 else pity.count += 1 end
    pityState[player.UserId] = pity
    return roll
end
```

### Reward magnitude curve

Externalize so designers can tune:
```luau
-- src/shared/Rewards/RewardCurve.lua
return {
    currencyPerLevel = function(level) return 5 + level * 2 end,
    xpPerLevel = function(level) return 10 + level * 3 end,
}
```

Scale reward magnitudes with player level so early-game grants don't trivialize late-game.

## Anti-pattern checks

- ❌ Drop rolls computed client-side → exploitable (favorable rolls injectable).
- ❌ Currency grant via client RemoteEvent → grant-anything exploit.
- ❌ Drop table hardcoded inline in mob script → un-tunable, scattered.
- ❌ "Legendary drop rate = 1%" displayed in UI but actual table is 0.1% → trust crash.
- ❌ No pity timer on rare drops → frustration / churn.
- ❌ Unlimited farm of the same mob → reward inflation.

## Verification

- Roll 10,000 times → empirical distribution matches table weights within tolerance.
- Pity timer: simulate N non-rare rolls → next roll is guaranteed rare.
- Daily cap: simulate N+1 rare rolls in one day → (N+1)th converts to currency.
- Adversarial: client fires `GrantLootRemote` directly → server rejects (loot grant is server-internal).
- Sources logged: kill mob, inspect analytics → entry exists with correct `source`.

## Roblox-fit notes

- **Random.new() is server-side**; don't use `math.random` for security-sensitive rolls — `Random.new()` is the modern API and is per-instance seeded.
- **Drop notifications** should batch — replicating a TextLabel per drop in a busy combat scene tanks performance.
- **Currency display** should animate on grant but not block input.
- **Marketplace gamepass "luck booster"** is a common monetization hook — implement it as a multiplier on the pity or rare-tier weight, not as a hidden override.
