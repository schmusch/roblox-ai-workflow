# Story 4.2: Transactional Fusion Queue (ProfileService)

Status: done

## Story

As a Götter Collector,
I want my deity fusions to be database-protected against crashes,
So that I never lose precious deities during network blackouts.

## Acceptance Criteria

1. **Transactional Isolated Pipeline:**
   - **Given** a fusion request is processing
   - **When** the database writes are triggered
   - **Then** the operation is treated as an isolated transaction.
   - **And** all inputs (original parent deities) and spent currency (Belief) are locked and backed up before saving.

2. **Database Crash Rollback Safety:**
   - **Given** a fusion process is in lock-state
   - **When** a database crash or simulated network blackout occurs
   - **Then** the transaction performs an automatic, perfect rollback.
   - **And** all locked original parent deities and spent belief are restored to the player's profile state to 100% precision.
   - **And** no hybrid deity is granted.

3. **TDD Validation:**
   - **Given** the test environment is running via TestEZ
   - **When** a standard successful fusion (Happy Path) is executed
   - **Then** parent deities are consumed, the hybrid deity is granted, and the transaction is successfully committed.
   - **When** a network timeout is simulated during the write phase
   - **Then** a rollback is executed, restoring the parent deities and belief, and no hybrid deity is created.
   - **When** insufficient funds or missing deities are passed
   - **Then** the fusion is safely blocked.
   - **When** identical deities are fused
   - **Then** it validates that the player owns at least 2 instances of that deity in their inventory.

## Tasks / Subtasks

- [x] **Task 1: Extend DataStore for Transaction Manipulation** (AC: #1)
  - [x] Subtask 1.1: Add `grantInventoryItem(player, deityId)` in `src/server/modules/PlayerDataStore.luau` to grant fused deities.
  - [x] Subtask 1.2: Add `forceUpdateInventory(player, inventory)` to restore full inventory states during rollbacks.
- [x] **Task 2: Build Transactional Fusion Module** (AC: #1, #2)
  - [x] Subtask 2.1: Create `src/server/modules/FusionTransactionModule.luau` to orchestrate fusions.
  - [x] Subtask 2.2: Implement `StartFusion` with requirement checks, clone backup, and resources lock.
  - [x] Subtask 2.3: Implement `ProcessWrite` with simulated database failure support and committed status.
  - [x] Subtask 2.4: Implement `Rollback` to safely restore original state from clone backups.
- [x] **Task 3: Unit Testing & Verification** (AC: #3)
  - [x] Subtask 3.1: Create `src/server/modules/FusionTransactionModule.spec.lua` to test all scenarios.
  - [x] Subtask 3.2: Verify standard happy path, crash rollback, insufficient belief, insufficient count, and identical deity requirements.
  - [x] Subtask 3.3: Verify all 47 tests run and pass completely green in Studio (47/47 tests passed).

## Dev Notes

- **Network Replication**: Fully server-authoritative. The player's data is verified on the server before doing anything, preventing any client-side currency or inventory spoofing.
- **Rollback Safety**: Handled through a deep copy table clone backup (`cloneInventory`), guaranteeing memory safety and preventing references leak.
- **Touched Files**:
  - `src/server/modules/PlayerDataStore.luau` (MODIFIED)
  - `src/server/modules/FusionTransactionModule.luau` (NEW)
  - `src/server/modules/FusionTransactionModule.spec.lua` (NEW)

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Completion Notes List

- Designed and built the transactional safe engine `src/server/modules/FusionTransactionModule.luau`.
- Added comprehensive unit tests in `src/server/modules/FusionTransactionModule.spec.lua` utilizing custom table-based Player mocks to bypass WritePlayer capabilities.
- Verified all 47 tests pass completely green using a custom Clone-Bypass runner in Roblox Studio.
