# Gods & Icons - Audited Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Gods & Icons, decomposing the requirements from the GDD, Götter-Blueprint, and Technical Architecture specifications into implementable stories.

**AI Development & MCP Strategy:**
Throughout all Epics, the development process MUST actively utilize the configured Roblox Studio MCP server (`mcp__Roblox_Studio__*`). This provides full engine and workspace control.
- **Verification Rule**: After every visual change, UI update, or asset insertion, run visual evidence collection (e.g. `screen_capture` or manual playtests).
- **TDD Requirement**: Failing TestEZ spec scripts must be written before any production Luau implementation.

---

## Requirements Inventory

### Functional Requirements

*   **FR 1: Persistent Voxel Grid Layout:**
    Save and load players' brutalist Citadels in standard voxel configurations, ensuring absolute server-side authority over spatial layout.
*   **FR 2: Cellular Snapping & Placement Preview:**
    Allow players to preview monument placement with 90-degree rotations, visual bounding-box prediction (Neon Lime/Crimson), and grid snapping.
*   **FR 3: Tick-Based Passive Economy:**
    Akkumulate passive resource generation (`Belief`) delta-time-driven every 1.0 second on the server and replicate to the client.
*   **FR 4: Deity Selection & Resource Validation UI:**
    Provide a premium glassmorphic build deck indicating monument prices, stock counts, and live out-of-money/out-of-stock validation.
*   **FR 5: Cataclysmic Voxel-Crises Loops:**
    Trigger random voxel catastrophe vectors (Metaphysical Rifts/Data Glitches) every 120 seconds, damping local belief generation until cleansed by the player.
*   **FR 6: 3x3 Auto-Battler Arena:**
    Initiate instance matches on 3x3 grids where formless deities deploy and battle asynchronously using Euclid-distance targeting matrices.
*   **FR 7: Divine Interventions & Client-Side Prediction:**
    Allow active spells from the player during combat with immediate Client-Side Prediction, masked latency by a 1.5s Ascension-Lock, and full server validation.
*   **FR 8: Devotion Fusion & Evolution:**
    Permit players to merge deities in transactional chambers, scaling properties according to sublinear logarithmic limits ($R_L = R_0 \cdot (1 + \ln(L + 1))$).

### Non-Functional Requirements

*   **NFR 1: Zero-Allocation 60Hz Battle Replication:**
    Avoid all Lua table allocations in the battle loop using raw bit-packed `buffer` packing (284 bytes per frame, 90 frames rolling history).
*   **NFR 2: Exploit-Proof Server Authority:**
    Calculate all resource increments and placement locations exclusively on the server, completely ignoring client timestamps.
*   **NFR 3: Performance-Optimized Voxel LOD Rendering:**
    Implement dynamic mesh swapping (SLIM/Light-weight meshes) for deities placed beyond 150 studs.
*   **NFR 4: Transactional Database Integrity:**
    Isolate deity fusion operations with safe in-memory queues and transaction rollbacks to prevent item-loss during server shutdowns.

---

### FR Coverage Map

| GDD Requirement / Feature | Technical Architecture Component | Remote Contract / Net Boundary |
| :--- | :--- | :--- |
| **Grid Placement Voxel Stacking** | `GridCollisionModule.luau` (Server) | `RequestPlacementEvent` (Remote) |
| **Live Belief Currency Flow** | `PlayerDataStore.luau` (Server) | Attribute replication (`CitadelBelief`) |
| **Passive Income Generation Loop** | `GridModule.Update` (Server 1.0s Loop) | Attribute replication (`CitadelBeliefRate`) |
| **Deity Build Deck & Validation** | `DeitySelectionController.client.luau` | Attribute replication (`CitadelInventory` JSON) |
| **Cataclysmic Event Damping** | `CrisisService.server.luau` | `TriggerCleansingEvent` (Remote) |
| **Match Ring-Buffer History** | `RollbackModule.luau` (Server 90 Frames) | `SyncCombatBufferEvent` (Remote Stream) |
| **Zero-Allocation AP Calculations** | `RingBufferModule.luau` (Shared Buffer) | Packed `buffer` binary format |
| **Deity Devotion Fusion** | `FusionService.server.luau` + `ProfileService` | `RequestFusionEvent` (Remote) |
| **Dynamic LOD Mesh Swapping** | `SLIMController.client.luau` (Client) | Handled purely locally |

