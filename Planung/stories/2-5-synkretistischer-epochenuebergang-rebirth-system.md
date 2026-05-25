# Story 2.5: Synkretistischer Epochenübergang (Rebirth-System)

Status: done

## Story

As an High Priest,
I want to sacrifice my current Citadel to transition into a new technological epoch (prestige-reset),
so that I receive permanent meta-currencies (Sakrale Funken) and unlock deeper automation layers.

## Acceptance Criteria

1. **Epoch Transition Requirements (AC #1):**
   - **Given** I meet the transition criteria.
   - **When** I own at least one hybrid deity (e.g., `sun_temple`) either placed on my grid or in my inventory.
   - **And** I have accumulated at least $10^9$ (1 billion) Belief.
   - **Then** I am allowed to trigger the prestige reset.

2. **Citadel Prestige Reset (AC #2):**
   - **Given** prestige reset is triggered.
   - **When** the transition is processed on the server.
   - **Then** my current Belief is wiped to 0.
   - **And** all personal temple structures are completely removed from my grid and the Workspace.
   - **And** my unplaced inventory items are preserved.

3. **Sublinear Metacurrency Conversion (AC #3):**
   - **Given** a successful prestige reset.
   - **When** calculating the awarded *Sakrale Funken* $P$.
   - **Then** the server uses the sublinear conversion formula:
     $$P = \left\lfloor \sqrt{\frac{B}{C_{\text{epoche}}}} \right\rfloor$$
     where $C_{\text{epoche}} = C_0 \cdot 10^{\text{epoche}}$ ($C_0 = 10^9$).
   - **And** all mathematical calculations (division, square root) on the server run inside a dedicated **Mantissa-Exponent** structure (double mantissa, integer exponent) to prevent double overflows.

4. **TDD-Verifikation (AC #4):**
   - **Given** the unit tests are executed.
   - **When** running `EpochModule.spec.lua` and `MantissaExponentModule` tests.
   - **Then** all specs pass cleanly, ensuring cheat-proof and mathematically sound transitions.

## Tasks / Subtasks

- [x] **Task 1: Implement High-Precision Math Module (AC: #3)**
  - [x] **Subtask 1.1**: Create `src/shared/MantissaExponentModule.luau` implementing scientific BigNumber representation and operators (`add`, `multiply`, `divide`, `sqrt`).
- [x] **Task 2: Implement Epoch prestige reset logic (AC: #1, #2, #3)**
  - [x] **Subtask 2.1**: Implement `GridModule.ClearGrid(player)` to geometrically and physisch clear the Citadel board.
  - [x] **Subtask 2.2**: Create `src/server/modules/EpochModule.luau` to validate transition requirements and process prestige.
- [x] **Task 3: Connect Network Remotes (AC: #2)**
  - [x] **Subtask 3.1**: Create `src/server/EpochServer.server.luau` to listen on `TriggerPrestige` remote event.
- [x] **Task 4: Implement Unit Tests & Verification (AC: #4)**
  - [x] **Subtask 4.1**: Create `src/server/modules/EpochModule.spec.lua` covering requirements validation, grid-clearing, and sublinear BigNumber conversions.
  - [x] **Subtask 4.2**: Modify `EpochModule.luau` to use relative requires for full TestEZ Klon-Bypass compatibility.
  - [x] **Subtask 4.3**: Verify 100% green execution in Roblox Studio.

## Dev Notes

- **Touched Files**:
  - `src/shared/MantissaExponentModule.luau` (new)
  - `src/server/modules/EpochModule.luau` (new)
  - `src/server/modules/EpochModule.spec.lua` (new)
  - `src/server/EpochServer.server.luau` (new)
  - `src/server/modules/GridModule.luau` (modified)
  - `default.project.json` (modified)
