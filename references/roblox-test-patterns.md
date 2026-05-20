# Roblox Test Patterns — TestEZ & Jest-Roblox

Canonical Luau / Roblox testing idioms. Consulted by `roblox-tdd`. Covers framework setup, suite layout, mocking Roblox engine surfaces (Players, RemoteEvent, DataStoreService, RunService), and common test doubles.

## Choosing the framework

**TestEZ** — the long-standing Roblox-community standard. Mature, widely used, BDD-style (`describe` / `it`). Runs in-Studio and via Lune. Smaller / lighter.

**Jest-Roblox** — port of the JavaScript Jest API to Luau. Richer matcher library (`expect(x).toBe(y)`, `.toEqual`, `.toThrow`). Snapshots supported. Slightly heavier; popular with TypeScript-Roblox (`roblox-ts`) users.

Both are valid. Detect what the repo uses; if greenfield, default TestEZ unless the user prefers Jest-Roblox.

## TestEZ setup

```toml
# wally.toml
[dev-dependencies]
TestEZ = "roblox/testez@0.4.1"
```

```jsonc
// default.project.json — add TestEZ to ReplicatedStorage
{
  "name": "myproject",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Packages": { "$path": "Packages" }
    },
    "Tests": { "$path": "tests" }
  }
}
```

```lua
-- tests/run-tests.server.lua (Lune or in-Studio runner)
local TestEZ = require(game.ReplicatedStorage.Packages.TestEZ)
local results = TestEZ.TestBootstrap:run({ script.Parent })
if results.failureCount > 0 then
    error("Test failures: " .. results.failureCount)
end
```

## Jest-Roblox setup

```toml
# wally.toml
[dev-dependencies]
JestGlobals = "jsdotlua/jest-globals@3.x"
Jest = "jsdotlua/jest@3.x"
```

```lua
-- jest.config.luau
return {
    rootDir = script.Parent,
    testMatch = { "**/*.test" },
}
```

## Suite layout

Co-located tests (one `*.spec.lua` next to the module):

```
src/
  shared/
    Wallet/
      Wallet.lua
      Wallet.spec.lua        -- TestEZ
      Wallet.test.lua        -- Jest-Roblox
```

Or central `tests/` folder mirroring `src/`:

```
src/
  shared/Wallet/Wallet.lua
tests/
  shared/Wallet/Wallet.spec.lua
```

Co-located is recommended — closer to the source, harder to drift, easier to delete with the module.

## Skeleton — TestEZ

```lua
-- src/shared/Wallet/Wallet.spec.lua
return function()
    local Wallet = require(script.Parent.Wallet)

    describe("Wallet", function()
        it("starts at zero", function()
            local w = Wallet.new()
            expect(w:GetBalance()).to.equal(0)
        end)

        it("credits add to balance", function()
            local w = Wallet.new()
            w:Credit(50)
            expect(w:GetBalance()).to.equal(50)
        end)

        it("debits reject when insufficient", function()
            local w = Wallet.new()
            local ok = w:Debit(10)
            expect(ok).to.equal(false)
            expect(w:GetBalance()).to.equal(0)
        end)

        it("rejects negative credits", function()
            local w = Wallet.new()
            local ok = pcall(function() w:Credit(-10) end)
            expect(ok).to.equal(false)
        end)
    end)
end
```

## Skeleton — Jest-Roblox

```lua
-- src/shared/Wallet/Wallet.test.lua
local JestGlobals = require(game.ReplicatedStorage.Packages.JestGlobals)
local describe, it, expect = JestGlobals.describe, JestGlobals.it, JestGlobals.expect

local Wallet = require(script.Parent.Wallet)

describe("Wallet", function()
    it("starts at zero", function()
        local w = Wallet.new()
        expect(w:GetBalance()).toBe(0)
    end)

    it("rejects negative credits", function()
        local w = Wallet.new()
        expect(function() w:Credit(-10) end).toThrow()
    end)
end)
```

## Mocking Roblox engine surfaces

### Player mock

```lua
-- tests/helpers/MockPlayer.lua
local MockPlayer = {}
MockPlayer.__index = MockPlayer

function MockPlayer.new(opts)
    local self = setmetatable({}, MockPlayer)
    self.UserId = opts.UserId or 12345
    self.Name = opts.Name or "TestPlayer"
    self._attributes = {}
    return self
end

function MockPlayer:GetAttribute(name) return self._attributes[name] end
function MockPlayer:SetAttribute(name, value) self._attributes[name] = value end
function MockPlayer:WaitForChild(_) return nil end
function MockPlayer:FindFirstChild(_) return nil end

return MockPlayer
```

Use:

```lua
local player = MockPlayer.new({ UserId = 42, Name = "Alice" })
ProgressionLogic.grantXp(player, 100, "test")
expect(player:GetAttribute("Xp")).to.equal(100)
```

### DataStoreService mock

