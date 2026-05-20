# Roblox Security Audit Checklist

Canonical exploit-vector checklist used by `roblox-security-review` and `roblox-ultrawork`. Walk this list against any change touching remotes, persistence, marketplace, trading, or competitive systems.

Each item names the **attack**, the **check** that closes it, and the **typical fix**.

## Threat model

- Client process is fully compromised (executor tools, memory editors, Lua injection).
- Any RemoteEvent / RemoteFunction can be called with arbitrary payloads at arbitrary rates.
- Replicated state visible on the client is leaked publicly.
- Multi-account / alt-farming defeats single-player rate limits.
- Roblox retries failed `ProcessReceipt` calls — code must be idempotent.

## 1. Remote handler validation

For every `OnServerEvent` and `OnServerInvoke` handler in scope.

| Attack | Check | Fix |
|--------|-------|-----|
| Client sends wrong type | Every param has `typeof(x) == expected_type` guard | Add type guard; early return |
| Client sends out-of-range value | Every numeric param has min/max bound check | Add bounds check |
| Client references entity it doesn't own | Server reads canonical ownership before mutating | Add ownership lookup |
| Client targets nonexistent entity | Server resolves the reference and validates existence | Add existence check |
| Client targets restricted action (admin) | Server checks authorization | Add role / permission check |
| Client fires faster than allowed | Per-player rate limit on server | Add rate-limit pattern (see `references/server-authority-rules.md`) |
| Client sends value the server should compute | Server reads its own canonical value | Ignore client-supplied price/qty; use server values |

## 2. Economy & inventory dupe paths

| Attack | Check | Fix |
|--------|-------|-----|
| Grant + remove are non-atomic | One of: pcall-wrapped transaction, single-tick state mutation, explicit rollback | Wrap in transaction-style mutation |
| Two simultaneous calls race | Per-user lock or `UpdateAsync` for canonical write | Add per-userId mutex or use UpdateAsync |
| Disconnect during grant leaves phantom item | Save triggers + `BindToClose` flush + recovery on rejoin | Add BindToClose flush + rejoin reconciliation |
| Drop / pick-up cycle dupes | Item ID has server-tracked owner; pickup validates owner | Add server-owned `Owner` tag; validate at pickup |
| Trade resolves both sides keeping items | Atomic dual-update at resolution; lock after both confirm | See trading section below |
| Use of consumable both succeeds and fails | Single state mutation; outcome determined server-side | Server holds decrement-and-grant pair in one tick |

## 3. Persistence (`DataStoreService`)

| Attack | Check | Fix |
|--------|-------|-----|
| Race write across servers | `UpdateAsync` on race-prone keys, never `SetAsync` | Switch to `UpdateAsync` |
| Save fails silently | Retry with exponential backoff + queue + log | Wrap `pcall` retries; log final failure |
| Server shutdown loses unsaved data | `game:BindToClose(flushAll)` | Add bind hook |
| Load fail gives player a fresh save (rollback exploit) | On load failure, kick with explicit error; do NOT give fresh state | Refuse to grant fresh; kick or queue |
| Corrupted save passes through | Sanity check on loaded value; clamp / reject if out of bounds | Add load-time validation |
| Save key uses `Player.Name` | Use `Player.UserId` (stable) | Switch key |
| Saved data exceeds quota | Trim history / use OrderedDataStore for time-series | Restructure shape |

## 4. MarketplaceService receipts

| Attack | Check | Fix |
|--------|-------|-----|
| Double-grant on retry | Idempotent on `PurchaseId`; tracked already-processed list per user | Track processed PurchaseIds in DataStore; check before grant |
| Grant before persist (refund-without-loss exploit) | Persist grant to DataStore FIRST, then return `PurchaseGranted` | Reorder: persist → granted |
| Receipt processed but grant logic fails silently | Wrap grant in pcall, return `NotProcessedYet` on failure for retry | pcall + retry contract |
| Receipt for offline player dropped | Queue / MessagingService route or "grant on next login" persistence | Add offline queue |
| Receipt response delayed (>30s) and Roblox retries | Idempotency via PurchaseId; quick acknowledgement of `NotProcessedYet` if not ready | Quick `NotProcessedYet` then process later |

## 5. Trading / player-to-player transfer

| Attack | Check | Fix |
|--------|-------|-----|
| Modify offer after lock | After lock, server ignores any offer-change input | Lock state strictly server-side; reject client edits |
| Resolution non-atomic (dupe) | Single-tick dual transfer with rollback on partial failure | Wrap in transaction |
| Third party injects into trade session | Session is keyed to the two participating UserIds; server validates source on every input | Per-session participant check |
| Disconnect mid-trade with locked offer | On `PlayerRemoving`, cancel session safely; return offers to original owners | PlayerRemoving handler with rollback |
| Server validates inventory at offer time but resolves later — item gone by resolution | Re-validate inventory at resolution time, not at offer time | Move validation to resolution |
| Both sides offer item with same ID | Server reads canonical inventory at resolution; client-claimed UUIDs don't matter | Server-side inventory checks |
| Trade spam (DOS via offer requests) | Rate-limit trade offers per player | Add rate-limit |