---

## Epic List

1.  **Epic 1: The Core Loop Initialization & Grid Construction (Zitadellen-Fundament)**
2.  **Epic 2: The Sacral Economy & Cataclysmic Voxel-Crises**
3.  **Epic 3: The 3x3 Metaphysical Auto-Battler Combat System**
4.  **Epic 4: Divine Fusion & Persistent Genealogy**
5.  **Epic 5: Noir Aesthetics & Lod-Mesh Swapping**

---

## Epic 1: The Core Loop Initialization & Grid Construction (Zitadellen-Fundament)
**Focus**: Establishes the core cellular building loops, server validations, and premium HUD interactions.
**Player Value**: Players can purchase, preview, rotate, and place deities dynamically on their personal brutalist Citadel plate.

### Story 1.1: Shared Mathematical Snapping
As a Tycoon Builder,
I want a client/server shared snapping math library,
So that spatial grid coordinates are calculated identically on both environments.

**Acceptance Criteria:**
*   **Given** a physical Vector3 world-space coordinate
*   **When** converted via `GridMath.WorldToCellCoords`
*   **Then** it returns the correct 1-based integer cell index matching a 10x10 layout.
*   **And** a corresponding test file `GridMath.spec.lua` validates conversions for all 4 quadrants.

### Story 1.2: Interactive Client Bounding-Box Preview
As a Tycoon Builder,
I want an atmospheric visual bounding-box preview snapping to the grid and breathing under my mouse,
So that I can see the exact dimensions of a monument before committing.

**Acceptance Criteria:**
*   **Given** the placement mode is active
*   **When** I hover my mouse over the Citadel plate
*   **Then** a semi-transparent Neon part breathes (`sine` wave transparency 0.3 to 0.5) at the snapped voxel.
*   **And** it glows Neon-Lime when the placement is valid, and Neon-Crimson when invalid.
*   **And** pressing the `R` key rotates the preview 90 degrees, swapping its width and length dimensions dynamically.

### Story 1.3: Server-Authoritative Placement Verification
As a Citadelle Architect,
I want the server to validate my placement request against collision limits and Catalogs,
So that clients cannot stack meshes or cheat prices.

**Acceptance Criteria:**
*   **Given** a client fires `PlacementRemote` with a deityId and coordinate
*   **When** verified by `GridCollisionModule.luau`
*   **Then** it checks if the voxel grid cells are completely empty.
*   **And** it verifies that the client has the monument in their inventar and enough Belief points.
*   **And** it subtracts the true catalog price from `PlayerDataStore` (ignoring any client price inputs).

### Story 1.4: Real-time Belief View & Tick-based Passive Income
As an Devoted High Priest,
I want a premium Glassmorphic HUD indicating my current currency and passive income rate,
So that I can feel my power grow with every second.

**Acceptance Criteria:**
*   **Given** the player has placed monuments that generate income
*   **When** the server runs its tick loop every 1.0 second
*   **Then** it increments player Belief points and replicates `CitadelBelief` and `CitadelBeliefRate`.
*   **And** the client UI displays the formatted Belief (e.g. `2,000`) and the rate (e.g. `+10/s`).
*   **And** the UI number pulser triggers green (+15% TextSize, `Back.Out`) on income increase, and red-shake (-10% TextSize, `Elastic.Out`) on spendings.

### Story 1.5: Dynamic Deity Selection Menu & Inventory Replication
As a Tycoon Builder,
I want a glassmorphic Build Deck at the bottom of the screen displaying my stocks,
So that I can comfortably choose which deity to build.

**Acceptance Criteria:**
*   **Given** I have different deities in my persistent inventory
*   **When** my inventory updates on the server
*   **Then** it replicates as a JSON-encoded string `"CitadelInventory"` to my client.
*   **And** the Deity Selection Menu updates card stocks, disabling and blurring cards whose stock is `0` or price is unaffordable.
*   **And** clicking an active card launches the placement mode.

