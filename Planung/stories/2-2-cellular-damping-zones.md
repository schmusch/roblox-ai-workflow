# Story 2.2: Cellular Damping Zones

Status: done

## Story

As a Citadel Overseer,
I want active voxel crises to block placement and damp local belief production of intersecting monuments by 50%,
so that I am incentivized to immediately deal with the threat.

## Acceptance Criteria

1. **Voxel Damping Activation (AC #1):**
   - **Given** a player has placed monuments that generate passive income
   - **When** a catastrophe spawns and its 3x3 footprint intersects the cells occupied by a monument
   - **Then** the passive Belief generation of that monument is damped by exakt 50%.
   - **And** the updated rate is correctly reflected in the replicated `CitadelBeliefRate` attribute.

2. **Placement Blocking (AC #2):**
   - **Given** a player has an active catastrophe on their grid
   - **When** the player attempts to place a new monument that intersects any of the 3x3 cells occupied by the catastrophe
   - **Then** `GridCollisionModule.verifyPlacement` or `GridModule.CheckPlacementValidity` returns `false`.
   - **And** the server rejects the placement request, preventing Voxel-Stacking over catastrophes.

3. **Multi-Crisis Damping Limits (AC #3):**
   - **Given** multiple catastrophes intersect the same monument
   - **When** income is calculated
   - **Then** the damping is capped at a maximum of 50% (non-cumulative damping) to prevent negative rate yields.

4. **TDD-Verifikation (AC #4):**
   - **Given** the unit tests are executed
   - **When** running the TestEZ suite
   - **Then** all test cases pass cleanly (verifying blocking, 50% damping calculations, and non-cumulative caps).

## Tasks / Subtasks

- [x] **Task 1: Link Crisis Spawner to Player Grid (AC: #2)**
  - [x] **Subtask 1.1**: Update `CrisisModule.SpawnCrisis` to register spawned catastrophes in the player's canonical `grid.Cells` structure as `"crisis_" .. crisisId`.
  - [x] **Subtask 1.2**: Update `CrisisModule.RemoveCrisis` and `CrisisModule.ClearAll` to cleanly free the occupied cells.
- [x] **Task 2: Implement Cellular Intersection & Damping (AC: #1, #3)**
  - [x] **Subtask 2.1**: Implement a state-free AABB intersection checker `GridModule.IsObjectDamped(grid, obj)` in `src/server/modules/GridModule.luau`.
  - [x] **Subtask 2.2**: Update `GridModule.PlaceObject` and `GridModule.Update` to apply the 50% damping modifier for all intersecting monuments.
- [x] **Task 3: Implement Unit Tests & Verification (AC: #4)**
  - [x] **Subtask 3.1**: Create `src/server/modules/GridModule.spec.lua` (if not existing) or add tests validating that catastrophes successfully block placement and damp passive income by exakt 50%.
- [x] **Task 4: Quality Code Review & Pre-Commit Verification**
  - [x] **Subtask 4.1**: Execute automated unit tests and verify 100% success.
  - [x] **Subtask 4.2**: Play solo playtest, audit console outputs, and take screen capture.

## Dev Notes

- **Network Replication**: Updates attributes `CitadelBeliefRate` and `CitadelPlacedObjects` dynamically to keep clients fully synchronized.
- **Server Authority**: Damping calculations and placement blocking are fully server-authoritative.
- **Touched Files**:
  - `src/server/modules/CrisisModule.luau` (modified)
  - `src/server/modules/GridModule.luau` (modified)
  - `src/server/modules/GridModule.spec.luau` (modified/created)

### Project Structure Notes

- Direct integration with existing `GridModule` and `CrisisModule` structures.
- All code strictly typed with `--!strict`.

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Debug Log References

- Synced TestEZ VM require-cache bypass validated with Clone-Bypass.
- 28 specs passed in edit-mode successfully.

### Completion Notes List

- Implemented state-free 2D AABB intersection check `IsObjectDamped`.
- Registered catastrophes in player grid cells dynamically, only occupying empty cells to preserve monument references.
- Corrected unit spec mock player's `SetAttribute` structure to prevent crashes.

### File List

- **New Files**:
- **Modified Files**:
  - `src/server/modules/CrisisModule.luau`
  - `src/server/modules/GridModule.luau`
  - `src/server/modules/GridModule.spec.lua`
  - `src/server/modules/CrisisModule.spec.lua`
