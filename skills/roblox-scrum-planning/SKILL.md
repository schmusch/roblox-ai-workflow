---
name: roblox-scrum-planning
description: 'Generate and update the sprint status tracking board from Roblox epics. Use when the user says "run sprint planning", "generate sprint plan", or "update scrum board".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum Planning

**Goal:** Generate sprint status tracking from epics, detecting current story statuses and building/updating a complete `sprint-status.yaml` file.

**Your Role:** You are the Scrum Master generating and maintaining sprint tracking. Parse Roblox epic files, detect story statuses, and produce a structured `sprint-status.yaml` as the Single Source of Truth (SSOT).

---

## Operating Guidelines

- **Language:** Perform the workflow in English. Respond and communicate with the creator/user in German (their primary language) unless requested otherwise.
- **Paths**:
  - `planning_artifacts` = `docs/planning-artifacts` (or fallback to `planning-artifacts` or `plans`)
  - `implementation_artifacts` = `docs/implementation-artifacts` (or fallback to `implementation-artifacts` or `plans`)
  - `status_file` = `{implementation_artifacts}/sprint-status.yaml`
  - `stories_folder` = `{implementation_artifacts}/stories`
  - `epics_pattern` = `*epic*.md`

---

## Workflow Steps

### Step 1: Parse Roblox Epic Files and Extract Work Items
1. Look for all files matching `{epics_pattern}` in `{planning_artifacts}`. If not found, fuzzy match with folders or search globally in the vault (e.g., `epics.md`, `epics_and_stories.md`, `user-stories.md`).
2. Read the files completely. Extract:
   - Epic numbers and titles (e.g., `## Epic 1: Tactical Tycoon Core`)
   - Story IDs and titles (e.g., `### Story 1.1: Cash Generator Module Script` or `#### Story 1.2: Leaderboard Replicated Storage UI`)
3. Convert the original `Epic.Story: Title` into a standard kebab-case key:
   - **Conversion Rule**: `1.1: Cash Generator` ➔ `1-1-cash-generator`
   - All lowercase, alphanumeric characters and dashes only.
4. Compile a full in-memory inventory of all Epics and Stories in exact sequence.

### Step 2: Build the Sprint Status Structure
For each epic found, create YAML entries in the following sequence:
1. **Epic entry** - Key: `epic-{num}`, Default status: `backlog`
2. **Story entries** - Key: `{epic}-{story}-{title}`, Default status: `backlog`
3. **Retrospective entry** - Key: `epic-{num}-retrospective`, Default status: `optional`

Example structure:
```yaml
development_status:
  epic-1: backlog
  1-1-cash-generator: backlog
  1-2-leaderboard-ui: backlog
  epic-1-retrospective: optional
```

### Step 3: Apply Intelligent Status Detection
For each story, scan for its corresponding implementation file:
- Check if file `{stories_folder}/{story-key}.md` exists.
- If it exists ➔ upgrade its status in `sprint-status.yaml` to at least `ready-for-dev`.
- Read the story file's frontmatter or `Status:` section. If it says `in-progress`, `review`, or `done`, map that value directly.
- **Preservation Rule**: If an existing `sprint-status.yaml` exists, preserve any advanced statuses. **Never downgrade** a status (e.g., do not overwrite `done` to `ready-for-dev` or `backlog`).

**State Transitions**:
- **Epic**: `backlog` ➔ `in-progress` ➔ `done` (automatically `in-progress` when first story is created).
- **Story**: `backlog` ➔ `ready-for-dev` ➔ `in-progress` ➔ `review` ➔ `done`
- **Retrospective**: `optional` ➔ `done`

### Step 4: Write or Update sprint-status.yaml
Write the complete YAML content to `{status_file}`. The file must contain both double-nested metadata comments at the top (for readability) and standard YAML key-values:

```yaml
# generated: 2026-05-24
# last_updated: 2026-05-24
# project: Roblox Game Dev
# tracking_system: file-system
# story_location: docs/implementation-artifacts/stories

# STATUS DEFINITIONS:
# ==================
# Epic Status:
#   - backlog: Epic not yet started
#   - in-progress: Epic actively being worked on
#   - done: All stories in epic completed
#
# Story Status:
#   - backlog: Story only exists in epic file
#   - ready-for-dev: Story file created in stories folder
#   - in-progress: Developer actively working on implementation
#   - review: Ready for code review (via Dev's code-review workflow)
#   - done: Story completed

generated: "2026-05-24"
last_updated: "2026-05-24"
project: "Roblox Game Dev"
tracking_system: "file-system"
story_location: "docs/implementation-artifacts/stories"

development_status:
  epic-1: backlog
  1-1-cash-generator: backlog
  1-2-leaderboard-ui: backlog
  epic-1-retrospective: optional
```

### Step 5: Report Progress in German
Verify the file is written correctly. Provide a clean summary to the user including:
- Location of the `sprint-status.yaml` file.
- Total Epics and Stories detected.
- Count of stories in each state (`backlog`, `ready-for-dev`, `in-progress`, `review`, `done`).
- Suggest the next step, which is running `roblox-scrum-create-story` for the next backlog story.
