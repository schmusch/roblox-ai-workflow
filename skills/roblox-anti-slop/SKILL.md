---
name: roblox-anti-slop
description: Use to strip enterprise jargon (Controller, Service-as-non-engine-service, Repository, DTO, Manager, Handler) out of Luau code and rewrite it as Roblox-native. Use when reviewing generated code that looks like Java enterprise architecture, when the user complains it doesn't "feel like Roblox", or as a final pass after roblox-forge.
domain: roblox-studio
audience: creator
artifact-type: skill
---

# Roblox Anti-Slop

Removes enterprise-software jargon and patterns from Luau code, rewriting them as engine-native Roblox.

## When to use

- After `roblox-forge` as a final pass, especially on AI-generated code.
- When reviewing existing code that reads like Java / Spring / .NET enterprise.
- When the user says "this doesn't feel like Roblox", "too abstract", "what's a Controller doing here".
- Before merging an AI-assisted PR.

## When not to use

- Code that's already Roblox-native (no enterprise smells).
- The existing repo deliberately uses an architectural framework (e.g. Knit, AGF, Roact) — preserve the framework, only fix actual slop within it.

## The replacement reference

Authoritative list: `references/roblox-vocabulary.md`. Quick reminders:

| ❌ Replace | ✅ With |
|----------|---------|
| `<Domain>Controller` | `<Domain>Module` or specific name |
| `<Domain>Service` (when not an engine service) | `<Domain>Module` or `<Domain>System` |
| `<Domain>Repository` | `<Domain>Store` + `DataStoreService` calls |
| `<Domain>DTO`, `<Domain>ViewModel` | Plain Luau table, typed Luau annotation |
| `<Domain>Manager` (vague) | Concrete name (`PartyMatchmaker`) |
| `<Domain>Handler` (vague) | `On<Event>` function or `<Event>Remote` |
| `Middleware`, `pipeline` | Server-side validation function |
| `Microservice`, `API gateway` | `MessagingService` / `TeleportService` |
| Abstract base class hierarchy | Composition + typed Luau |

## Method

### 1. Scan for smell tokens

Grep / `script_grep` (via Studio MCP) for:
- `Controller`, `Repository`, `DTO`, `ViewModel`, `Manager` (when not `MarketplaceService`-related), `Handler`, `Middleware`, `Pipeline`, `Microservice`, `BaseClass`, `AbstractFactory`, `Singleton` (when not a normal Module pattern)
- Type names ending in `Service` that aren't actual Roblox services
- Folder names matching enterprise patterns (`controllers/`, `repositories/`, `dtos/`)

Note: a name containing `Service` is OK when it refers to a Roblox service (`DataStoreService`, `MarketplaceService`) — those stay.

### 2. For each match, decide

- **Cosmetic rename** (the structure is fine, just the name is slop) → rename to a Roblox-native equivalent.
- **Structural fix** (the structure itself is enterprise — e.g. a "Repository" layer adds nothing) → flatten the structure and update callers.
- **Domain change** (the abstraction exists for an enterprise reason but Roblox has a built-in) → replace with the engine primitive.

Examples:

- `class InventoryController` exposing CRUD methods → `InventoryModule` with the same methods.
- `IInventoryRepository` interface with concrete implementation → drop the interface; use the DataStore calls directly in `InventoryModule`.
- `class InventoryService extends BaseService` → flat `InventoryModule` returning a table; ditch the inheritance chain.
- `interface InventoryDTO { ... }` → typed Luau:
  ```luau
  type InventoryItem = { id: string, qty: number, acquiredUtc: number }
  ```

### 3. Update all callers

A rename or structural change is incomplete until every reference is updated. Use `script_grep` for the old name, replace with the new.

### 4. Verify no regressions

- Run repo lint / typecheck.
- Run existing tests.
- Use `execute_luau` (Studio MCP) to invoke the renamed module if appropriate.

## When to push back vs accept enterprise patterns

Some enterprise patterns **do** belong:
- A `MarketplaceService` (engine service) — keep.
- A `Service` suffix when it accurately names a Roblox engine service — keep.
- A "Singleton" pattern implemented as a module returning a singleton table — that's normal Lua, not slop.
- A "Manager" when it's a concrete coordinator with a meaningful name (`PartyMatchmaker`) — fine.
- Existing project's chosen framework (Knit's `KnitService`, AGF, Roact components) — preserve; don't fight the framework.

Don't reflexively rename — judge each case. The test: **does this name help a Roblox developer understand what it does, or does it require enterprise mental translation?**

## Output format

After the pass, summarize:

```markdown
## Anti-slop pass results

### Renamed (cosmetic)
- `InventoryController` → `InventoryModule`
- `IInventoryRepository` (interface) → removed; calls go directly to DataStoreService

### Restructured
- `InventoryService extends BaseService` → flat `InventoryModule` table; dropped BaseService

### Removed
- `dtos/` folder (replaced with typed Luau in shared/Types.lua)
- `IRepositoryFactory` (abstraction layer; replaced with direct DataStore access)

### Preserved
- `MarketplaceService` calls (engine service — correct)
- `PartyMatchmaker` (concrete, meaningful name)

### Touched files
- src/server/Inventory/InventoryModule.lua (was InventoryController.lua)
- src/shared/Inventory/InventoryTypes.lua (new, replaces DTO folder)
- src/server/Trade/TradeModule.lua (caller update)
- ... (N files)

### Tests / verification
- selene clean
- luau-lsp typecheck clean
- TestEZ test pass (12/12)
```

## Anti-pattern check (meta)

- ❌ Renaming things without updating callers → broken refs.
- ❌ Removing an abstraction the existing code relies on without replacing it → broken behavior.
- ❌ Reflexively renaming `MarketplaceService` → don't touch engine services.
- ❌ Anti-slop pass that doesn't update tests → silently broken tests.

## Roblox-fit reminder

If a name only makes sense after 3 layers of mental translation, it's slop. If a name reads naturally to a Roblox developer, it stays.
