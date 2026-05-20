---
name: roblox-blueprint-social
description: Use during blueprint planning for social mechanics — parties, guilds, trading, co-op, invites, friend systems, shared progression. Designs the social structure with anti-abuse guardrails, friction-minimizing entry points, and replication patterns. Use when the user says "add parties", "design guilds", "implement trading", "make it social", or when the feature depends on multi-player interaction.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Blueprint — Social

Blueprint deepening skill for **social mechanics**: parties, guilds, trading, co-op, invites, friend systems, shared progression, gifting.

Roblox is socially native — social mechanics done well can be a primary retention layer. Done poorly they introduce dupe exploits, harassment vectors, and abandonment risk.

## When to use

- The feature is a party / guild / trade / co-op / invite / gift / shared-progress system.
- The brief's primary or supporting driver is Community.
- A social layer is being added on top of an existing solo loop.

## When not to use

- Single-player-only features.
- Pure server-side infrastructure changes with no social surface.

## What this skill produces

A social mechanic spec covering:

1. **Mechanic type** — party / guild / trade / gift / co-op / shared-progress.
2. **Entry friction** — how fast can players engage (target: under 5 seconds, 2 taps).
3. **State ownership** — who is server-authoritative for the shared state.
4. **Replication shape** — what propagates to whom and when.
5. **Anti-abuse guardrails** — anti-dupe, anti-spam, anti-harassment, anti-deadweight.
6. **Failure / lapse handling** — what happens when a member disconnects, server hops, churns.
7. **Visibility surfaces** — where the social state is seen (hub, in-game, profile).
8. **Cross-platform considerations** — mobile-friendly invite, in-game chat constraints.
9. **Persistence shape** — which DataStore (per-player vs shared) holds the data.
10. **Verification path** — adversarial test cases (dupes, race conditions, harassment patterns).

## Method

### 1. Pick the mechanic and its trust boundary

| Mechanic | State authority | Cross-server? | Persistence? |
|----------|----------------|---------------|--------------|
| Party (in-session) | Server (single server) | No (party = one server) | No (in-memory) |
| Guild | Server + DataStore | Yes (members may be on different servers) | Yes (per-guild key) |
| Trade | Server (single server) | No (both parties in same server) | No, but post-trade inventory persists |
| Gift | Server + DataStore | Yes (recipient may be offline) | Yes (mailbox) |
| Co-op session | Server (single server) | No | Optional (shared progress) |
| Shared progression (guild quest) | Server + DataStore + MemoryStore | Yes | Yes (per-guild) |

### 2. Minimize entry friction

Roblox social mechanics live or die on friction. Targets:
- **Party:** join from friend list in 1 tap.
- **Guild:** join via invite link / code in 2 taps; one-tap auto-accept if invited by friend.
- **Trade:** initiated via ProximityPrompt or party UI — never a multi-screen wizard.
- **Co-op queue:** matchmake in under 15 seconds; offer "play with random" alongside "play with friend".

Sketch the player flow tap-by-tap. If any step takes more than 2 taps, design it down.

### 3. State ownership + replication

Decide who owns the canonical state and which clients see what:

**Party example:**
- Server holds `PartySession { leader, members, sharedXp, raidCooldown }`.
- All members get a `PartyState` push on any change.
- Visitors / non-members see read-only summary (party name, member count).

**Guild example:**
- Each server holds an in-memory cache of the guild's current state (loaded from DataStore on first member join).
- Cross-server sync via `MessagingService` topic `Guild_{guildId}`.
- DataStore is the canonical source; cache is the fast read.
- `UpdateAsync` is the canonical write path (race-safe).

### 4. Anti-abuse guardrails (mandatory)

