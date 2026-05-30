# Story 2.1: Asynchronous Catastrophe Spawner

Status: done

## Story

As a Citadel Overseer,
I want a server-side random catastrophe dispatcher running every 120 seconds,
so that the Citadel plate feels alive, dynamic, and presents active voxel-crises.

## Acceptance Criteria

1. **Catastrophe Dispatcher Loop (AC #1):**
   - **Given** the game server is active and ticking
   - **When** the periodic spawner is running
   - **Then** every 120 seconds, the server selects a random 3x3 voxel area on a player's grid.
   - **And** it spawns a physical Neon-Purple Metaphysical Rift (indicator part) centered on that 3x3 area.
   - **And** the spawner interval is adjustable (e.g., shorter in Studio for rapid testing).

2. **Network Notification (AC #2):**
   - **Given** a new catastrophe is spawned by the server
   - **When** the spawner finishes instantiation
   - **Then** the server fires the `CatastropheRemote` RemoteEvent to the player.
   - **And** the client receives the event containing the 3x3 grid coordinates of the catastrophe.

3. **Geometrische Voxel-Zuordnung (AC #3):**
   - **Given** a 10x10 voxel grid
   - **When** the 3x3 catastrophe area is calculated
   - **Then** the starting origin `(cellX, cellZ)` must be strictly between `1` and `8` to prevent boundaries overflow.
   - **And** the physical parts are correctly aligned to the shared grid system coordinates.

4. **TDD-Verifikation (AC #4):**
   - **Given** the unit tests are executed
   - **When** running the `CrisisModule.spec.lua`
   - **Then** all test cases pass cleanly (verifying random bounds, state registration, and clearing).

## Tasks / Subtasks

- [x] **Task 1: Setup Architecture & Network Remotes (AC: #2)**
  - [x] **Subtask 1.1**: Declare the `CatastropheRemote` RemoteEvent in `default.project.json` under `ReplicatedStorage.Events`.
  - [x] **Subtask 1.2**: Implement dynamic instantiation fallback in server scripts to auto-create `CatastropheRemote` if it's missing in runtime.
- [x] **Task 2: Implement Crisis Core Module (AC: #3, #4)**
  - [x] **Subtask 2.1**: Create a failing TestEZ spec `src/server/modules/CrisisModule.spec.lua` to validate spawner math and bounds (RED).
  - [x] **Subtask 2.2**: Implement `src/server/modules/CrisisModule.luau` to manage the active crisis state, calculate 3x3 grid coordinates securely, and pass all TestEZ specs (GREEN).
- [x] **Task 3: Implement Crisis Server Dispatcher (AC: #1, #2)**
  - [x] **Subtask 3.1**: Create `src/server/CrisisServer.server.luau` running a periodic task loop that triggers `CrisisModule.SpawnCrisis` for active players.
- [x] **Task 4: Complete Pre-Commit Verification & Code Review**
  - [x] **Subtask 4.1**: Execute automated unit tests and verify 100% success.
  - [x] **Subtask 4.2**: Trigger manual Play Solo playtest and perform visual verification with screen captures.

## Dev Notes

- **Network Replication**: Uses `ReplicatedStorage.Events.CatastropheRemote` (RemoteEvent, Server ➔ Client).
- **Server Authority**: The server alone decides when, where, and why a crisis is spawned. Clients are only notified of the coordinate outcomes.
- **Touched Files**:
  - `default.project.json` (modified)
  - `src/server/modules/CrisisModule.luau` (new)
  - `src/server/modules/CrisisModule.spec.lua` (new)
  - `src/server/CrisisServer.server.luau` (new)
- **Wally & External Packages**: Reuses `TestEZ` from `ServerScriptService.ServerPackages`.

### Project Structure Notes

- Compliant with Rojo project mapping. All scripts strictly typed with `--!strict`.
- No enterprise slop naming. Pure domain-focused `CrisisModule`.

### Project Context Rules

- Zero-allocation guidelines for math-only sections.
- PascalCase for modules and components.

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Debug Log References

- Active Studio play solo console logs audited in real-time.
- Visual check via screen capture.

### Completion Notes List

- Spawned neon purple catastrophes hover perfectly at Y=0.25 to prevent rendering overlapping Z-fighting glitches.
- Adjustable spawner successfully runs at 15s in Studio and 120s in production.
- TestEZ unit tests validated parallel spawning, stochastische boundaries (1-8 bounds), and ClearAll logic.

### File List

- **New Files**:
  - `src/server/modules/CrisisModule.luau`
  - `src/server/modules/CrisisModule.spec.lua`
  - `src/server/CrisisServer.server.luau`
- **Modified Files**:
  - `default.project.json`
