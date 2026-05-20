# Roblox-Native Vocabulary

Anti-slop reference: prefer engine concepts over generic software jargon. Skills consult this list when writing or reviewing Luau.

## The replacement table

| ❌ Enterprise / generic | ✅ Roblox-native | Notes |
|------------------------|------------------|-------|
| `Controller` (vague) | `<Domain>Module`, e.g. `InventoryModule`, `TradeHandler` | Name by concrete domain, not architectural role |
| `Service` (when not an engine service) | `Module` / `ModuleScript` | Reserve "Service" for actual Roblox services |
| `Repository`, `DAO` | `<Domain>Store`, `<Domain>Data`, `DataStoreService` calls | Roblox has DataStoreService; don't reinvent ORM concepts |
| `DTO`, `ViewModel` | Plain Luau table, typed Luau annotation | `type Trade = { offerer: number, items: {string} }` |
| `Manager` (vague) | Concrete name: `PartyMatchmaker`, `EconomyLedger` | Be specific |
| `Handler` (vague) | `<Event>Remote`, `On<Event>` | Tie to the actual remote / signal |
| `Middleware`, `pipeline` | Server-side validation, RemoteEvent OnServerEvent handler | Roblox has no middleware concept |
| `Microservice`, `API gateway` | `MessagingService` (cross-server), `TeleportService` | Real Roblox cross-place primitives |
| `BaseClass`, `AbstractFactory`, `Inheritance hierarchy` | Plain ModuleScript returning table; composition over inheritance | Luau OOP is light; don't over-engineer |
| `Observer pattern` | `BindableEvent`, `RBXScriptSignal`, `Attribute changed` | Engine already provides these |
| `Singleton` | A module that returns a singleton table on require | Implicit in `ModuleScript` semantics |
| `Database` | `DataStoreService`, `MemoryStoreService` | Use the right one; MemoryStore for ephemeral, DataStore for persistent |
| `Frontend / Backend` | `Client / Server` | Roblox replication isn't HTTP |
| `REST endpoint`, `route` | `RemoteEvent` (one-way) / `RemoteFunction` (request-response) | Pick the right kind |
| `Session token`, `JWT` | `Player.UserId`, `Player.SessionId`, server-trusted identity | Don't roll your own auth |
| `Reducer`, `Action`, `Store` (Redux-style) | Plain Luau state table on server, replicated via attributes / remotes | Only adopt Roact/Rodux if the user already uses them |
| `Mock`, `Stub` (in test names) | Plain Luau test doubles; TestEZ / Jest-Roblox idioms | Match repo's test framework |

## Roblox services to know by name

Use the engine service when one exists. Mention it explicitly instead of describing it generically.

- `ReplicatedStorage` — shared assets, modules, remote events visible to client and server
- `ReplicatedFirst` — preloaded before player scripts run (loading screens)
- `ServerScriptService` — server-only scripts (clients can't see contents)
- `ServerStorage` — server-only assets (clients can't replicate)
- `StarterPlayer.StarterPlayerScripts` — replicated to each player's PlayerScripts (client-only)
- `StarterPlayer.StarterCharacterScripts` — replicated to character on spawn
- `StarterGui` — UI cloned to each player's PlayerGui
- `StarterPack` — tools cloned to each player's Backpack
- `Workspace` — runtime instances, terrain, players' characters
- `Lighting` — atmosphere, time-of-day, post-fx
- `SoundService` — global audio routing
- `DataStoreService` — persistent key/value store (use `GetDataStore`, `GetOrderedDataStore`)
- `MemoryStoreService` — short-lived shared state (sorted maps, queues)
- `MessagingService` — cross-server pub/sub
- `TeleportService` — cross-place / cross-server transfer
- `MarketplaceService` — developer products, gamepasses, premium
- `BadgeService` — award badges
- `CollectionService` — tag-based instance grouping
- `HttpService` — outbound HTTP (if enabled in Studio)
- `RunService` — `Heartbeat`, `Stepped`, `RenderStepped`, `IsServer/IsClient/IsStudio`
- `Players` — `PlayerAdded`, `PlayerRemoving`, `LocalPlayer`
- `UserInputService` — client input on the client side
- `ContextActionService` — bind input to actions, mobile-friendly
- `TweenService` — animated property transitions
- `PathfindingService` — NPC navigation
- `ChatService` (legacy) / `TextChatService` (modern) — pick one
- `HapticService` — controller rumble
- `LocalizationService` — i18n

## Instance class names to keep crisp

- `Part`, `MeshPart`, `Model`, `Folder`, `Configuration`, `Attachment`
- `Humanoid`, `HumanoidRootPart`, `Animator`, `Animation`
- `Script` (server), `LocalScript` (client), `ModuleScript` (shared)
- `RemoteEvent`, `RemoteFunction`, `BindableEvent`, `BindableFunction`
- `ScreenGui`, `Frame`, `TextLabel`, `TextButton`, `ImageLabel`, `UIListLayout`, `UIGridLayout`, `UIStroke`
- `ProximityPrompt`, `ClickDetector`, `Beam`, `Trail`, `ParticleEmitter`, `Sound`
- `BoolValue`, `IntValue`, `NumberValue`, `StringValue` (legacy — prefer `Attribute` for new code)

## When in doubt

If a term feels like it belongs in a Java enterprise codebase, it probably doesn't belong in Luau. Stop and ask: *"What does a Roblox developer naturally call this?"*

The smell-test heuristic: if the name only makes sense after explaining 3 layers of abstraction, you're slopping.