```lua
-- tests/helpers/MockDataStore.lua
local MockStore = {}
MockStore.__index = MockStore

function MockStore.new() return setmetatable({_data = {}}, MockStore) end

function MockStore:GetAsync(key) return self._data[key] end
function MockStore:SetAsync(key, value) self._data[key] = value end
function MockStore:UpdateAsync(key, transform)
    self._data[key] = transform(self._data[key])
    return self._data[key]
end

local MockDataStoreService = {}
local stores = {}
function MockDataStoreService:GetDataStore(name)
    stores[name] = stores[name] or MockStore.new()
    return stores[name]
end

return MockDataStoreService
```

Inject the mock into the module under test rather than reaching for the real `game:GetService("DataStoreService")`:

```lua
-- Wallet.lua designed for testability
local Wallet = {}
function Wallet.new(opts)
    opts = opts or {}
    local self = setmetatable({}, {__index = Wallet})
    self._datastore = opts.datastore or game:GetService("DataStoreService"):GetDataStore("Wallet")
    return self
end
```

```lua
-- in the test
local mockDs = MockDataStoreService:GetDataStore("Wallet")
local wallet = Wallet.new({datastore = mockDs})
wallet:Save(player, 500)
expect(mockDs:GetAsync(tostring(player.UserId))).to.equal(500)
```

### RemoteEvent mock

```lua
-- tests/helpers/MockRemoteEvent.lua
local MockRemoteEvent = {}
MockRemoteEvent.__index = MockRemoteEvent

function MockRemoteEvent.new()
    local self = setmetatable({}, MockRemoteEvent)
    self._serverHandlers = {}
    self._fired = {}  -- captures server→client fires
    return self
end

function MockRemoteEvent:FireClient(player, ...)
    table.insert(self._fired, { player = player, args = {...} })
end

function MockRemoteEvent:FireAllClients(...)
    table.insert(self._fired, { all = true, args = {...} })
end

MockRemoteEvent.OnServerEvent = {
    Connect = function(self, handler)
        table.insert(self._serverHandlers or {}, handler)
    end,
}

-- test-only: simulate a client firing the remote
function MockRemoteEvent:_simulateClientFire(player, ...)
    for _, h in ipairs(self._serverHandlers) do h(player, ...) end
end

return MockRemoteEvent
```

Use to test that server validation rejects bad input:

```lua
local remote = MockRemoteEvent.new()
WalletService:BindPurchaseRemote(remote)
remote:_simulateClientFire(player, "not-a-number")
expect(#remote._fired).to.equal(0)  -- server didn't push any state change
```

### RunService mock

```lua
local MockRunService = {
    IsServer = function() return true end,
    IsClient = function() return false end,
    IsStudio = function() return true end,
}
```

Inject into modules that branch on `RunService:IsServer()`.

## Test doubles patterns

- **Stub** — returns canned values; no behavior. Use for read-only deps.
- **Spy** — wraps a real function and records calls. Use to assert "X was called with Y".
- **Mock** — full replacement with programmable behavior. Use for engine services.
- **Fake** — in-memory implementation of a real interface. Use for DataStore (the mock above is a fake).

For Roblox, fakes are the most useful pattern — DataStoreService, MemoryStoreService, and RemoteEvents all have clear contracts to fake.

## Async testing

For functions that yield (`task.wait`, `RemoteFunction:InvokeServer`):

```lua
it("yields then returns", function()
    local result
    task.spawn(function()
        result = SomeAsyncFn()
    end)
    task.wait(0.1)
    expect(result).to.equal("expected value")
end)
```

In Lune, async behavior is approximated; in-Studio runners the real engine clock applies.

## Adversarial test set (mandatory for remote handlers)

For any function bound to `OnServerEvent`:

```lua
describe("BuyItem remote — adversarial", function()
    it("rejects nil", function()
        Service:HandleBuy(player, nil)
        expect(player:GetAttribute("Currency")).to.equal(initialBalance)
    end)
    it("rejects wrong type", function()
        Service:HandleBuy(player, {weird = "table"})
        expect(player:GetAttribute("Currency")).to.equal(initialBalance)
    end)
    it("rejects unknown item id", function()
        Service:HandleBuy(player, "definitely-not-a-real-sku")
        expect(player:GetAttribute("Currency")).to.equal(initialBalance)
    end)
    it("rate-limits rapid fire", function()
        for _ = 1, 100 do Service:HandleBuy(player, "small-potion") end
        local granted = countInInventory(player, "small-potion")
        expect(granted < 100).to.equal(true)
    end)
end)
```

These are required by `roblox-ultraqa` and `roblox-security-review`.

## Common pitfalls

- **Testing engine objects directly** — slow, non-deterministic. Mock or fake.
- **Tests that touch `game.Players` etc. globally** — order-dependent, leak state across tests. Pass deps in.
- **Snapshots of large tables** — drift over time; prefer focused asserts.
- **Tests that depend on real timing** (e.g., `wait(5)` then assert) — flaky; use fakes for time-dependent code.
- **Skipping the adversarial set** — passing tests don't prove security.

## Running tests

- **Lune** (`lune run tests/run-tests.lua`) — fastest, headless, no Studio needed for pure-logic tests.
- **In-Studio** — runs in real engine; needed for tests that touch actual instances.
- **CI** — run via Lune in a GitHub Actions job; see `references/roblox-build-toolchain.md` for pipeline patterns.