### Story 1.6: Server-Authoritative Voxel-Kollision & Boundary Verification
As a Citadelle Architect,
I want a server-side voxel-collision and boundary verification system (`GridCollisionModule.luau`),
So that malicious clients cannot stack meshes (voxel-stacking) or place deities outside the active Citadel grid coordinates.

**Acceptance Criteria:**
*   **Given** a placement request to the server
*   **When** a monument is rotated (90 or 270 degrees)
*   **Then** its width and length are geometrically transformed ($W' \leftarrow D, D' \leftarrow W$).
*   **And** it checks that all target voxel coordinates ($F \subseteq \text{GridBounds}$) are inside citadel boundaries.
*   **And** it checks that all target coordinates are empty ($\text{Grid}[c] = \emptyset$).
*   **And** a TestEZ unit test validates that out-of-bounds placements are rejected.
*   **And** a TestEZ unit test validates that overlapping placements are rejected.

---


## Epic 2: The Sacral Economy & Cataclysmic Voxel-Crises
**Focus**: Handles randomized voxel catastrophe loops, damping areas, and cleaning mechanisms.
**Player Value**: Citadel maintenance becomes interactive; players must cleanse glitches/rifts to restore full belief generation.

### Story 2.1: Asynchronous Catastrophe Spawner
As a Citadel Overseer,
I want a server-side random catastrophe dispatcher running every 120 seconds,
So that the Citadel plate feels alive and dynamic.

**Acceptance Criteria:**
*   **Given** the game server is active and ticking
*   **When** a 120-second interval expires
*   **Then** the server randomly selects a 3x3 voxel area on a player's grid.
*   **And** it spawns a visual catastrophe indicator (Neon Purple Metaphysical Rift or Glitch Part).
*   **And** it fires a remote event to let clients hear a distinct warning sound.

### Story 2.2: Cellular Damping Zones
As a Citadel Overseer,
I want active voxel crises to block placement and damp local belief production,
So that I am incentivized to immediately deal with the threat.

**Acceptance Criteria:**
*   **Given** a Metaphysical Rift has spawned on grid cells (4,4) to (6,6)
*   **When** `GridCollisionModule.CheckPlacementValidity` runs for these coordinates
*   **Then** it returns `false` (OOB/Blocked).
*   **And** the passive Belief generation of any pre-placed monuments intersecting this 3x3 zone is reduced by 50%.

### Story 2.3: Server-Verified Proximity Cleansing
As a Devoted High Priest,
I want the server to strictly verify my proximity and channeling time during a cleansing ritual,
So that clients cannot teleport-cleanse or trigger instant-cleanses.

**Acceptance Criteria:**
*   **Given** a catastrophe is active
*   **When** I press `E`, the client fires a `StartCleansing` remote.
*   **Then** the server registers the start timestamp and validates that the character is within 15 studs.
*   **When** the 3-second channel completes and the client fires a `CompleteCleansing` remote.
*   **Then** the server verifies that at least 3.0 seconds have elapsed since `StartCleansing`.
*   **And** verifies that the character's current position is still within 15 studs of the crisis.
*   **And** only then removes the catastrophe, unblocks the grid, and restores the full belief rates.
*   **And** a TestEZ spec validates both instant-trigger and out-of-range exploit attempts.

### Story 2.4: Anti-Speedhack Session Verification & Damped Offline Progression
As a Core Player,
I want a server-authoritative offline belief calculation system (`SessionVerificationModule.luau`),
So that my progression is cheat-proof against local time dilation speedhacks and offline earnings are healthy damped.

**Acceptance Criteria:**
*   **Given** a player joining the game
*   **When** calculating offline elapsed time $\Delta t = t_{\text{now}} - t_{\text{last\_save}}$
*   **Then** the server uses absolute unix timestamps (`os.time()`), completely ignoring client-sent time.
*   **And** offline earnings beyond a 12-hour limit ($T_{\text{cap}} = 43200$s) are progressively damped by 90% ($\gamma = 0.10$):
    $$B_{\text{offline}} = R_p \cdot (t_{\text{effektiv}} + \gamma \cdot t_{\text{overflow}})$$
