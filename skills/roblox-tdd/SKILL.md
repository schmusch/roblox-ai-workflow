---
name: roblox-tdd
description: Use to drive Roblox / Luau implementation via red-green-refactor cycles with TestEZ or Jest-Roblox. Use when the user says "TDD", "test-driven", "write the test first", "test it properly", before implementing any non-trivial Luau module, or any time disciplined coverage is needed before code lands.
domain: process
audience: creator
artifact-type: skill
---

# Roblox TDD

Test-driven development adapted to Luau and the Roblox runtime. Generic TDD assumes a hosted process, dependency injection, and a fast test runner. Roblox tests must additionally handle:

- Mocking engine services (`Players`, `DataStoreService`, `RemoteEvent`, `RunService`).
- The split between pure-logic ModuleScripts (easy to test) and server `Script` / `LocalScript` (harder — usually refactored into modules to be testable).
- TestEZ or Jest-Roblox as the typical runner; both work in headless Lune or in-Studio.

This skill is for the red-green-refactor discipline. Long-form Roblox test idioms (mocks for `DataStoreService`, fake `Player` factory, `RemoteEvent` doubles, suite layout) live in `references/roblox-test-patterns.md`.

## When to use

- Implementing any non-trivial Luau module where correctness matters more than speed of first commit.
- Before writing a `ProgressionService`, `WalletService`, `TradeService`, or any module with non-obvious correctness.
- After a bug is reported — write the failing test first, then fix, to prevent regression.
- When the user says "TDD", "test first", "write the test first", "red-green-refactor".

## When not to use

- Single-line bugfix where the fix is obvious from the trace and no regression test is realistic.
- Pure visual / UI tweak with no testable logic.
- Spike / prototype where the code will be thrown away.
- Tightly-coupled engine code (e.g. `RenderStepped` lerp) that is dominated by runtime behavior — use `roblox-ultraqa` runtime verification instead.

## What this skill produces

A coherent red → green → refactor cycle for the change:
- A **failing test** that asserts the desired behavior.
- The **minimum implementation** that turns the test green.
- A **refactor pass** that improves the code while keeping all tests green.

Plus the test file lives at a predictable location and is wired into the existing test runner.

## Method

### 1. Confirm the testable shape

If the work is server `Script` / client `LocalScript` glue, **refactor first** to extract pure logic into a `ModuleScript`. The `Script` becomes a thin wiring layer; the `ModuleScript` is the testable unit.

Example: instead of putting XP grant logic inside `ProgressionService.server.lua`, put it in `ProgressionLogic` (a ModuleScript) and have the server Script call it. Now `ProgressionLogic` is testable.

### 2. Identify the test framework

Detect what the repo uses:
- `TestEZ` (look for `testez.toml`, `*.spec.lua` files, `it("...")` calls).
- `Jest-Roblox` (look for `jest.config.luau`, `*.test.lua`).
- Custom runner (look for `tests/` folder and any runner script).
- Nothing → set up TestEZ (default Roblox choice) unless the user prefers Jest-Roblox.

See `references/roblox-test-patterns.md` for the layout each framework expects.

### 3. Write the failing test (RED)

State the behavior the new code must have, in test form, before writing any implementation. The test must:
- Have a clear `describe` / `it` name that reads like a sentence.
- Assert a single behavior (not a god-test).
- Fail for the right reason — "expected X, got nil" because the function doesn't exist yet, or "expected 100, got 0" because the logic is missing.

Run the test. Confirm it fails. **A green test on the first run is a smell** — either the test isn't asserting what you think, or the behavior already exists (in which case rethink the task).

### 4. Write the minimum implementation (GREEN)

Write the smallest code that makes the test pass. Resist the urge to also handle edge cases not yet tested — write the test for those first. Run the test. Confirm it passes.

### 5. Refactor (REFACTOR)

With a green test as safety net, clean the code:
- Rename for clarity.
- Extract repeated patterns.
- Apply `roblox-anti-slop` if any enterprise jargon crept in.
- Improve types (typed Luau).

Re-run all tests after each refactor step. Stop refactoring when the code reads naturally to a Roblox developer.

### 6. Repeat for each behavior

Each new behavior gets its own RED → GREEN → REFACTOR cycle. Do not write multiple tests at once and then implement against all of them — the safety net only works if each cycle is small and isolated.

### 7. Cover the adversarial path

For any function that takes external input (especially from a remote handler), add a failing test for:
- Wrong type input → returns / rejects, no crash.
- Out-of-range input → rejects, no state change.
- Missing required parameter → rejects, no crash.
- Unauthorized actor → rejects.

Then make it green. These tests are non-negotiable for any code surface a client can reach.

### 8. Run the full suite before claiming done

After the last refactor, run the **entire** test suite (not just the changed file) to confirm no regressions. If the suite is large and slow, at minimum run the directory the change lives in plus any direct dependencies.

## Mocking Roblox engine surfaces

Pure logic modules don't need mocks. When a module touches engine services, see `references/roblox-test-patterns.md` for canonical mock patterns:

- **Player mock** — table with `UserId`, `Name`, `GetAttribute`, `SetAttribute`, `:WaitForChild` stubs.
- **DataStoreService mock** — in-memory table acting as the key/value store with `GetAsync` / `UpdateAsync` / `SetAsync` matching the real API surface.
- **RemoteEvent / RemoteFunction mock** — emits events to test-controlled handlers, captures fired payloads for assertion.
- **RunService mock** — overrides `IsServer` / `IsClient` / `IsStudio` for the test environment.

**Inject** these mocks into the module under test (constructor parameter, module-level `setDeps()`, or test-local override). Don't reach into the global `game` from inside the test.

## Anti-pattern checks

- ❌ Writing the implementation first and then "adding tests" — not TDD; defeats the discipline.
- ❌ Writing one giant test that asserts ten things — fails confusingly, hides the failing behavior.
- ❌ Skipping the RED step — if the test passes immediately, it's not asserting what you think.
- ❌ Testing engine services directly (`game.Players`) — non-determinism, slow, brittle. Mock them.
- ❌ Mocking pure logic — pointless; just call the real function.
- ❌ Inflating coverage with trivial getter/setter tests — adds maintenance, catches no bugs.
- ❌ Refactoring without re-running tests — defeats the safety net.

## Roblox-specific framing

Generic TDD assumes hosted code with a fast unit test runner. Roblox TDD additionally requires:
- **Pure-logic extraction** as a precondition — `Script` and `LocalScript` are not directly testable; their logic must live in `ModuleScript`s.
- **Engine-service mocks** for any module that touches `Players`, `DataStoreService`, `RemoteEvent`, etc.
- **Runtime verification** *in addition to* unit tests for behavior depending on replication — see `roblox-ultraqa`.

A passing TestEZ suite is necessary but not sufficient for Roblox completeness. It proves the pure logic is correct; runtime behavior still needs `roblox-ultraqa` verification.

## Handoff

- TDD cycle complete and suite green → continue in `roblox-forge` for any remaining wiring.
- Runtime-dependent behavior still untested → run `roblox-ultraqa` to capture the runtime evidence.
- Code-shape review needed before merge → run `roblox-code-review`.
- Security-touching surface (remotes, persistence, marketplace) → also run `roblox-security-review`.
