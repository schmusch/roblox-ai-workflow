---
name: roblox-forge-progression
description: Use when implementing XP, levels, unlocks, rebirth, or prestige systems in Roblox after a blueprint is approved. Builds server-authoritative progression with replicated client mirror, persistence, and curve / sink design. Use when the user says "implement XP", "add the level system", "build rebirth", "forge progression".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Progression

Execution skill for the **Progression** driver. Implements XP, levels, unlock tracks, rebirth, prestige loops with server authority + persistence.

## When to use

- A `roblox-blueprint` plan includes a progression system and is approved.
- The user asks to implement / extend / tune XP, level, unlock, rebirth, or prestige.

## When not to use

- The plan is still being designed → run `roblox-blueprint` / `roblox-blueprint-psychology` first.

## Default implementation pattern

### State (server-authoritative)

```luau
-- src/server/Progression/ProgressionService.server.lua
type ProgressionData = {
    xp: number,
    level: number,
    prestige: number,
    unlocks: {[string]: boolean},
    lastSavedUtc: number,
}
```

Stored in `DataStoreService:GetDataStore("PlayerProgression")` keyed by `userId`. Cached in-memory while the player is in-session.

### Curve

Externalize the curve in a config module so designers (or the user) can tune without touching service code:

```luau
-- src/shared/Progression/ProgressionConfig.lua
return {
    xpForLevel = function(level) return 100 * (level ^ 1.5) end,
    maxLevel = 100,
    prestigeUnlockLevel = 100,
    rebirthBonusPerPrestige = 0.10,
}
```

### Grant flow

```luau
-- server-only function
function ProgressionService.grantXp(player, amount, reason)
    if typeof(amount) ~= "number" or amount <= 0 then return end
    local data = ProgressionService._cache[player.UserId]
    data.xp += amount
    while data.xp >= ProgressionConfig.xpForLevel(data.level + 1) and data.level < ProgressionConfig.maxLevel do
        data.xp -= ProgressionConfig.xpForLevel(data.level + 1)
        data.level += 1
        LevelUpRemote:FireClient(player, data.level)
    end
    player:SetAttribute("Level", data.level)
    player:SetAttribute("Xp", data.xp)
    AnalyticsService:log(player, "xp_granted", { amount = amount, reason = reason })
end
```

### Replication

- `Player:SetAttribute("Level", n)` and `Player:SetAttribute("Xp", n)` auto-replicate.
- `LevelUpRemote` (server→client) for the celebratory toast.

### Persistence

- Autosave on `PlayerRemoving` + every N minutes.
- Use `UpdateAsync` with retry + exponential backoff on throttle.
- On data load failure, **do not give the player a fresh save** — kick with a clear message and `BindToClose` flush.

### Rebirth / prestige

```luau
function ProgressionService.attemptRebirth(player)
    local data = ProgressionService._cache[player.UserId]
    if data.level < ProgressionConfig.prestigeUnlockLevel then return false end
    data.prestige += 1
    data.level = 1
    data.xp = 0
    data.unlocks = {}  -- or keep some; design choice
    player:SetAttribute("Prestige", data.prestige)
    RebirthRemote:FireClient(player, data.prestige)
    return true
end
```

## Verification

- Unit: `grantXp` with valid input increments correctly; with invalid input is a no-op.
- Runtime: in Studio Play Solo, `execute_luau` to call `grantXp(testPlayer, 1000, "test")` → assert `Player.Level` attribute changed + LevelUpRemote fired.
- Adversarial: client tries to set its own Level attribute → server attribute write overwrites; or use a server-only attribute setter (Players can't write player attributes from client).
- Persistence: leave + rejoin → XP and level restored.

## Anti-pattern checks

- ❌ Client RemoteEvent like `GrantMyselfXpRemote` exists. **Never.**
- ❌ XP table stored client-side and synced occasionally.
- ❌ Curve hardcoded inside the grant function (un-tunable).
- ❌ `SetAsync` instead of `UpdateAsync` for save (race risk across servers).
- ❌ Silent save-failure swallowed (no log, no retry).

## Roblox-fit notes

- First level-up should arrive in ~2–5 minutes of first play.
- Display next-level XP requirement clearly (`current / required`).
- Prestige should grant a **visible persistent flex** (badge, icon, title) — see `roblox-forge-status`.
