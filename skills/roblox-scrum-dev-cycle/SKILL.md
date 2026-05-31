---
name: roblox-scrum-dev-cycle
description: 'Runs a complete, autonomous end-to-end Roblox SCRUM development cycle (Planning ➔ Story Creation ➔ TDD Execution ➔ Code Review) in a single unified run. Use when the user says "run dev cycle", "autopilot the next story", or "execute full scrum cycle".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum: Complete Development Cycle

**Goal:** Automate and execute a complete Roblox SCRUM development cycle for the next backlog story in a single, high-discipline run: planning, story creation, TDD-driven implementation, and final code review.

**Your Role:** Full-Stack Roblox Autonomous Agent acting as Scrum Master, Context Engineer, Developer, and QA Reviewer in sequence.

---

## Operating Guidelines

- **Language:** German for user communications and logs. English for Luau specs and files.
- **Backbone Sequence**:
  ```
  1. Planning (roblox-scrum-planning)
       ➔ 2. Story Spec Creation (roblox-scrum-create-story)
       ➔ 3. TDD Implementation (roblox-scrum-dev-story)
       ➔ 4. Quality Code Review (roblox-code-review)
  ```
- **Autonomy Ceiling**: Proceed sequentially through all phases without interrupting the creator unless a hard blocker is met.

---

## Workflow Steps

### Phase 1: Sprint Planning & Story Discovery
1. Load e-mail/vault configs and run the `roblox-scrum-planning` workflow.
2. Read the canonical `docs/epics_and_stories.md` file.
3. Update `docs/sprint-status.yaml` with legal status transitions.
4. Detect the **first available backlog story key** (e.g. `1-1-cash-generator`). If no story is in `backlog`, stop and report that all work is completed.
5. Report the target story key to the user in German and transition immediately to Phase 2.

### Phase 2: Story Context Generation
1. Act as the Context Engineer to build the ultimate, disaster-proof story spec guide.
2. Load the GDD (`docs/00.1_Game-Brief.md`), Technical Architecture (`docs/00.2_Blueprint.md`), and glob `project-context.md`.
3. If applicable, load the previous story spec to extract continuity learnings and touchpoint files.
4. Scaffold `docs/stories/{story_key}.md` using the story spec template.
5. Run the **Quality and Disaster Prevention Checklist**:
   - Check and enforce **Server Authority** rules (explicit remote validation, no client-trusted values).
   - Clean out **Enterprise Slop** (no `Controller` / `Repository` jargon, pure Luau modules only).
   - Ensure explicit BDD-formatted Acceptance Criteria (*Given-When-Then*) are written.
   - Verify directory placement rules (server scripts in ServerScriptService, shared modules in ReplicatedStorage).
6. Set the story status in `sprint-status.yaml` to `ready-for-dev`.

### Phase 3: TDD Story Implementation
1. Shift the story status in `sprint-status.yaml` to `in-progress`.
2. Systematically execute the subtasks inside the story spec in exact order. For each subtask, run the **Red-Green-Refactor TDD cycle**:
   - **RED**: Write a failing TestEZ/Jest-Roblox spec test (e.g., `src/shared/__tests__/*.spec.lua`). Ensure the test fails before any production code is written.
   - **GREEN**: Write minimal Luau code to make the tests pass. Use the Roblox Studio MCP tools (`mcp__Roblox_Studio__*`) to insert/edit scripts, execute Luau in the running workspace, and monitor prints.
   - **REFACTOR**: Format code with StyLua, resolve Selene lints, and ensure all tests remain green.
3. Check off tasks `[x]` in the story spec file and populate the *Dev Agent Record* (model used, touched files, debug log).

### Phase 4: Quality Code Review & Pre-Commit Verification (Exhaustive Testing & Visual Proof)
1. Act as the Senior Roblox Reviewer and QA Auditor. Analyze the cumulative git diff or touchpoints of the implemented story.
2. Run the `roblox-code-review` gates:
   - **Network Audit**: Are RemoteEvents rate-limited and proximity-checked?
   - **Replication Audit**: Are local changes decoupled from server authoritative states?
   - **Convention Audit**: Are names PascalCase and compliant with `references/roblox-vocabulary.md`?
3. **MANDATORY PRE-COMMIT TEST & SYNC GATE**:
   - **Exhaustive Testing**: Run the complete automated test suite (TestEZ / Jest-Roblox) and verify that 100% of assertions pass. If any test fails, return to Phase 3.
   - **Manual/Play Solo Test Run**: Trigger play-testing in Roblox Studio. Query the active console output (`get_console_output`) to ensure there are zero warnings, errors, or unhandled exceptions.
   - **Mandatory Visual Verification**: Trigger a screen capture in Roblox Studio using the `screen_capture` tool. Save this screenshot as visual evidence in the implementation folder (or display it to the user). Confirm that UI overlays, character visuals, or modifications align perfectly with GDD/UX specs.
   - **Replication Probe**: If remotes or persistence layers were added, run runtime checks (e.g. `execute_luau` server-side) to ensure data is persisting and replicating.
   - **Documentation Maintenance**: The developer agent MUST keep all documentation in sync with code modifications to prevent drift:
     a) If the implementation introduced or modified RemoteEvents, RemoteFunctions, data schemas (PlayerDataStore), or significant structural ModuleScripts, update the Technical Architecture Blueprint (`docs/00.2_Blueprint.md`).
     b) If the implementation introduced or modified game mechanics, unit designs, tycoon economics, player progression, or gacha balance, update the Game Brief (`docs/00.1_Game-Brief.md`).
     c) If the overall features of the game were expanded or changed, update the Feature Matrix (`docs/Spielmechanik_Uebersicht.md`).
4. If gaps or failures are found during these audits, return to Phase 3 to resolve them immediately. If all tests, lints, and visual evidence pass:
   - Update `{story_key}` status to `done` in `sprint-status.yaml`.
   - If all stories in the Epic are now `done`, update the Epic status to `done`.

### Phase 5: Final Retrospective and Handoff
1. Output a beautifully structured report in German detailing the entire Dev Cycle run:
   - Story completed and file paths created/modified.
   - Count of green TestEZ assertions.
   - Screenshots / console logs captured as evidence.
   - Key engineering lessons learned.
2. Commit the completed story work and push to GitHub (`origin/main`).