*   **And** a heartbeat syncs the last active server time every 60 seconds to protect against data loss on crash.
*   **And** a TestEZ test confirms that a 24-hour offline period generates exactly 55% of undamped earnings (43200s + 4320s).

### Story 2.5: Synkretistischer Epochenübergang (Rebirth-System)
As an High Priest,
I want to sacrifice my current Citadel to transition into a new technological epoch (prestige-reset),
So that I receive permanent meta-currencies (Sakrale Funken) and unlock deeper automation layers.

**Acceptance Criteria:**
*   **Given** I meet the epoch-transition criteria (hybrid deities owned, $10^9$ belief accumulated)
*   **When** I trigger a prestige reset
*   **Then** my current belief is wiped and all personal temple structures are removed.
*   **And** I receive *Sakrale Funken* $P$ according to the sublinear conversion formula:
    $$P = \left\lfloor \sqrt{\frac{B}{C_{\text{epoche}}}} \right\rfloor$$
*   **And** the constant $C_{\text{epoche}}$ scales exponentially for higher epochs.
*   **And** all mathematical calculations on the server run inside a dedicated **Mantissa-Exponent** structure (double mantissa, integer exponent) to prevent floating-point double overflows.

---


## Epic 3: The 3x3 Metaphysical Auto-Battler Combat System
**Focus**: ZERO-allokation combat ticks, 90-frame rollback ring-buffers, and Euclid-distance targeting.
**Player Value**: Deities battle in a highly competitive, latenz-kompensierten arena with predictable interventions.

### Story 3.1: Zero-Allocation AP Calculations (Ring Buffer)
As a Competitive Player,
I want the battle calculation loop to run without garbage collection spike lags,
So that matches remain fluid and stable at 60Hz.

**Acceptance Criteria:**
*   **Given** 18 deities on a 3x3 battlefield
*   **When** the 60Hz battle tick runs
*   **Then** all entity properties, health, action points, and status-effects are packed into a pre-allocated binary `buffer` (284 bytes per frame).
*   **And** a TestEZ test suite confirms that running 1 minute of combat simulation produces exactly 0 KB of Lua heap memory allocation.

### Story 3.2: Exploit-Proof 90-Frame Combat Rollback System
As a Competitive Player,
I want the server to validate and cap the rollback tick requested by a client,
So that clients cannot send invalid historical ticks to manipulate outcomes.

**Acceptance Criteria:**
*   **Given** the server-authoritative combat ticks running at 60Hz
*   **When** `RollbackModule.luau` stores states
*   **Then** it overwrites oldest ticks inside a 90-frame ring-buffer array.
*   **And** when a client invokes an intervention at `clientTick`, the server checks if $\Delta T = T_{\text{current}} - T_{\text{clientTick}}$ is between 0 and 90 frames.
*   **And** if $\Delta T$ is out of bounds, the request is immediately discarded as an invalid state-sync.
*   **And** if valid, the server rolls back to `clientTick`, performs geometric validation, and fast-forwards the remaining buffer frames.
*   **And** TestEZ specs verify both too-old (91+ frames) and future-tick spoofing attempts.

### Story 3.3: Tactical Euclidean Targeting & Battle Orchestrator
As a Tactical Deceiver,
I want my deities to target enemies based on euklidischen target matrices,
So that combat maneuvers are mathematically predictable.

**Acceptance Criteria:**
*   **Given** a deity is ready to attack
*   **When** selecting a target
*   **Then** the orchestrator computes the Euclid distance $\sqrt{(x_2-x_1)^2 + (z_2-z_1)^2}$ to all enemy entities.
*   **And** it selects the closest target matching its role config (e.g. Tank, Supporter, Slayer).

### Story 3.4: Predicted Auras & 1.5s Ascension-Lock
As a Competitive Player,
I want client-side spells to animate instantly while the server processes an Ascension-Lock,
So that input feels snappy while maintaining absolute network protection.

**Acceptance Criteria:**
*   **Given** a client triggers an Intervention spell
*   **When** the remote fires
*   **Then** the client immediately renders the glowing spell aura locally.
*   **And** the server locks the state for a 1.5-second "Ascension-Lock", giving the opponent a reaction window.
*   **And** the server validates target ranges at the end of the lock, executing or discarding the spell authoritatively.

