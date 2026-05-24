---
name: roblox-scrum-correct-course
description: 'Adjusts sprint scopes, manages blockers, or changes project directions mid-sprint. Use when the user says "correct course", "change sprint scope", or "manage blocker".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum: Correct Course Workflow

**Goal:** Provide an organized procedure to adjust the sprint backlog, adapt story definitions to new architectural discoveries, and log course corrections without losing context or introducing regressions.

**Your Role:** Scrum Master / Agility Advisor.

---

## Operating Guidelines

- **Language:** German for user communications and decision logging. English for technical documents.
- **Paths**:
  - `sprint_status` = `docs/implementation-artifacts/sprint-status.yaml`
  - `stories_folder` = `docs/implementation-artifacts/stories`
  - `gdd_file` = `docs/planning-artifacts/gdd.md`

---

## Workflow Steps

### Step 1: Gather Course-Correction Context
1. Elicit from the user or analyze the latest workspace error/log to understand:
   - What is the blocker or change in direction? (e.g. "Roblox DataStores are failing because of rate limits", "The UI needs a completely different reward loop", "A new Roblox Studio MCP version is breaking script inserts").
   - Which stories are impacted?
2. Review `{sprint_status}` to identify current story and epic statuses.

### Step 2: Adapt Backlog & Stories
1. **Adding / Modifying Stories**:
   - If a story needs scope changes, open `{stories_folder}/{story_key}.md` and modify its Acceptance Criteria or Tasks. Put a distinct `[Course-Correction]` tag on new subtasks.
   - If a new story is required, insert it into `sprint-status.yaml` in its logical sequence, keeping the naming scheme `epic-story-title`. Mark status as `backlog` (or `ready-for-dev` if immediately scaffolding it).
2. **De-scoping Stories**:
   - If a story is no longer needed, change its status in `{sprint_status}` to `descoped` or `backlog` (to move it out of the current sprint).

### Step 3: Document Decisions
1. Log the decision rationale in the Project Hub (`00_Roblox-Game-Dev Hub.md`) or in the `docs/planning-artifacts/sprint-change-proposal.md` log.
2. Note:
   - The date and reasoning for the shift.
   - Impacted assets (scripts, remotes, Wally configurations).
   - Technical workarounds planned.

### Step 4: Resume Sprint
1. Refresh the sprint board using `roblox-scrum-planning` to validate structure.
2. Direct the developer agent to the next appropriate task or the modified story. Report in German with a reassuring, structured overview of changes.
