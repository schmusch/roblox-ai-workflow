---
name: roblox-scrum-retrospective
description: 'Closes a sprint, audits completed stories, evaluates key learnings, and marks epics as done. Use when the user says "run retrospective", "close sprint", or "end epic [num]".'
domain: process
audience: creator
artifact-type: skill
---

# Roblox Scrum: Retrospective Workflow

**Goal:** Formally close out completed epics/sprints, compile engineering learnings, audit quality, and update statuses to keep the workspace clean and optimized.

**Your Role:** Scrum Master / QA Product Owner.

---

## Operating Guidelines

- **Language:** German for user communications and retrospective outputs. English for technical keys.
- **Paths**:
  - `sprint_status` = `docs/sprint-status.yaml`
  - `retrospectives_folder` = `docs/retrospectives`
  - `stories_folder` = `docs/stories`

---

## Workflow Steps

### Step 1: Audit Completed Stories
1. Elicit from the user which Epic (e.g. Epic 1) is being reviewed.
2. Scan `{sprint_status}` for all stories associated with that epic (e.g. keys starting with `1-X-`).
3. Verify that all of these stories are marked as `done` in the YAML file. If any story is not `done`, compile a list of pending tasks and raise a blocker or complete them first.

### Step 2: Compile Retrospective Document
1. Gather engineering metrics:
   - Total lines of Luau code added/modified (approximate).
   - TestEZ coverage and test count.
   - List of Wally packages integrated.
   - Review findings resolved during the sprint.
2. Scrape Dev Notes and Dev Agent Records from each completed story in `{stories_folder}` to extract **Critical Learnings**:
   - What went well?
   - What caused debugging circles or LLM issues (e.g. Rojo sync delays, type mismatch, replication delay)?
   - Which code patterns (e.g. dynamic cameras, data structures, remote listeners) must be carried over as standards?
3. Create the retrospective file: `{retrospectives_folder}/epic-{epic_num}-retro-{{date}}.md`.

#### **Retrospective File Template**:
```markdown
# Retrospektive: Epic {{epic_num}} - {{epic_title}}

**Datum**: {{date}}
**Entwickler-Agent**: {{agent_model_name_version}}

## 📊 Sprint Metriken
- Erstellte Stories: ...
- Durchgeführte TestEZ Tests: ...
- Neue Wally-Pakete: ...

## 🚀 Was lief gut?
- ...

## ⚠️ Stolpersteine & LLM-Fehltritte
- ...

## 💡 Technische Erkenntnisse für zukünftige Epics
- [Cites to specific file locations and patterns]
```

### Step 3: Close Epic Status & Sync Docs
1. Update `{sprint_status}`:
   - Change `epic-{epic_num}` status to `done`.
   - Change `epic-{epic_num}-retrospective` status to `done`.
   - Update `last_updated` date.
2. **Technical Architecture Sync**: Review the compiled retrospective learnings and touched files. If any permanent architectural changes, new core services, data schemas, or structural guidelines were established during the sprint, the agent MUST update `docs/00.2_Gods-and-Icons-Blueprint.md` (Blueprint) or `docs/00.1_Game-Brief.md` (Brief) directly to prevent documentation drift.
3. Log this milestone in the global Project Hub (`00_Roblox-Game-Dev Hub.md`) under the `## 📜 Log` section, adding at least 2 inline wikilinks.
4. Present the compiled retrospective to the user in German, highlighting the top three technical rules established for the next sprint.
