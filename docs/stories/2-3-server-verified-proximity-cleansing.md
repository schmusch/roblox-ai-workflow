# Story 2.3: Server-Verified Proximity Cleansing

Status: done

## Story

As a Devoted High Priest,
I want the server to strictly verify my proximity and channeling time during a cleansing ritual,
so that clients cannot teleport-cleanse or trigger instant-cleanses.

## Acceptance Criteria

1. **Start Cleansing Validation (AC #1):**
   - **Given** a catastrophe is active
   - **When** the client fires the `StartCleansing` RemoteEvent with a `crisisId`
   - **Then** the server registers the cleansing start timestamp.
   - **And** the server validates that the player's character is within 15 studs of the catastrophe center.
   - **And** rejects the request if the player is too far or the crisis is invalid.

2. **Complete Cleansing Validation (AC #2):**
   - **When** the client fires the `CompleteCleansing` RemoteEvent with a `crisisId` after the 3-second channel completes
   - **Then** the server validates that at least 3.0 seconds have elapsed since the registered start time.
   - **And** validates that the player's character is still within 15 studs of the catastrophe.
   - **And** only then removes the catastrophe, unblocks the grid, and recalculates the passive income.

3. **Anti-Exploit Security (AC #3):**
   - **Given** a client attempts an instant-cleansing exploit (firing Start and Complete within less than 3 seconds)
   - **Or** a client attempts a teleport-cleansing exploit (firing Complete from > 15 studs away)
   - **Then** the server immediately rejects the removal request and logs a warning.

4. **TDD-Verifikation (AC #4):**
   - **Given** the unit tests are executed
   - **When** running `CrisisModule.spec.lua`
   - **Then** all test cases pass cleanly (verifying happy cleansing path, instant-cleansing blocking, and out-of-range blocking).

## Tasks / Subtasks

- [x] **Task 1: Setup Architecture & Network Remotes (AC: #1, #2)**
  - [x] **Subtask 1.1**: Declare `StartCleansing` and `CompleteCleansing` RemoteEvents in `default.project.json` under `ReplicatedStorage.Events`.
  - [x] **Subtask 1.2**: Implement dynamic instantiation fallback in server scripts to auto-create these remotes if missing.
- [x] **Task 2: Implement Proximity Cleansing Verification (AC: #1, #2, #3)**
  - [x] **Subtask 2.1**: Implement `CrisisModule.HandleStartCleansing(player, crisisId)` calculating AABB/Euclidean distance to the catastrophe center.
  - [x] **Subtask 2.2**: Implement `CrisisModule.HandleCompleteCleansing(player, crisisId)` verifying elapsed time and second proximity boundary.
  - [x] **Subtask 2.3**: Update `CrisisModule.RemoveCrisis` to trigger passive rate recalculations.
- [x] **Task 3: Connect Cleansing Remotes (AC: #1, #2)**
  - [x] **Subtask 3.1**: Create/modify `src/server/CrisisServer.server.luau` to connect network listeners to `StartCleansing` and `CompleteCleansing` remotes and delegate to `CrisisModule`.
- [x] **Task 4: Implement Unit Tests & Verification (AC: #4)**
  - [x] **Subtask 4.1**: Update `src/server/modules/CrisisModule.spec.lua` with failing tests for happy cleansing path, instant-cleansing, and teleporting (RED).
  - [x] **Subtask 4.2**: Format code and verify 100% green tests (GREEN/REFACTOR).
  - [x] **Subtask 4.3**: Visual verification in Roblox Studio and screen capture.

## Dev Notes

- **Network Replication**: Uses `StartCleansing` (RemoteEvent, Client ➔ Server) and `CompleteCleansing` (RemoteEvent, Client ➔ Server).
- **Server Authority**: The entire cleansing workflow, time elapsed, and distance checks are calculated solely on the server.
- **Touched Files**:
  - `default.project.json` (modified)
  - `src/server/modules/CrisisModule.luau` (modified)
  - `src/server/modules/CrisisModule.spec.lua` (modified)
  - `src/server/CrisisServer.server.luau` (modified)

### Project Structure Notes

- Compliant with Rojo project mapping. All scripts strictly typed with `--strict`.

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Debug Log References

- Active Studio Play Solo loop run verified.
- 31 green specs executed and verified through Clone-Bypass runner in Studio edit mode.

### Completion Notes List

- Implemented `HandleStartCleansing` and `HandleCompleteCleansing` utilizing high-precision `os.clock()` timing.
- Added character proximity checks at both the start and end of channeling to prevent teleport-cleanses.
- Linked crisis removal back to player grids and automatically triggered `CitadelBeliefRate` passive income updates.

### File List

- **New Files**:
- **Modified Files**:
  - `default.project.json`
  - `src/server/modules/CrisisModule.luau`
  - `src/server/modules/CrisisModule.spec.lua`
  - `src/server/CrisisServer.server.luau`