### Story 3.5: Binary Ring-Buffer Packing Architecture (`RingBufferModule.luau`)
As a Competitive Player,
I want a binary packing and unpacking layout for combat frames in Luau memory,
So that the 60Hz server heartbeat runs without garbage collection lag spikes.

**Acceptance Criteria:**
*   **Given** 18 deities deployed on a 3x3 arena
*   **When** serializing the tick state
*   **Then** all entity coordinates, HP, AP, and status masks are packed into a pre-allocated binary `buffer` of 284 bytes per frame.
*   **And** a total ring-buffer capacity of 90 frames (25560 bytes) is allocated on startup.
*   **And** a TestEZ benchmark validates that 10,000 packing steps do not allocate any heap memory (0 KB increase on `gcinfo()`).

### Story 3.6: Server-Authoritative Latenz-Rollback-Validierer (`RollbackModule.luau`)
As a Competitive Player,
I want the server to authoritatively validate my intervention spells against historical buffer frames,
So that network latency is compensated and malicious status exploits are prevented.

**Acceptance Criteria:**
*   **Given** an intervention remote request at `clientTick`
*   **When** validated on the server
*   **Then** the request is discarded if the tick difference $\Delta T = T_{\text{server}} - T_{\text{client}}$ exceeds 90 frames (1.5 seconds).
*   **And** the server rolls back to `clientTick`, computes Euclidean range limits, and verifies that the targeted entity had $HP > 0$ at that exact moment.
*   **And** if validation fails, the server rejects the spell and fires a `Correction` network packet to force the client to snap back to the authoritative tick.

---


## Epic 4: Divine Fusion & Persistent Genealogy
**Focus**: Mathematical deity evolution scaling ($R_L = R_0 \cdot (1 + \ln(L + 1))$) and transactional ProfileService database safety.
**Player Value**: Players can merge duplicate deities to evolve powerful new entities without risking item loss.

### Story 4.1: True Logarithmic Deity Evolution Module
As an Alchemist of Götter,
I want the fusion of deities to follow a true logarithmic mathematical scale,
So that the orbital radius grows in a controlled, non-disruptive sublinear manner.

**Acceptance Criteria:**
*   **Given** two deities are fused at Level L
*   **When** the new properties are calculated
*   **Then** the orbital radius scales sublinearly as:
    $$R_L = R_0 \cdot (1 + \ln(L + 1))$$
*   **And** the rotation velocity scales down mathematically as:
    $$\omega_L = \frac{\omega_0}{\sqrt{L + 1}}$$
*   **And** a TestEZ test validates that at Level 10, the radius is exactly $3.39 \cdot R_0$ (within a 0.01 tolerance limit), preventing visual layout overflow.

### Story 4.2: Transactional Fusion Queue (ProfileService)
As a Götter Collector,
I want my deity fusions to be database-protected against crashes,
So that I never lose precious deities during network blackouts.

**Acceptance Criteria:**
*   **Given** a fusion request is processing
*   **When** the database writes are triggered
*   **Then** the operation is treated as an isolated transaction.
*   **And** if a server crash occurs before completion, the fusion rolls back, restoring original deities to the player's profile.

### Story 4.3: Sakrales Fusions- & Mendelsches Vererbungssystem
As a Deity Breeder,
I want a fusion chamber that strictly adheres to Mendelian inheritance laws and room stimulation formulas,
So that I can strategically breed tactical hybrid deities without creating game-breaking stat inflation.

**Acceptance Criteria:**
*   **Given** two parent deities in the fusion transactional chamber
*   **When** fusion is initiated
*   **Then** only base statistics are inherited (base HP, base attack, base speed), ignoring any acquired bonus stats.
*   **And** the inheritance chance of the superior stat $P_{\text{besser}}$ is dynamically driven by the room stimulation parameter $S \in [0, 100]$:
    $$P_{\text{besser}} = \frac{1.0 + 0.01 \cdot S}{2.0 + 0.01 \cdot S}$$
