# Story 2.4: Anti-Speedhack Session Verification & Damped Offline Progression

Status: done

## Story

As a Core Player,
I want a server-authoritative offline belief calculation system (`SessionVerificationModule.luau`),
so that my progression is cheat-proof against local time dilation speedhacks and offline earnings are healthy damped.

## Acceptance Criteria

1. **Absolute Server-Authority (AC #1):**
   - **Given** a player joining the game.
   - **When** calculating offline elapsed time $\Delta t = t_{\text{now}} - t_{\text{last\_save}}$.
   - **Then** the server uses absolute unix timestamps (`os.time()`), completely ignoring client-sent time.

2. **Damped Progressive Earnings (AC #2):**
   - **Given** offline elapsed time is computed.
   - **When** calculating offline belief earnings.
   - **Then** offline earnings beyond a 12-hour limit ($T_{\text{cap}} = 43200$s) are progressively damped by 90% ($\gamma = 0.10$):
     $$B_{\text{offline}} = R_p \cdot (t_{\text{effektiv}} + \gamma \cdot t_{\text{overflow}})$$
     where $t_{\text{effektiv}} = \min(\Delta t, 43200)$ and $t_{\text{overflow}} = \max(0, \Delta t - 43200)$.

3. **Crash-Safe Heartbeat (AC #3):**
   - **Given** the game server is ticking.
   - **When** the 60-second heartbeat interval expires.
   - **Then** the server syncs the last active server time `LastSaveTime` inside `PlayerDataStore` for all active players to protect against data loss on crash.

4. **TDD-Verifikation (AC #4):**
   - **Given** the unit tests are executed.
   - **When** running `SessionVerificationModule.spec.lua`.
   - **Then** a 24-hour offline period is verified to generate exactly **55%** of undamped earnings (43200s at 100% rate + 43200s at 10% rate).
   - **And** negative or zero time deltas are successfully rejected (returning 0 earnings).

## Tasks / Subtasks

- [x] **Task 1: Implement SessionVerificationModule (AC: #1, #2)**
  - [x] **Subtask 1.1**: Create `src/server/modules/SessionVerificationModule.luau` implementing the damped offline time calculation formula.
- [x] **Task 2: Integrate into PlayerDataStore & Server (AC: #1, #3)**
  - [x] **Subtask 2.1**: Extend the `PlayerState` structure in `PlayerDataStore.luau` to include `LastSaveTime`.
  - [x] **Subtask 2.2**: Modify `PlacementServer.server.luau` to trigger the offline earnings calculation at `onPlayerAdded`.
  - [x] **Subtask 2.3**: Implement the asychronous 60-second heartbeat save logic in `PlacementServer.server.luau`.
- [x] **Task 3: Implement Unit Tests & Verification (AC: #4)**
  - [x] **Subtask 3.1**: Create `src/server/modules/SessionVerificationModule.spec.lua` covering 10h regular earnings, 24h damped earnings (55% check), and time-travel exploit defenses.
  - [x] **Subtask 3.2**: Run TestEZ suite and verify 100% green execution.
  - [x] **Subtask 3.3**: Verify in Roblox Studio Play Solo.

## Dev Notes

- **Touched Files**:
  - `src/server/modules/SessionVerificationModule.luau` (new)
  - `src/server/modules/SessionVerificationModule.spec.lua` (new)
  - `src/server/modules/PlayerDataStore.luau` (modified)
  - `src/server/PlacementServer.server.luau` (modified)
