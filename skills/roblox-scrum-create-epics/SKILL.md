---
name: roblox-scrum-create-epics
description: 'Transforms Roblox GDD and Architecture specifications into a comprehensive list of Epics and detailed User Stories with BDD-formatted acceptance criteria. Use when the user says "create epics and stories" or "scaffold project backlog".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum: Create Epics and Stories Workflow

**Goal:** Transform GDD requirements and Architecture decisions into detailed, user-value-focused Epics and User Stories with complete BDD-formatted acceptance criteria.

**Your Role:** Game Product Strategist and technical specifications writer. Partner with the creator to decompose their game vision into high-discipline, modular milestones.

---

## Operating Guidelines

- **Language:** German for user interactions. English for technical document contents (matches standard Roblox terminology).
- **Paths**:
  - `planning_artifacts` = `docs/planning-artifacts`
  - `gdd_file` = `{planning_artifacts}/gdd.md`
  - `architecture_file` = `{planning_artifacts}/architecture.md`
  - `output_file` = `{planning_artifacts}/epics_and_stories.md`
  - `template` = `./epics-template.md`

---

## Workflow Steps

### Step 1: Validate Prerequisites
1. Scan `{planning_artifacts}` for the GDD (`gdd.md` or `game-brief.md`) and the Technical Architecture (`architecture.md`).
2. If those files are missing, guide the user to run `roblox-brief` and `roblox-blueprint` first to establish the design and technical foundation.
3. Read the GDD and Architecture documents completely, extracting:
   - Target player segments and motivations.
   - List of game features (e.g. cash collectors, inventory, leaderboards, combat).
   - Non-functional requirements (e.g. stable 60 FPS with 500+ items, networking replication limits, mobile support).

### Step 2: Establish Requirements Inventory & Map Coverage
1. Compile a prioritized inventory of Functional Requirements (FR) and Non-Functional Requirements (NFR).
2. Create an FR Coverage Map linking each GDD feature to its technical architecture touchpoint (e.g., *Proximity Activation ➔ Client LocalScript magnitude check + Server RemoteEvent validate*).

### Step 3: Design the Epic List
1. Group features into user-value-oriented Epics.
   - Each Epic must represent a playable or testable milestone.
   - Example list:
     - **Epic 1: The Core Loop Initialization** (Project setup, basic movement, spawn point, core stats).
     - **Epic 2: The Economy / Core System** (Currency drop, server authority collection, saving state).
     - **Epic 3: Social & Visual Polish** (Leaderboards, UI animations, trade loops, player inspect).
2. Review the Epic structure with the user in German to confirm alignment with their gameplay vision.

### Step 4: Decompose Epics into Detailed User Stories
For each Epic, write highly detailed, actionable User Stories using the following format:

```markdown
### Story N.M: <Title>

As a <user_type>,
I want <capability>,
So that <value_benefit>.

**Acceptance Criteria:**

**Given** <precondition>
**When** <action>
**Then** <expected_outcome>
**And** <additional_criteria>
```

#### **Roblox Quality Guardrails for Stories**:
- **Replication**: Explicitly define the networking boundary (Remotes).
- **Server Authority**: Mandate that client requests are validated on the server.
- **Pure Luau**: Use plain ModuleScript references; avoid enterprise jargon slop.
- **TDD Hook**: Define TestEZ test expectations in the acceptance criteria.

### Step 5: Write the Backlog Document
1. Load `{template}` and populate all sections:
   - Requirements Inventory
   - FR Coverage Map
   - Epic List and detailed Story decompositions.
2. Save the final document to `{output_file}`.
3. Guide the user in German on the next step: running `roblox-scrum-planning` to build the `sprint-status.yaml` agile tracking board!