*   **And** the resulting hybrid deity receives a persistent `IsStabilized = true` flag and cannot be used as a parent for further fusions.
*   **And** a player can "unfuse" a stabilized hybrid deity at any time for a belief fee, recovering both parent deities while losing the original fusion catalysts.
*   **And** a TestEZ unit test validates inheritance probability distribution for stimulation values $S=0$ ($50\%$), $S=50$ ($60\%$) and $S=100$ ($100\%$).

### Story 4.4: Raumkomfort- & Mutations-Steuerung
As a Deity Breeder,
I want my chamber's comfort parameter ($\mu$) and spatial room classification to influence fusion success and mutation probability,
So that citadel optimization directly affects the evolution quality of my pantheon.

**Acceptance Criteria:**
*   **Given** a fusion process
*   **When** the current room comfort $\mu$ is below the threshold $\mu_{\text{min}}$
*   **Then** the fusion is strictly blocked.
*   **When** room comfort is maximized ($\mu_{\text{max}}$) and configured as "Barracks" (combat mutation) or "Royal" (vitality mutation)
*   **Then** it triggers unique, rare mutations giving the hybrid deities exclusive heritable passive talents.

---


## Epic 5: Noir Aesthetics & Lod-Mesh Swapping
**Focus**: Pantheon-Noir chromatic aberration effects, dynamically alternating client aura loops, and light-weight LOD-mesh swaps.
**Player Value**: The game looks breathtakingly premium on high-end PCs, while running smoothly on lower-end mobile devices.

### Story 5.1: Pantheon-Noir Aura Alternator
As a Visual Enthusiast,
I want my deities to emit abstract auras alternating in color,
So that the visual distinction between Ancient and New Gods is striking.

**Acceptance Criteria:**
*   **Given** a deity is placed in the workspace
*   **When** rendering its aura
*   **Then** the client LocalScript animates a smooth interpolation between stone-gray and glitched-cyan.
*   **And** a subtle chromatic aberration shader triggers when high-level deities activate their orbits.

### Story 5.2: Light-weight LOD-Mesh Swapper (SLIM)
As a Mobile Player,
I want the game to swap heavy deity meshes with lightweight low-poly proxies beyond 150 studs,
So that my frame rate remains stable at 60 FPS.

**Acceptance Criteria:**
*   **Given** many complex brutalist monument meshes are in my Citadel view
*   **When** their distance to the camera exceeds 150 studs
*   **Then** the `SLIMController.client.luau` replaces them with simplified proxy models (under 100 triangles).
*   **And** they are instantly restored to high-detail meshes once the camera moves within 150 studs.

### Story 5.3: Glaube-Momente Video-Capture Integration
As a Visual Enthusiast,
I want my greatest tactical battle triumphs to be recorded automatically in the background,
So that I can post clean cinematic clips to Roblox Moments without 2D HUD interferences.

**Acceptance Criteria:**
*   **Given** a dramatic in-game battle event (e.g. single survivor deity winning a round with 100% health)
*   **When** triggered client-side
*   **Then** the game automatically records a 30-second clean gameplay clip via `CaptureService:StartVideoCaptureAsync()`.
*   **And** all game states (health, active synergy beams, damage indicators) are visualized in 3D in the workspace (monolith fractures, volumetric lasers, 3D rune texts), since Roblox automatically removes all 2D ScreenGuis in Moments clips.
*   **And** an elegant post-game UI prompt offers the player options to save the capture locally (`PromptSaveCapturesToGallery`) or upload it to the Moments stream (`UploadCaptureAsync`).

### Story 5.4: Konformes Moments-Sharing & PolicyService-Schutz
As a Compliance-Focused Developer,
I want the Moments sharing system to strictly adapt to players' age privacy settings,
So that youth accounts are protected and the game remains compliant with global platform guidelines.

**Acceptance Criteria:**
*   **Given** a client loading the capture and moments sharing interfaces
*   **When** verifying sharing policies
*   **Then** the system checks user permissions via `PolicyService:IsContentSharingAllowed`.
*   **And** if sharing is restricted (e.g. accounts under 16 years old), all capture galleries, upload buttons, and lobby moments-billboards are completely hidden and disabled.
*   **And** shared moments are parameterized using `SocialService:PromptLinkSharing` with launch data, teleporting friends directly to the exact temple location and setup of the clip creator.