| Mechanic | Risks | Guardrails |
|----------|-------|------------|
| Trade | dupe, scam, item theft | atomic dual-update at lock; re-verify ownership at lock; trade log per session; rate-limit trade-start |
| Gift | dupe, money laundering | server-only mailbox; receiver-side claim with server inventory grant; no client mutation |
| Invite | spam, harassment | rate-limit invites per sender; recipient block list; auto-ignore repeat-decline from same sender |
| Guild | deadweight, drama, takeover | role-based permissions; leader transfer cooldown; guild dissolve = 24h grace + leader-only |
| Co-op match | griefing, AFK | server-detected AFK kick after N min; report flow; vote-kick with cooldown |

Specifically for **trading** (highest-risk):
- Re-verify both sides' item ownership at the lock step, not at the offer step.
- Use a single server-tick atomic mutation: remove from both, grant to both, then persist.
- Log the trade pair, items, and timestamp for support recovery.
- Rate-limit `TradeStart` to N per minute per player.
- Block trades between accounts that joined too recently (anti-account-farming).

### 5. Failure / lapse handling

For each mechanic, handle:
- **Member disconnects mid-action:** trade aborts, party member ghost-removes, guild member status to offline (not removed).
- **Server hops:** party stays (TeleportService cross-server party teleport), guild reloads from DataStore on new server.
- **Churned member:** guild auto-demotes after N days inactive; party reforms without them.

### 6. Visibility surfaces

Where do players see the social state?
- Hub world — guild banners, party-up prompts.
- HUD — current party member list with health/level mirror.
- Profile — friends, guild, recent co-op stats.
- Leaderboard — guild ranks, party leaderboards.

### 7. Mobile / chat constraints

- Roblox chat has filtering; never use chat as the primary invite channel (filtered codes break).
- Mobile screens are small — limit party UI to 4 members visible, scroll for more.
- Push notifications aren't available — use in-game "friends online" cue.

## Output format

```markdown
## Social mechanic: party-trade

### Mechanic
- **Type:** in-session trade between party members
- **Trust boundary:** server-authoritative; both players in same server

### Entry friction
- ProximityPrompt → trade panel opens for both (1 tap each)
- Add item: click in inventory → adds to offer (1 tap per item)
- Lock: tap "ready" button (1 tap)
- Total: 3 taps to a locked trade

### State ownership
- Server: `TradeSession { a, b, state }` keyed by session ID
- Both clients get `TradeStateRemote` push per mutation
- No cross-server (party trade is in-session only)

### Anti-abuse
- Both sides re-verified at lock (ownership + inventory presence)
- Atomic swap in single server tick: deduct both, grant both, persist
- Rate limit: 1 trade start per 30s per player
- Trade log: server logs trader IDs + item list to DataStore for support recovery
- New-account block: accounts <24h old can't initiate trades

### Failure handling
- Either player disconnects → session cancelled, no mutation
- Inventory desync at lock → session cancelled, both notified
- DataStore save fail post-swap → roll back in-memory + retry with backoff

### Visibility
- Party HUD shows party members and "trade with" affordance
- No status surface for trades themselves (volume-private)

### Persistence
- Inventory changes go through standard `InventoryService`
- Trade log: `TradeLog/{date}` key, append-only

### Verification
- Two test players trade item A↔B → assert post-swap inventories
- Adversarial: client fires LockRemote for unowned session → server rejects silently
- Adversarial: client sends `TradeAddItemRemote` with item it doesn't own → server rejects
- Race: client sends multiple LockRemote calls simultaneously → server idempotent (only first wins)
```

## Roblox-specific framing

- **Robux trades are forbidden** by TOS — never design trade systems that exchange Robux for items.
- **Under-13 chat constraints** — if your audience includes under-13, the chat-based "send a code to join" flow is blocked by filtering. Use friend-list invites.
- **Friend / group APIs** — `Players:GetFriendsAsync`, `GroupService:GetGroupInfoAsync` are throttled — cache results.
- **Real-money side-effects** — features that approximate gambling (loot boxes with paid currency) face heightened regional regulation. Audit early.

## Handoff

Social mechanic spec slots into the main blueprint. After completion:

> "Social mechanic spec complete. Recommend handing off to `roblox-forge-community` for implementation, or returning to `roblox-blueprint` to integrate into the main plan."
