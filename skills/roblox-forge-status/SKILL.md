---
name: roblox-forge-status
description: Use when implementing cosmetics, titles, leaderboards, profile badges, showcase slots, or rarity systems in Roblox. Builds the visibility layer that makes player status flexible to other players. Use when the user says "add titles", "implement leaderboard", "build cosmetics", "forge status".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Status

Execution skill for the **Status** driver. Implements the surfaces where players see other players' achievements — cosmetics, titles, leaderboards, showcase slots, rarity color systems.

## When to use

- A blueprint includes status-driver mechanics.
- The user wants to add titles / leaderboards / cosmetics / showcase slots / rarity systems.

## Default implementation pattern

### Cosmetics (equipped, visible)

```luau
-- src/server/Cosmetics/CosmeticsService.server.lua
type EquippedCosmetics = {
    title: string?,
    hatId: string?,
    auraId: string?,
    nameColor: string?,
}
```

- Owned cosmetics in DataStore (`PlayerCosmetics/{userId}`).
- Equipped cosmetics in DataStore + replicated as player attributes for in-world rendering.
- Equip request: `EquipCosmeticRemote` (client→server) → server validates ownership → updates attribute.

### Titles

- Implement as a string attribute on the Player or as a BillboardGui above the character.
- Rendering: `LocalScript` reads other players' `Title` attribute → constructs a BillboardGui above the head.
- Color / glow tied to rarity tier from `references/roblox-vocabulary.md`-style config.

### Leaderboards

Two kinds — pick deliberately:

**In-experience leaderboard (legacy `leaderstats`):**
```luau
local stats = Instance.new("Folder")
stats.Name = "leaderstats"
stats.Parent = player
local level = Instance.new("IntValue")
level.Name = "Level"
level.Value = playerData.level
level.Parent = stats
```
Roblox renders this in the player list top-right. Use for cheap always-visible status.

**Persistent leaderboard (top-N over time):**
- Use `DataStoreService:GetOrderedDataStore`.
- Server writes the player's current value on key change or periodically.
- Read top N via `GetSortedAsync(true, N)`.
- Cache the result on a SurfaceGui / ScreenGui leaderboard; refresh every M seconds.

### Rarity color system

Externalize in config so designers can tune:

```luau
-- src/shared/Cosmetics/RarityConfig.lua
return {
    Common    = { color = Color3.fromRGB(180,180,180), order = 1 },
    Uncommon  = { color = Color3.fromRGB( 80,200, 80), order = 2 },
    Rare      = { color = Color3.fromRGB( 60,120,255), order = 3 },
    Epic      = { color = Color3.fromRGB(170, 80,255), order = 4 },
    Legendary = { color = Color3.fromRGB(255,170, 60), order = 5 },
}
```

### Showcase slots (housing / trophy room)

- Server holds owned items + which slot they're displayed in.
- Slot count gated by progression / gamepass.
- Other-player visit: server replicates owner's slot config to visitor client → local renders read-only.

## Replication / visibility audit

Status only works if **other players see it**. For every status mechanic, name the surface:

| Mechanic | Where it's seen |
|----------|-----------------|
| Title | BillboardGui above head, in-world, all clients |
| Cosmetic (hat / aura) | Attached to character, all clients |
| Leaderboard rank | Hub SurfaceGui / persistent leaderboard board |
| Showcase | Visitor sees on house tour |
| Rarity color | In inventory, in trade window, in chat tag |

If a status mechanic has no visibility surface, **the design is broken** — add one before implementing.

## Anti-pattern checks

- ❌ Status only visible in your own inventory → no flex, no driver pull.
- ❌ Leaderboard with only top-100 visible → 99% of players invisible.
- ❌ Equip client-validated only → exploitable.
- ❌ Rarity colors inconsistent across surfaces (inventory says blue, world says green).
- ❌ Cosmetic ownership double-stored (in two DataStores out of sync).

## Verification

- Other player joins → sees the host's title BillboardGui and equipped hat.
- Player equips cosmetic from inventory → attribute updates → world reflects within ~1 frame.
- Persistent leaderboard refreshes after a value change → reads ordered store correctly.
- Adversarial: client sends `EquipCosmeticRemote` with an item it doesn't own → server rejects silently.

## Roblox-fit notes

- BillboardGui scaling on mobile must be tested — too-tight text becomes unreadable.
- `leaderstats` is heritage but powerful — players know to look at the top-right.
- Persistent leaderboards have a 1-key-per-leaderboard limit on free-tier OrderedDataStore quota — design names accordingly.
- Trade-value of cosmetics is a separate concern — see `roblox-blueprint-social`.
