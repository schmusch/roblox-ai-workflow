# Server Authority — Non-Negotiable Rules

The single most important architectural invariant in Roblox development. Skills assume these rules. Code that violates them gets rejected.

## The core principle

> **Clients request. Server validates. Server mutates canonical state.**

That's it. Three roles. Don't mix them.

## Why this is non-negotiable

Roblox clients run on the player's machine. Players can — and do — modify their client. Exploits range from simple input spoofing to full executor abuse (Synapse, Krnl, etc.). Any logic that *trusts the client* is exploitable in production. Treat every value coming from a client as **potentially attacker-controlled**.

## Rules

### Rule 1: RemoteEvent / RemoteFunction parameters are untrusted

Every `OnServerEvent` and `OnServerInvoke` handler must validate **every parameter**:
- type check (`typeof(x) == "number"`)
- range check (positive, within expected min/max)
- ownership check (does this player actually own that item?)
- rate limit (is this player firing the remote 100×/sec?)

```luau
-- BAD
buyItemRemote.OnServerEvent:Connect(function(player, itemId, price)
    grantItem(player, itemId)
    deductCurrency(player, price)  -- client decides price?! exploit-paradise
end)

-- GOOD
buyItemRemote.OnServerEvent:Connect(function(player, itemId)
    if typeof(itemId) ~= "string" then return end
    local item = CATALOG[itemId]
    if not item then return end                          -- unknown SKU
    if not isPurchasable(player, item) then return end   -- ownership / level gate
    if not canAfford(player, item.price) then return end -- server reads server-side wallet
    deductCurrency(player, item.price)                   -- server price
    grantItem(player, itemId)
end)
```

### Rule 2: Economy / inventory state lives only on the server

- The player's wallet, inventory, level, XP, equipped items live in **server memory** + **DataStoreService**.
- The client gets a **replicated read-only view** (via remote-pushed updates, attributes, or replicated values).
- The client UI reads from the replicated view; it never mutates it locally and trusts that mutation.

### Rule 3: Damage / combat is server-resolved

- Client-sent damage is suspect. At minimum:
  - server validates attacker can reach target (distance / line-of-sight)
  - server validates attacker has the weapon equipped
  - server applies cooldown / rate-limit
  - server clamps damage to a known weapon value, not a client-provided number
- For competitive shooters, server-authoritative hit registration (or carefully designed server-reconciled client prediction) is the only safe model.

### Rule 4: DataStore writes happen only on the server, only after validation

- Never call `DataStoreService:GetDataStore():SetAsync()` based on raw client input.
- Server reads → server mutates in-memory model → server writes back on save trigger (player leave, autosave tick).
- Use `UpdateAsync` (not `SetAsync`) for any field that can race across servers.
- Handle DataStore failure: retry with backoff, queue the write, and **never silently drop** a save.

### Rule 5: MarketplaceService receipts are the source of truth for paid items

- Listen to `ProcessReceipt` on the server.
- Return `PurchaseGranted` only after the grant is durably written to DataStore.
- Return `NotProcessedYet` on any failure so Roblox retries (idempotency-keyed by `PurchaseId`).

### Rule 6: Trading / player-to-player transfers need atomic dual-update + anti-dupe

- A trade is two state updates that must both succeed or both fail.
- Use a server-side `TradeSession` object holding both sides' offers, locked once both confirm.
- After lock, grant items to each side **and** remove items from the giver in the same server-tick before persisting.
- Never expose the trade-resolution logic to client input after the lock step.

### Rule 7: Client → server is request, server → client is canonical update

- RemoteEvent client-to-server: "I want to do X." Server may reject silently or with a structured error.
- RemoteEvent server-to-client: "Your state is now Y." Client UI re-renders against the new state.
- RemoteFunction client-to-server (request-response): use sparingly — yields the client. Validate exactly the same way.
- RemoteFunction server-to-client: **avoid**. Clients can throw / hang and stall the server thread.

## Rate-limit pattern (default-on)

Every player-facing remote should have a rate limit:

```luau
local lastFire = {} -- [Player] = tickWhenLastAllowed
local function rateLimit(player, key, perSecond)
    local now = os.clock()
    local bucket = lastFire[player] or {}
    if (bucket[key] or 0) > now then return false end
    bucket[key] = now + (1 / perSecond)
    lastFire[player] = bucket
    return true
end
```

## Replication patterns

- **Attributes** on a player or instance → cheap, automatic replication, good for small scalars (level, currency display).
- **RemoteEvent push** → use for events ("you leveled up", "trade accepted") and for batched state updates.
- **Streaming / `:SetNetworkOwner(nil)`** → keep ownership of moving parts on the server when they're authoritative (NPCs, vehicles in PvP).

## Smell list

If any of these appear, the design is broken:
- Client sends "my new currency value" to the server.
- Client tells the server "I picked up item X" and server trusts it.
- Server reads "damage amount" from a client RemoteEvent payload and applies it raw.
- Inventory state stored only in the client (LocalScript) and synced occasionally.
- DataStore write triggered directly inside a RemoteEvent handler with no validation layer.
- `FilteringEnabled = false` (it's been mandatory for years; if you see this, the codebase is ancient).

## When unsure

Ask: *"If a player edited their client to send arbitrary values to this RemoteEvent, what's the worst they could do?"* If the answer is "duplicate items / grant themselves currency / damage other players uncontrollably / corrupt my DataStore", you have a server-authority hole. Fix it before shipping.
