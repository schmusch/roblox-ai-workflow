# Story 4.3: Sakrales Fusions- & Mendelsches Vererbungssystem

Status: ready-for-dev

## Story

As a Götter Breeder,
I want a fusion chamber that strictly adheres to Mendelian inheritance laws and room stimulation formulas,
So that I can strategically breed tactical hybrid deities without creating game-breaking stat inflation.

## Acceptance Criteria

1. **Inheritance & Damping Rules:**
   - **Given** two parent deities in the fusion transactional chamber
   - **When** fusion is initiated
   - **Then** only base statistics are inherited (base HP, base attack, base speed), ignoring any acquired bonus stats.
   - **And** the resulting hybrid deity receives a persistent `IsStabilized = true` flag and cannot be used as a parent for further fusions (blocking infinite stat rolls).

2. **Stimulation Parameter Scaling ($S$):**
   - **Given** a fusion process
   - **When** the room stimulation parameter $S \in [0, 100]$ is evaluated
   - **Then** the inheritance chance of the superior base stat ($P_{\text{besser}}$) scales dynamically as:
     $$P_{\text{besser}} = \frac{1.0 + 0.01 \cdot S}{2.0 + 0.01 \cdot S}$$
   - **And** the chance of inheriting the better stat is:
     - $50\%$ when $S = 0$
     - $60\%$ when $S = 50$
     - $100\%$ when $S = 100$ (completely guaranteed!)

3. **Unfusing Safety Valve:**
   - **Given** a stabilized hybrid deity
   - **When** the player requests to "unfuse" it
   - **Then** the player must pay a standardized In-Game belief fee.
   - **And** both original parent deities are fully recovered and returned to the player's inventory.
   - **And** the hybrid deity and the original fusion catalysts are completely destroyed.

4. **TDD Validation:**
   - **Given** the test environment is running via TestEZ
   - **When** fusions are simulated under $S=0, 50, 100$
   - **Then** the stat distribution follows the Mendelian stimulation curve exactly (validated with statistical check intervals).
   - **And** any attempt to use a stabilized deity (`IsStabilized = true`) as a fusion parent is strictly blocked.
   - **And** unfusing returns both original parent deities and deducts the belief fee correctly.

## Tasks / Subtasks

- [ ] **Task 1: Extend Catalog & Deity Schema** (AC: #1)
  - [ ] Subtask 1.1: Extend `DeityConfig` in `src/shared/DeityCatalog.luau` to include base stats: `BaseHP`, `BaseAttack`, `BaseSpeed`.
  - [ ] Subtask 1.2: Add stats to standard profiles:
    - Forest Spirit: HP 100, Attack 10, Speed 8
    - Sun Temple: HP 250, Attack 25, Speed 4
    - Water Shrine: HP 80, Attack 15, Speed 12
    - Media Nexus: HP 120, Attack 18, Speed 9
- [ ] **Task 2: Build Inheritance Engine** (AC: #1, #2)
  - [ ] Subtask 2.1: Create `src/server/modules/FusionInheritanceModule.luau`.
  - [ ] Subtask 2.2: Implement `CalculateSuperiorInheritanceChance(stimulation: number): number`.
  - [ ] Subtask 2.3: Implement `GenerateHybridStats(parentA: DeityConfig, parentB: DeityConfig, stimulation: number): (DeityConfig, boolean)`.
  - [ ] Subtask 2.4: Ensure that hybrid stats receive `IsStabilized = true` flag and cannot be used as parents.
- [ ] **Task 3: Implement Unfusing System** (AC: #3)
  - [ ] Subtask 3.1: Add `UnfuseHybrid(player: Player, hybridId: string, unfuseFee: number): (boolean, string?)` in `FusionTransactionModule.luau`.
  - [ ] Subtask 3.2: Verify that hybrid is consumed, original parents are restored to player inventory, and fee is deducted.
- [ ] **Task 4: Unit Testing & Verification** (AC: #4)
  - [ ] Subtask 4.1: Create `src/server/modules/FusionInheritanceModule.spec.lua`.
  - [ ] Subtask 4.2: Verify inheritance chances for $S=0$, $S=50$, $S=100$.
  - [ ] Subtask 4.3: Verify stabilized blocker prevents hybrid fusions.
  - [ ] Subtask 4.4: Verify unfusing flow.
  - [ ] Subtask 4.5: Run automated test suite via Clone-Bypass runner.

## Dev Notes

- **Network Replication**: Fully server-authoritative. The player's data is verified on the server before doing anything, preventing any client-side currency or inventory spoofing.
- **Touched Files**:
  - `src/shared/DeityCatalog.luau` (MODIFIED)
  - `src/server/modules/FusionInheritanceModule.luau` (NEW)
  - `src/server/modules/FusionInheritanceModule.spec.lua` (NEW)
  - `src/server/modules/FusionTransactionModule.luau` (MODIFIED)

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Completion Notes List

### File List

- **New Files**:
- **Modified Files**:
