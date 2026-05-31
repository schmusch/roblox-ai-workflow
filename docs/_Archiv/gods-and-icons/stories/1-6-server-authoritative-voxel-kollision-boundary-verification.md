# Story 1.6: Server-Authoritative Voxel-Kollision & Boundary Verification

Status: done

## Story

As a Citadelle Architect,
I want a server-side voxel-collision and boundary verification system (`GridCollisionModule.luau`),
so that malicious clients cannot stack meshes (voxel-stacking) or place deities outside the active Citadel grid coordinates.

## Acceptance Criteria

1. **BDD Geometry Check:**
   - **Given** a placement request to the server
   - **When** `GridCollisionModule.verifyPlacement` is executed
   - **Then** if the monument is rotated (90 or 270 degrees), its width and length are geometrically transformed ($W' \leftarrow D, D' \leftarrow W$).
   - **And** it checks that all target voxel coordinates ($F \subseteq \text{GridBounds}$) are inside the citadel grid boundaries ($10 \times 10$).
   - **And** it checks that all target cells in the grid are completely empty ($\text{Grid}[c] = \emptyset$).
   - **And** only then it returns `true` and the list of cells to occupy.

2. **TDD Validation:**
   - **Given** the test environment is running via TestEZ
   - **When** an out-of-bounds placement is simulated (e.g. $(10, 0, 10)$)
   - **Then** the validation is rejected.
   - **When** an overlapping placement is simulated (two monuments on the same cell)
   - **Then** the validation is rejected.

## Tasks / Subtasks

- [x] **Task 1: Setup Voxel-Collision Module** (AC: #1)
  - [x] Subtask 1.1: Create `src/server/modules/GridCollisionModule.luau` to handle all geometric checks on the server.
  - [x] Subtask 1.2: Implement `getRotatedDimensions(footprint: Vector3, rotation: number): (number, number, number)` (swap Width and Length at 90/270 degrees).
  - [x] Subtask 1.3: Implement `verifyPlacement(occupiedCells: { [number]: { [number]: string? } }, footprint: Vector3, cellX: number, cellZ: number, rotation: number): (boolean, { {number} }?).
- [x] **Task 2: Integrate with GridModule** (AC: #1)
  - [x] Subtask 2.1: Require `GridCollisionModule` in `src/server/modules/GridModule.luau`.
  - [x] Subtask 2.2: Refactor `GridModule.CheckPlacementValidity` to delegate to `GridCollisionModule.verifyPlacement` for server-side authority.
- [x] **Task 3: Unit Testing and Verification** (AC: #2)
  - [x] Subtask 3.1: Create `src/server/modules/GridCollisionModule.spec.lua` to test out-of-bounds and overlapping placements.
  - [x] Subtask 3.2: Run the TestEZ suite inside Roblox Studio and verify a clean, 100% green run.

## Dev Notes

- **Network Replication**: No new Remotes are needed. We are strengthening the server-side validator for the existing `PlacementRemote`.
- **Server Authority**: Strictest geometric checks on the server. If `verifyPlacement` returns `false`, `GridModule` immediately rejects the placement, preventing voxel stacking exploits.
- **Touched Files**:
  - `src/server/modules/GridCollisionModule.luau` (NEW)
  - `src/server/modules/GridCollisionModule.spec.lua` (NEW)
  - `src/server/modules/GridModule.luau` (MODIFIED)

### Project Structure Notes

- ModuleScripts must use PascalCase and strict typing (`--!strict`).
- We preserve `GridMath.luau` for client-side predictions, while `GridCollisionModule.luau` represents the authoritative server-side gate.

### References

- [Source: Planung/02_Spezifikationen/02.2_Server-Authoritative-Tempel-Wirtschaft-Spezifikation.md#Section-2]

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Debug Log References

- Verified isolated planning errors by cleaning legacy Roblox `ServerScriptService.Modules` folder.
- Executed isolated TestEZ test suite under `ServerScriptService.Server` using custom Clone-Bypass script to avoid require cache.

### Completion Notes List

- Designed and built the server-authoritative geometric validator `GridCollisionModule.luau` in Luau.
- Added comprehensive unit test coverage including boundaries, overlaps, and rotated coordinate transformations.
- 21/21 tests green and verified in active Roblox Studio edit environment.

### File List

- **New Files**:
  - `src/server/modules/GridCollisionModule.luau`
- **Modified Files**:
  - `src/server/modules/GridModule.luau`
  - `src/server/modules/GridCollisionModule.spec.lua`
