---
name: roblox-scrum-dev-story
description: 'Executes Roblox story implementation following a context-filled story spec file, using TDD, StyLua, Rojo, and the Roblox Studio MCP integration. Use when the user says "develop story [key]" or "implement the next story".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum: Dev Story Workflow

**Goal:** Implement the specified user story following a comprehensive context-filled story spec file, maintaining strict Roblox-native guardrails and achieving verified completion.

**Your Role:** Developer Agent executing story implementation.

---

## Operating Guidelines

- **Language:** Communicate all responses and logs in German (tailored to creator experience), but keep Luau technical specs and code comments in English.
- **Paths**:
  - `sprint_status` = `docs/implementation-artifacts/sprint-status.yaml`
  - `stories_folder` = `docs/implementation-artifacts/stories`
- **Roblox-Native Guardrails**:
  - **Server Authority**: Clients request, server validates, server mutates canonical state. Validate all RemoteEvent/RemoteFunction parameters strictly on the server.
  - **No Enterprise Slop**: Use pure Luau, standard engine services, and component/module terminology.
  - **Evidence over Assumptions**: Prove completion via test execution and runtime console/play tests.

---

## Workflow Steps

### Step 1: Discover and Load the Story
1. Parse user input for a specific story key (e.g. `1-2-leaderboard-ui`).
2. If no key is provided, load the FULL `{sprint_status}` file. Parse the `development_status` section and select the **FIRST story** marked as `ready-for-dev` or `in-progress`.
3. Locate the corresponding spec file: `{stories_folder}/{story_key}.md` and read it completely.
4. If a "Senior Developer Review (AI)" or "AI-Review" section exists in the story file, parse the review comments to prioritize follow-up tasks before moving to regular implementation steps.

### Step 2: Set Status to In-Progress
1. Load `{sprint_status}` and change `{story_key}` status to `in-progress`. Update the `last_updated` date to today.
2. Report the start of work to the user in German, listing the first incomplete task.

### Step 3: Implement Tasks using TDD and Roblox Studio MCP
Execute the tasks and subtasks listed in the story spec in exact sequential order. For each task, perform the **Red-Green-Refactor** cycle:

#### **🔴 RED Phase: Write Failing Tests**
- Before implementing any production Luau code, write a TestEZ test (or Jest-Roblox test).
- Place test files under `src/shared/__tests__/` or a matching `*.spec.lua` sibling location.
- Run tests (e.g., using `mcp__Roblox_Studio__execute_luau` or `npm run test` or Rojo toolchains) to verify that the test fails. This proves the test is valid and not a false positive.

#### **🟢 GREEN Phase: Implement minimal code**
- Write the minimal Luau code necessary to make the tests pass.
- Use `mcp__Roblox_Studio__*` tools:
  - `script_read` / `multi_edit`: Read and write code directly in Roblox Studio.
  - `execute_luau`: Run play solo or execute script logic to verify behavior.
  - `get_console_output`: Inspect runtime errors and game prints.
  - `screen_capture`: Take a screenshot of the viewport to verify UI rendering or visual assets.
- Verify tests now pass.

#### **🔵 REFACTOR Phase: Clean and Lint**
- Refactor the code for maximum readability, clean naming, and modular separation.
- Format all modified files with `stylua` and check for errors using `selene` linting.
- Re-run all tests to ensure the codebase remains green.

### Step 4: Update Story Spec and Progress
1. Keep the story spec file in sync:
   - Check off completed tasks `[x]` and subtasks.
   - Record notes in the *Dev Agent Record* (specify model, completion details, and touchpoints).
   - Add new/modified files to the *File List* section.
2. If any blocker arises or external library dependencies are missing, pause work, log the status, and seek the creator's guidance. Do not halt mid-execution for minor milestones.

### Step 5: Finalize and Move to Review
1. Once all acceptance criteria are checked and all tasks are `[x]`, run a **COMPLETE & EXHAUSTIVE VERIFICATION**:
   - Compile the game tree using Rojo and ensure no Wally lock violations.
   - **Exhaustive Testing**: Run the full TestEZ / Jest-Roblox test suite. Assert that all unit, module, and replication tests are 100% green.
   - **Manual/Console Audit**: Check the console output (`get_console_output`) during active Play Solo testing to ensure zero runtime warnings or exceptions exist.
   - **Mandatory Visual Verification**: Trigger a screen capture in Roblox Studio using the `screen_capture` tool. Save this screenshot as visual evidence in the implementation folder (or display it to the user). Confirm that UI overlays, character visuals, or modifications align perfectly with GDD/UX specs.
2. Update `{sprint_status}`: change `{story_key}` status to `review`.
3. Inform the user in German of successful implementation, outputting:
   - File list of created/modified assets.
   - Summary of tests run, console outputs audited, and the captured screenshot file path.
   - Instructions on running `roblox-code-review` to validate code replication and server security gates.
