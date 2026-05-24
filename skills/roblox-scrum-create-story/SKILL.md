---
name: roblox-scrum-create-story
description: 'Creates a dedicated Roblox story specification file with full context (GDD, architecture, project-context) for the Developer Agent. Use when the user says "create the next story" or "create story [identifier]".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum: Create Story Workflow

**Goal:** Create a comprehensive story specification file that gives the developer agent everything needed for flawless Luau/Roblox implementation.

**Your Role:** Story Context Engine that prevents LLM developer mistakes, omissions, or structural regressions.

---

## Operating Guidelines

- **Language:** Perform the workflow in English. Respond and communicate with the creator/user in German (their primary language) unless requested otherwise.
- **Paths**:
  - `planning_artifacts` = `docs/planning-artifacts`
  - `implementation_artifacts` = `docs/implementation-artifacts`
  - `sprint_status` = `{implementation_artifacts}/sprint-status.yaml`
  - `epics_file` = `{planning_artifacts}/epics.md` or `epics_and_stories.md`
  - `gdd_file` = `{planning_artifacts}/gdd.md`
  - `architecture_file` = `{planning_artifacts}/architecture.md`
  - `project_context` = `**/project-context.md` (load if exists)
  - `template` = `./template.md`
  - `validation` = `./checklist.md`
  - `output_file` = `{implementation_artifacts}/stories/{{story_key}}.md`

---

## Workflow Steps

### Step 1: Determine the Target Story
1. Parse user input if a specific story key or ID (e.g. `1-2` or `1-2-leaderboard-ui`) is given.
2. If no user input is provided, auto-discover by reading `{sprint_status}` from top to bottom. Find the **FIRST story key** where:
   - It matches pattern `number-number-title` (e.g., `1-2-leaderboard-ui`)
   - It is NOT an epic key (`epic-X`) or retrospective key.
   - Status value is `"backlog"`.
3. Extract `epic_num`, `story_num`, `story_title` from the key. Set `story_id = epic_num.story_num` and `story_key = epic-story-title`.
4. If this is the first story in Epic `epic_num` and the epic's status is `"backlog"`, update the epic's status in `sprint-status.yaml` to `"in-progress"`.

### Step 2: GDD & Architecture Context Analysis
1. Load `epics_file` and extract Epic `{epic_num}` complete context.
2. Extract our target story details: Acceptance Criteria (BDD format), technical constraints, dependencies.
3. Load and scan `architecture_file` for Roblox-relevant details:
   - Folder structure conventions (e.g., Mojo, Rojo namespaces, directories: `src/server`, `src/client`, `src/shared`).
   - Network boundaries: RemoteEvent/RemoteFunction definitions in `ReplicatedStorage`.
   - Security constraints: Validation on the server, anti-exploit rules.
4. Scan `project_context` for required Wally packages, Selene lint definitions, StyLua formatting rules, or Roblox Studio MCP settings. Store as `{{project_rules}}`.

### Step 3: Continuity & previous story analysis
1. If `story_num > 1`, find the previous story file: `{implementation_artifacts}/stories/{{epic_num}}-{{previous_story_num}}-*.md`.
2. Extract **Previous Story Intelligence**:
   - Dev learnings, review feedback, files created/modified, and code patterns established.
3. Check the git repository (last 5 commits) to analyze recent file modifications and coding styles.

### Step 4: Web / Library Research
1. Identify any third-party Luau libraries (e.g., Promise, Roact, Fusion, Knit, Cmdr) or Roblox APIs mentioned.
2. Use available tools (like Context7 MCP or web search) to research latest stable versions and API conventions.

### Step 5: Draft the Story Spec
1. Initialize the draft using `{template}`.
2. Populate:
   - Acceptance Criteria (detailed, BDD-formatted *Given/When/Then*).
   - Tasks / Subtasks checkbox list (extremely detailed, step-by-step developer actions).
   - Dev Notes: Roblox Architecture requirements, Replication models, Touched files, Wally configs.
   - Project Context Rules: Extracted from `project-context.md`.
   - Previous Story Intelligence and Git insights.
3. Validate the drafted story file against `{validation}` (checklist.md) to detect any missing constraints, vague steps, or structural gaps. Fix any issues found.

### Step 6: Update Sprint Status & Finalize
1. Save the final story file to `{output_file}`.
2. Update the story status in `{sprint_status}`: change `{story_key}` status from `"backlog"` to `"ready-for-dev"`.
3. Inform the user in German with a structured report:
   - Story ID & Key
   - Path to the generated story spec
   - Summary of key Roblox-specific guardrails included
   - Suggest running the developer agent using the `roblox-scrum-dev-story` skill.
