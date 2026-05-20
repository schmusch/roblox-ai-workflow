# Roblox Pre-Action Plan Template

Used by `roblox-pre-action` and `roblox-blueprint`. Fill out before any code-generation pass for non-trivial creator-domain work. The gate flips to `PRE_ACTION_COMPLETE: true` only when all sections are filled.

```markdown
# Roblox Pre-Action Plan: <task slug>

`PRE_ACTION_COMPLETE: false`

## 1. Task classification

- **Task type:** (new feature / extension / bugfix / refactor / asset / config)
- **Genre:** (simulator / combat / social / tycoon / obby / roleplay / sandbox / other)
- **Audience:** (casual under-13 / teen / mixed / mature / unknown)
- **Scale:** (single-server / cross-server / persistent world / event-driven)
- **Multiplayer assumptions:** (solo only / co-op / PvP / massive / mixed)
- **Monetization intent:** (none / cosmetic / gamepass / developer products / season pass / mixed)

## 2. Relevant Roblox concepts

- **Concepts:** (replication, server authority, persistence, real-time combat, economy, …)
- **Services:** (DataStoreService, MessagingService, TeleportService, MarketplaceService, …)
- **Classes:** (RemoteEvent, ModuleScript, Humanoid, ProximityPrompt, …)
- **Gameplay patterns:** (XP loop, daily login, trading, party-up, …)

## 3. Reference sources to consult

- **Canonical Roblox docs:** (specific Creator Docs URLs)
- **Implementation references:** (existing project files, open-source samples)
- **Dataset / corpus support:** (psychology-framework.md, vocabulary.md, …)

## 4. Canonical terms to use

- **Term standardization:** map enterprise/synonym terms to Roblox-native ones
- **Naming vocabulary:** (Module / Remote / Attribute naming conventions for this task)
- **Source:** `references/roblox-vocabulary.md`

## 5. Risks and uncertainties

- **Unsafe assumptions:** (anything client-trusted; anything depending on undocumented behavior)
- **Required validation:** (rate limit, ownership check, type check, range check)
- **Likely pitfalls:** (replication race conditions, DataStore size limits, throttling, …)

## 6. Proposed file tree

```text
src/
├── server/
│   └── <Feature>/
│       ├── <Feature>Service.server.lua
│       └── <Feature>Validator.lua
├── client/
│   └── <Feature>/
│       └── <Feature>Controller.client.lua
├── shared/
│   └── <Feature>/
│       ├── <Feature>Module.lua
│       └── <Feature>Types.lua
└── config/
    └── <Feature>Config.lua
```

(Adapt to existing repo conventions — Rojo `default.project.json` layout, or alternative.)

## 7. Category ownership

- **Server:** which scripts hold authority and own state mutation
- **Client:** which scripts handle input, prediction, UI
- **Shared:** which ModuleScripts are pure logic / data / types
- **Config:** data tables (catalog, balance, drops)
- **Assets:** Models, Sounds, Images this work depends on
- **Tests:** unit / integration / runtime-smoke targets

## 8. Naming convention

- **Folder naming:** (PascalCase per feature, lowercase for category buckets)
- **Module naming:** (`<Feature>Module`, not `<Feature>Manager`)
- **Remote / event naming:** (`<Feature><Verb>Remote`, e.g. `TradeOfferRemote`)
- **Config naming:** (`<Feature>Config`, e.g. `EconomyConfig`)

## 9. Implementation phases

1. **Vertical slice:** minimal end-to-end flow, server-authoritative, no UI polish
2. **Persistence + replication:** DataStore reads/writes, attribute replication, recovery
3. **UI:** StarterGui mirror of authoritative state
4. **Edge cases + tests:** rate limits, dupes, disconnect mid-flow, save failures
5. **Polish + tuning:** sounds, particles, balance values

## 10. Validation checkpoints

- [ ] Docs verified (creator docs + existing repo patterns)
- [ ] Architecture reviewed (server / client / shared boundaries explicit)
- [ ] File tree approved
- [ ] Server-authority rules satisfied (see `references/server-authority-rules.md`)
- [ ] Vocabulary aligned (no enterprise jargon)
- [ ] Implementation gate clear (what proves this works at runtime?)

`PRE_ACTION_COMPLETE: true`
```

## When to skip the pre-action plan

The gate is **not** required when:
- The task names a specific file + symbol + concrete change ("fix typo in `InventoryModule:GetItem`").
- It's a single-line bugfix with an existing test or reproduction.
- The user has explicitly authorized direct execution (e.g. "just fix it, I know what you need").

In all other cases — vague feature requests, new systems, monetization changes, persistence changes, anything cross-server — fill the gate.