## 6. Damage / combat (PvP / competitive)

| Attack | Check | Fix |
|--------|-------|-----|
| Client claims damage amount | Server clamps damage to known weapon value | Server reads weapon catalog; ignores client damage |
| Client claims hit target at impossible range | Server validates distance / line-of-sight | Add reachability check |
| Client claims hit without weapon equipped | Server reads canonical equipped state | Add equipped check |
| Client fires faster than weapon cooldown | Per-weapon, per-player cooldown server-side | Add server cooldown tracking |
| Client claims headshot multiplier without server raycast | Server raycasts the hit, decides multiplier | Server hit-detection |
| Speed hack / teleport | Server tracks player position deltas; flag impossible movement | Add anti-cheat speed check |

## 7. Replication leakage

| Attack | Check | Fix |
|--------|-------|-----|
| Admin list in `ReplicatedStorage` | Move to `ServerScriptService` / `ServerStorage` | Move + audit references |
| Anti-cheat thresholds in client-visible config | Move thresholds to server-only module | Move + audit references |
| Server-only ModuleScript replicated visibly | Move to server-only container | Move + audit references |
| Debug / admin remote available to all clients | Either remove or gate behind authorization check | Add `isAdmin(player)` check, return early |
| Private game-mode parameters leaked via Attributes | Use server-only memory; don't replicate sensitive values | Stop replicating sensitive attrs |

## 8. Rate-limit completeness

| Attack | Check | Fix |
|--------|-------|-----|
| No rate-limit on remote | Per-player rate-limit on every player-facing remote | Add rate-limit |
| Rate-limit defeated by reconnect | Track by `UserId`, not connection / session | Migrate tracking to UserId |
| Rate-limit defeated by alt accounts | At minimum, log and detect; design-level question if widespread | Server logs alt patterns; design review |
| Expensive query rate-limited only after work | Rate-limit before doing the work | Move check to top of handler |
| Rate-limit reset on server hop | MessagingService share state, or accept per-server reset | Document as known limitation or share via MessagingService |

## 9. `RemoteFunction:InvokeClient`

| Attack | Check | Fix |
|--------|-------|-----|
| Server thread yields forever on client | Wrap in `task.spawn` with explicit timeout | Refactor to RemoteEvent push or task.spawn + timeout |
| Client throws, propagates to server | Wrap in `pcall` | Add pcall |
| Server stack blocked by malicious client | Avoid `InvokeClient` entirely | Design review |

**Default recommendation:** do not use `RemoteFunction:InvokeClient`. The cost of safe usage usually exceeds the cost of refactoring to server→client RemoteEvent push.

## 10. HttpService (if enabled)

| Attack | Check | Fix |
|--------|-------|-----|
| Request to attacker-controlled URL | Whitelist host on server; reject others | Add host whitelist |
| Secret token leaks in logs / error messages | Never log full request payload; redact tokens | Log scrubbing |
| Synchronous request stalls server | `task.spawn` and async-style response | Move to async |
| Request body from client trusted | Server constructs request body from server state, not client input | Server-only request shape |

## 11. Anti-cheat surface (advanced)

For competitive games:

- **Movement** — server-authoritative or sanity-checked client movement (speed cap, teleport detection).
- **Damage** — server-authoritative hit registration; client prediction only for visual feedback.
- **Anomaly logging** — log impossible XP / currency gain; impossible move speed; impossible kill streak. Forensics matter even if you can't prevent everything.
- **Honeypot remotes** — fake remotes a non-exploiter would never call; exploiters get flagged for using them.

## 12. Build / deploy

| Attack | Check | Fix |
|--------|-------|-----|
| Place file contains test / debug remote left over | Pre-publish lint pass that searches for `_debug`, `_admin`, `test_` remotes | Add CI check |
| Game published with `StudioOnly` checks defeated | Code that says "if Studio, allow everything" — clients can fake `IsStudio()` from their side, but this only matters if server consults it incorrectly | Audit `IsStudio` server-side uses |
| Wally package update introduces a backdoor | Pin versions; review changelog before bumping | Process: code-read package source on bump |

## Closing summary

The biggest categories of exploit on Roblox:
1. **Remote validation gaps** (Category 1).
2. **Economy dupe paths** (Category 2).
3. **Persistence rollback / corruption** (Category 3).
4. **Receipt double-grant** (Category 4).

Walk these four at minimum on every monetization / persistence / trading change. The others matter when their surface is in scope.
