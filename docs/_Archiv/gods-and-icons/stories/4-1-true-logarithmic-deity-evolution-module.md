# Story 4.1: True Logarithmic Deity Evolution Module

Status: done

## Story

As an Alchemist of Götter,
I want the fusion of deities to follow a true logarithmic mathematical scale,
So that the orbital radius grows in a controlled, non-disruptive sublinear manner.

## Acceptance Criteria

1. **Logarithmic Scaling & Damping:**
   - **Given** two deities are fused at Level L
   - **When** the new properties are calculated
   - **Then** the orbital radius scales sublinearly as:
     $$R_L = R_0 \cdot (1 + \ln(L + 1))$$
   - **And** the rotation velocity scales down mathematically as:
     $$\omega_L = \frac{\omega_0}{\sqrt{L + 1}}$$
   - **And** invalid level inputs (e.g., $< 1$) are safely clamped to Level 1.

2. **TDD Validation:**
   - **Given** the test environment is running via TestEZ
   - **When** Level 10 is tested
   - **Then** the radius ratio $R_{10} / R_0$ is exactly within the range of $3.39 \pm 0.01$, preventing visual layout overflow.
   - **And** the Level 10 rotation velocity is correctly throttled by $\omega_{10} = \omega_0 / \sqrt{11} \approx 0.3015 \cdot \omega_0$.
   - **And** negative levels are successfully clamped to Level 1 values ($R_1 \approx 1.693 \cdot R_0, \omega_1 \approx 0.707 \cdot \omega_0$).

3. **Client-Side Glowing Orbits:**
   - **Given** placed deities in the workspace Ordner `"PlacedObjects"`
   - **When** the client render engine executes
   - **Then** it dynamically renders a beautiful, rotating neon circle (16 glowing segments) around each placed monument.
   - **And** the neon color corresponds to the deity's faction: warm orange-gold for Alte Götter, cyan-blue for Neue Götter.
   - **And** the radius and rotation velocity dynamically scale in real-time if the `"Level"` attribute of the placed monument changes.

## Tasks / Subtasks

- [x] **Task 1: Build Mathematical Scaling Module** (AC: #1)
  - [x] Subtask 1.1: Create `src/shared/DeityEvolutionModule.luau` to handle all logarithmic evolution calculations.
  - [x] Subtask 1.2: Implement `CalculateRadius` with `math.max(1, level)` and natural logarithm `math.log(l + 1)`.
  - [x] Subtask 1.3: Implement `CalculateOmega` with `math.max(1, level)` and square root `math.sqrt(l + 1)`.
- [x] **Task 2: Unit Testing with TestEZ** (AC: #2)
  - [x] Subtask 2.1: Create `src/server/modules/DeityEvolutionModule.spec.lua` inside server modules.
  - [x] Subtask 2.2: Add specs for Level 1, Level 10 (asserting the ratio within a 0.01 tolerance), Level 10 rotation, and invalid levels.
  - [x] Subtask 2.3: Verify all tests run and pass completely green in Studio (42/42 tests passed).
- [x] **Task 3: Client-Side Real-Time Visualization** (AC: #3)
  - [x] Subtask 3.1: Create `src/client/DeityOrbitVisualizer.client.luau` to scan and render orbits.
  - [x] Subtask 3.2: Implement prozedural halo generation (16 glowing Neon segments).
  - [x] Subtask 3.3: Set up AttributeChangedSignal listener for `"Level"` and render loop with RenderStepped.
  - [x] Subtask 3.4: Modify `src/server/modules/GridModule.luau` to assign default level attribute `"Level" = 1` on placed object parts.

## Dev Notes

- **Network Replication**: Fully server-authoritative level attributes drive client visual renders.
- **Formulas**:
  - `math.log(x)` in Luau computes the natural logarithm ($\ln$), which meets the requirements perfectly. At Level 10, the calculated radius ratio is $1 + \ln(11) \approx 3.39789$, which is exactly within the requested $3.39 \cdot R_0$ limit (with $<0.01$ absolute error).
- **Touched Files**:
  - `src/shared/DeityEvolutionModule.luau` (NEW)
  - `src/server/modules/DeityEvolutionModule.spec.lua` (NEW)
  - `src/client/DeityOrbitVisualizer.client.luau` (NEW)
  - `src/server/modules/GridModule.luau` (MODIFIED)

## Dev Agent Record

### Agent Model Used

Gemini Auto-Gemini-3

### Completion Notes List

- Designed and built the sublinear evolution scaling formulas in `src/shared/DeityEvolutionModule.luau`.
- Added comprehensive unit tests in `src/server/modules/DeityEvolutionModule.spec.lua` to guarantee correct logarithmic bounds and math precision.
- Built a high-end visualizer in `src/client/DeityOrbitVisualizer.client.luau` generating beautiful neon halos (colour-coded by faction) that respond dynamically to level and rotate in real-time.
- Verified all 42 tests are passing.
