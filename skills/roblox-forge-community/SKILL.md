---
name: roblox-forge-community
description: Use when implementing guilds, parties, trading, co-op, invites, gifting, or shared progression in Roblox. Builds social mechanics with anti-abuse guardrails and low-friction entry. Use when the user says "implement guilds", "build the trade system", "add party mode", "forge community".
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Forge — Community

Execution skill for the **Community** driver. Implements social mechanics designed in `roblox-blueprint-social`: parties, guilds, trading, gifts, co-op, shared progression.

## When to use

- A blueprint includes social mechanics and is approved.
- The user wants to implement the social layer.

## Default implementation pattern

### Party (in-session, single server)

```luau
-- src/server/Party/PartyService.server.lua
local sessions = {}  -- [partyId] = { leader, members = {[Player]=true}, sharedXp, raidCooldown }

function PartyService.createParty(leader)
    local id = HttpService:GenerateGUID(false)
    sessions[id] = { leader = leader, members = {[leader] = true}, sharedXp = 0 }
    leader:SetAttribute("PartyId", id)
    return id
end

function PartyService.inviteToParty(leader, target)
    if not isLeaderOf(leader) then return end
    InvitePartyRemote:FireClient(target, leader, sessions[leader:GetAttribute("PartyId")])
end

function PartyService.acceptInvite(player, partyId)
    if not sessions[partyId] then return end
    sessions[partyId].members[player] = true
    player:SetAttribute("PartyId", partyId)
    broadcastPartyState(partyId)
end
```

### Guild (cross-server, persistent)

- Guild list stored in `DataStoreService:GetDataStore("Guilds")`, keyed by guildId.
- Per-server cache loaded on first member join.
- Cross-server sync via `MessagingService:SubscribeAsync("Guild_" .. guildId, handler)`.
- All mutations go through `UpdateAsync` for race safety.

```luau
type GuildData = {
    id: string,
    name: string,
    leaderUserId: number,
    members: {[number]: {role: "leader" | "officer" | "member", joinedUtc: number}},
    treasury: number,
    weeklyGoal: { current: number, target: number, weekStartUtc: number },
}
```

### Trading (in-session, server-authoritative)

See `roblox-blueprint-social` for the full spec. Key rules:
- **Re-verify ownership at lock**, not at offer.
- **Atomic swap** in a single server tick.
- **Trade log** persisted for support recovery.
- **Rate limit** trade-start per player.
- **Anti-new-account block** (configurable).

### Gift mailbox (offline-friendly)

- Sender → server validates → server writes to recipient's mailbox in DataStore.
- Recipient (on next join) → server reads mailbox → claim UI.
- Server grants on claim, then removes from mailbox in same UpdateAsync write.

### Co-op session (matchmade)

- Queue stored in `MemoryStoreService:GetSortedMap("CoopQueue")`.
- Server scans the queue periodically, matches by skill / level proximity.
- On match: teleport players to a shared instance via `TeleportService:ReserveServer` + `TeleportService:TeleportToPrivateServer`.

## Anti-abuse guardrails (mandatory)

| Mechanic | Guardrails |
|----------|------------|
| Trade | re-verify at lock, atomic swap, log, rate-limit, new-account block |
| Gift | server-only mailbox, server-validated claim, no client mutation |
| Invite | rate-limit per sender, block list, auto-ignore repeat-decline |
| Guild | role permissions, leader-transfer cooldown, dissolve grace period |
| Co-op queue | AFK detection + kick, vote-kick with cooldown, report flow |

## Cross-server replication patterns

- **MessagingService** for guild-wide events (treasury updates, weekly goal, member role changes).
- Topic name: `Guild_{guildId}`.
- Servers subscribe on first guild-member join.
- Throttle: MessagingService has per-topic limits — debounce rapid updates.

## Persistence patterns

- Guild DataStore key: `Guild_{guildId}`.
- Per-member quick lookup: store `guildId` in player's main DataStore so login can fetch the right guild fast.
- On guild dissolution: 24h grace, members leave naturally; final write archives guild to a separate `GuildArchive` store.

## Anti-pattern checks

- ❌ Trade lock that doesn't re-verify ownership → dupe exploit.
- ❌ Gift claim that grants client-sent itemId → grant-anything exploit.
- ❌ Guild role check on client only → impersonation.
- ❌ MessagingService spammed on every minor change → throttled, then sync breaks.
- ❌ Party state stored client-side → leader-impersonation exploit.
- ❌ No rate limit on `InviteToPartyRemote` → spam vector.

## Verification

- **Trade adversarial:** client fires LockRemote for session it's not in → server rejects silently.
- **Trade dupe attempt:** offer item, then drop it just before lock → server detects ownership desync at lock and aborts.
- **Guild cross-server:** two players in different servers → leader updates treasury → both see the update within MessagingService latency.
- **Gift offline:** sender gifts when recipient is offline → recipient sees mailbox on next join.
- **Co-op queue:** two players queue → match → teleport into same private server.

## Roblox-fit notes

- **Robux-for-items is forbidden.** Never design trade systems exchanging Robux.
- **Under-13 chat is filtered** — invite codes shared via chat may not work. Use friend-list invites.
- **MessagingService quota** — 150 messages/min/topic on most tiers. Throttle.
- **MemoryStoreService quota** — limits per-experience write rate. Plan accordingly.
- **DataStoreService UpdateAsync retry** — implement exponential backoff; throttling is real.
