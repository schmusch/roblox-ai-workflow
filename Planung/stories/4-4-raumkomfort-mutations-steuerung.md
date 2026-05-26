# Story 4.4: Raumkomfort- & Mutations-Steuerung

Status: ready-for-dev

## Story

As a Deity Breeder,
I want my chamber's comfort parameter ($\mu$) and spatial room classification to influence fusion success and mutation probability,
So that citadel optimization directly affects the evolution quality of my pantheon.

## Acceptance Criteria

1. **Comfort Threshold Safeguard ($\mu_{\text{min}}$):**
   - **Given** a fusion process
   - **When** the current room comfort $\mu$ is below the threshold $\mu_{\text{min}} = 10$
   - **Then** the fusion is strictly blocked and returns an error.

2. **Room Classifications & Passive Talents:**
   - **Given** maximum comfort ($\mu = 100$) in the chamber
   - **When** the room is classified as `"Barracks"` and a successful mutation roll triggers
   - **Then** the hybrid deity receives the unique passive talent `"Kriegszorn"` (which persistently boosts Attack by $+20\%$).
   - **When** the room is classified as `"Royal"` and a successful mutation roll triggers
   - **Then** the hybrid deity receives the unique passive talent `"GöttlicherSegen"` (which persistently boosts HP by $+20\%$).
   - **And** otherwise (no max comfort, invalid class, or failed roll), no talent is granted and stats are unaffected.

3. **TDD Validation:**
   - **Given** the test environment is running via TestEZ
   - **When** comfort $\mu = 5$ is passed
   - **Then** the fusion is rejected.
   - **When** comfort $\mu = 100$, class is `"Barracks"`, and random roll succeeds
   - **Then** the hybrid config has `Talent = "Kriegszorn"` and `BaseAttack` is boosted by $20\%$ ($1.2 \times$).
   - **When** comfort $\mu = 100$, class is `"Royal"`, and random roll succeeds
   - **Then** the hybrid config has `Talent = "GöttlicherSegen"` and `BaseHP` is boosted by $20\%$ ($1.2 \times$).

## Tasks / Subtasks

- [x] **Task 1: Extend Catalog Schema for Passive Talents** (AC: #2)
  - [x] Add `Talent: string?` field to `DeityConfig` in `src/shared/DeityCatalog.luau`.
- [x] **Task 2: Build Comfort & Mutation Logic** (AC: #1, #2)
  - [x] Add parameters `comfort: number, roomClass: string?` to `FusionInheritanceModule.GenerateHybrid`.
  - [x] Block fusion if `comfort < 10`.
  - [x] Implement mutation triggering at `comfort == 100` (20% chance under math.random, or forced via deterministic mock random).
  - [x] Apply `"Kriegszorn"` (+20% Attack) for `"Barracks"` room class.
  - [x] Apply `"GöttlicherSegen"` (+20% HP) for `"Royal"` room class.
- [x] **Task 3: Unit Testing & Verification** (AC: #3)
  - [x] Create specs under `FusionInheritanceModule.spec.lua` to validate komfort blocking and talent mutation boosts.
  - [x] Run automated test suite via Clone-Bypass runner.

## Dev Notes

- **Touched Files**:
  - `src/shared/DeityCatalog.luau` (MODIFIED)
  - `src/server/modules/FusionInheritanceModule.luau` (MODIFIED)
  - `src/server/modules/FusionInheritanceModule.spec.lua` (MODIFIED)
