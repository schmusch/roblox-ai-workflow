# Roblox AI-Workflow — Claude Code Entry Point

This workspace is a **Single Source of Truth (SSOT)** for AI-assisted Roblox game development. It contains a curated skill set adapted from [JustineDevs/roblox-ai-os (RCS)](https://github.com/JustineDevs/roblox-ai-os) and rebuilt for Claude Code's native skill system.

The same `skills/` directory is consumed by Claude Code (this file), Gemini CLI (`GEMINI.md`), and Codex / generic agents (`AGENTS.md`). Skills are written platform-neutrally; only this file contains Claude Code-specific instructions.

## Kanonischer Doku-Index & KI-Einstieg

Bevor du mit einer Aufgabe startest oder Code generierst, konsultiere immer den aktuellen Dokumentations-Kanon unter:
- **[docs/README.md](docs/README.md)**: Der Doku-Map-Index mit allen Quellenregeln und Zuordnungen.
- **[docs/AI_HANDOFF.md](docs/AI_HANDOFF.md)**: Der dedizierte KI-Einstiegspunkt mit Vision, Feature-Ist-Stand, anstehenden Backlog-Punkten, Verifikationsgates und Roblox-MCP-Tipps.

### Quellenrang (Source of Truth Hierarchy)
Sollte es zwischen verschiedenen Dateien zu inhaltlichen Widersprüchen kommen, gilt folgende feste Rangordnung:
1. **Code + [docs/sprint-status.yaml](docs/sprint-status.yaml)** = Absoluter Ist-Stand (Wahrheit bei Drift).
2. **[docs/epics_and_stories.md](docs/epics_and_stories.md)** = Geplantes Soll-Verhalten (Backlog & Acceptance Criteria).
3. **[docs/00.1_Game-Brief.md](docs/00.1_Game-Brief.md)** = Spieldesign-Vision & Player Fantasy.
4. **[docs/00.2_Gods-and-Icons-Blueprint.md](docs/00.2_Gods-and-Icons-Blueprint.md)** = Technische Architektur.
5. **[docs/Spielmechanik_Uebersicht.md](docs/Spielmechanik_Uebersicht.md)** = Aktuelle Feature-Matrix.

> [!CAUTION]
> **Archivierte Dokumente**: Dateien im Ordner `docs/_Archiv/` sind historisch und dürfen NIEMALS als aktuelle Vorgaben oder Wahrheit für Codeänderungen herangezogen werden!

## Neue Ideen & Feature-Pipeline (Ideen-Handoff)

Wenn der User neue Spielideen einbringt (Trigger: *"Ich habe eine neue Idee: [Name]"* oder *"Lass uns ein Feature brainstormen: [Name]"*), **MUSST** du dieser strukturierten Pipeline autonom folgen:

1. **Phase A: Brainstorming & PRD**: Aktiviere `roblox-deep-interview`. Stelle sokratische Fragen zu Player Fantasy, Progression, Motivationen und Exploits. Erstelle anschließend das Feature-Briefing (PRD) unter `docs/features/[feature_name]_brief.md` (Nutze `roblox-forge-init` as template).
2. **Phase B: Architektur-Entwurf**: Aktiviere `roblox-blueprint`. Übersetze das Briefing in einen technischen Blueprint mit Remotes, Datenschemata und Rojo-Dateibaum unter `docs/features/[feature_name]_blueprint.md`.
3. **Phase C: Scrum-Board-Sync**: Aktiviere `roblox-scrum-create-epics`, um den Blueprint in konkrete Epics und Stories (mit Given-When-Then-Kriterien) zu zerlegen und in `docs/epics_and_stories.md` einzupflegen. Führe danach `roblox-scrum-planning` aus, um die Stories als `backlog` in `docs/sprint-status.yaml` einzusortieren.

Begleite den Creator im Chat auf Deutsch und führe ihn Schritt für Schritt durch diese Pipeline.

## What this workspace is for

Building Roblox experiences with disciplined AI assistance — from creator brief, to Roblox-native architecture, to verified Studio implementation. Default operating mode is:

```
roblox-brief  →  roblox-blueprint  →  roblox-forge
   (clarify)        (plan)              (build & verify)
```

For larger features that span multiple sessions, scaffold a PRD first with `roblox-forge-init` so context survives between sessions. The full sequence becomes:

```
roblox-forge-init        →  roblox-deep-interview / roblox-brief
       (PRD)                       (creator vision)
   →  roblox-blueprint    →  roblox-plan    →  roblox-forge / roblox-autopilot / roblox-ultrawork
        (architecture)         (sequence)         (execute)
```

For large, multi-epic projects managing long-term game development (the **BMAD SCRUM Workflow**):

```
roblox-scrum-create-epics ➔ roblox-scrum-planning ➔ roblox-scrum-create-story ➔ roblox-scrum-dev-story ➔ roblox-code-review ➔ roblox-scrum-retrospective
   (epic backlog)              (scrum board)           (rich story spec)         (TDD execution)         (quality gate)          (close epic)
```

Skip phases only when the user's input already satisfies them (e.g., a precise file-level fix can go straight to `roblox-forge`).

## How to invoke skills

Use the `Skill` tool. Skills live in `skills/<name>/SKILL.md`. Available skills are listed in system-reminders each session — only invoke names that appear there. The skill content is loaded into context when you invoke it; follow it directly.

When a user request maps to one of these skills, **invoke it before responding** (per `superpowers:using-superpowers`). Even a 1% match warrants invocation.

## The Roblox skill catalog

### Agile SCRUM Workflow (BMAD Method)
- **`roblox-scrum-create-epics`** — Transform GDD and Architecture specifications into detailed Epics and User Stories with BDD acceptance criteria.
- **`roblox-scrum-planning`** — Parse Roblox epics and compile the `sprint-status.yaml` board.
- **`roblox-scrum-create-story`** — Select the next backlog story, analyze GDD/architecture, previous stories, and generate a rich developer guide story spec.
- **`roblox-scrum-dev-story`** — Implement a story spec using TDD, StyLua, Rojo, and the Roblox Studio MCP.
- **`roblox-scrum-correct-course`** — Adjust sprint scopes, manage blockers, or redirect mid-sprint.
- **`roblox-scrum-retrospective`** — Close the sprint, audit stories, extract learnings, and close epics.
- **`roblox-scrum-dev-cycle`** — Run a complete end-to-end SCRUM development cycle (Planning ➔ Story Creation ➔ TDD Dev ➔ Code Review) autonomously.

### Workflow backbone (use in order)
- **`roblox-brief`** — Clarify creator intent (genre, audience, scale, multiplayer, monetization) before any planning.
- **`roblox-blueprint`** — Turn an approved brief into a Roblox-native architecture plan (services, ownership boundaries, data shape, verification path).
- **`roblox-forge`** — Carry an approved blueprint to verified completion via the Roblox Studio integration.

### Brief deepening
- **`roblox-deep-interview`** — Long-form Socratic requirements gathering for complex briefs (deeper than `roblox-brief`).
- **`roblox-brief-audience`** — Build a target-audience profile (age, region, session length, social context).
- **`roblox-brief-motivation`** — Identify which player drivers (Progression/Status/FOMO/Mastery/Community) the experience should lean on.

### Blueprint deepening
- **`roblox-blueprint-psychology`** — Apply the 5-driver psychology framework as a design lens.
- **`roblox-blueprint-loops`** — Design reward, daily, and event loops as composable specs.
- **`roblox-blueprint-retention`** — Build D1/D7/D30 retention plans with explicit fail-states.
- **`roblox-blueprint-social`** — Design social mechanics (parties, guilds, trading, co-op) with anti-abuse guardrails.

### Forge psychology execution loops
- **`roblox-forge-progression`** — Implement XP, levels, rebirth, prestige.
- **`roblox-forge-status`** — Implement cosmetics, leaderboards, titles, showcase slots.
- **`roblox-forge-fomo`** — Implement timed events, rotating shops, seasonal ladders.
- **`roblox-forge-mastery`** — Implement combos, build paths, skill expression systems.
- **`roblox-forge-community`** — Implement guilds, trading, co-op, invites.
- **`roblox-forge-daily-loop`** — Implement daily login chains and streaks.
- **`roblox-forge-event-loop`** — Implement event arcs (start/peak/sunset).
- **`roblox-forge-reward-loop`** — Implement reward schedules with anti-burnout guardrails.

### Process & planning
- **`roblox-forge-init`** — Scaffold a PRD doc for a new feature so context survives across sessions.
- **`roblox-plan`** — Multi-step implementation plan with Planner/Architect/Critic consensus loop.
- **`roblox-analyze`** — Read-only deep analysis of a codebase / place; ranked synthesis of architecture, hotspots, risks.
- **`roblox-deepsearch`** — Doc-grounded research via Creator Docs, DevForum, Wally registry, repo grep.
- **`roblox-tdd`** — Red-green-refactor cycles for Luau via TestEZ or Jest-Roblox.
- **`roblox-build-fix`** — Systematic debugging for Rojo / Wally / Selene / StyLua / Luau-LSP / TestEZ failures.
- **`roblox-git-master`** — Roblox-aware git workflows (Wally lock, Rojo manifest, place file conventions).
- **`roblox-ask-other-model`** — Cross-LLM consultation when running multi-model setups.

### Multi-agent execution
- **`roblox-team`** — Coordinate parallel agents on independent slices of a plan (consolidates crew/swarm/worker).
- **`roblox-autopilot`** — Long-running autonomous execution of an approved plan with minimal user checkpoints.
- **`roblox-ultrawork`** — Forge with extreme verification — every step gets full ultraqa + adversarial proof. For monetization / persistence / competitive surfaces.

### Quality & cross-cutting
- **`roblox-code-review`** — Roblox-flavored code review (server-authority audit, anti-slop pass, replication audit).
- **`roblox-security-review`** — Exploit-vector audit (remotes, persistence, trade, marketplace receipts, rate-limits).
- **`roblox-ultraqa`** — Verification before completion via runtime evidence (in-Studio probes, adversarial inputs).
- **`roblox-anti-slop`** — Strip enterprise jargon (`Controller`/`Repository`/`DTO`/`Service`) out of Luau code.
- **`roblox-visual-verdict`** — Compare Studio screenshots against a reference image; emit structured pass/fail.
- **`roblox-pre-action`** — Pre-action gate: classify task, list services involved, define file tree before code generation.
- **`roblox-studio-bridge`** — Patterns for using the Roblox Studio MCP (script_read, multi_edit, execute_luau, screen_capture).

## Documented but not a skill

- **End-to-end automation** (`brief → blueprint → forge` in one go) — this is just the default backbone sequence. Use `roblox-autopilot` once a plan exists. No separate skill needed.
- **Generic AI-slop cleanup** — covered by `roblox-anti-slop`; the Luau / Roblox specifics are the value; there is no useful "generic-only" mode.

## Roblox-native guardrails (always apply)

These are non-negotiable invariants. Skills assume them; do not violate them.

### Server authority
- **Clients request. Server validates. Server mutates canonical state.**
- Never trust client-sent payloads for economy, inventory, combat damage, or persistence.
- RemoteEvents and RemoteFunctions must validate every parameter on the server side.
- DataStore writes happen only from `ServerScriptService` after server validation.

See `references/server-authority-rules.md` and `references/roblox-security-audit-checklist.md`.

### Roblox vocabulary, not enterprise jargon
Prefer engine concepts over generic software jargon. See `references/roblox-vocabulary.md` for the full list. Quick reference:

| ❌ Avoid (enterprise) | ✅ Use (Roblox-native) |
|----------------------|------------------------|
| `Controller`, `Service`, `Repository`, `DTO` | `ModuleScript`, `Service` (engine service), `DataStoreService` |
| `Middleware chain`, `Pipeline` | Server-side validation, RemoteEvent handler |
| `Microservice`, `API gateway` | `MessagingService`, `TeleportService` |
| `Manager`, `Handler` (when vague) | Concrete name: `InventoryModule`, `TradeRemote` |
| `BaseClass`, `AbstractFactory` | Plain ModuleScript table, typed Luau |

### Standard places things live
- **`ServerScriptService`** — server-only authority logic
- **`ReplicatedStorage`** — shared ModuleScripts, remote events, configs, assets clients may need
- **`StarterPlayer/StarterPlayerScripts`** — local-only client scripts
- **`StarterGui`** — UI templates replicated to each player
- **`Workspace`** — runtime instances; not for code storage

### Verification before completion
- Do not claim work is "done" from static inspection alone when runtime behavior depends on replication, remotes, or DataStore.
- Use `roblox-ultraqa` (or `superpowers:verification-before-completion`) to capture runtime evidence.
- Use `roblox-studio-bridge` patterns to actually run/inspect when possible: `execute_luau` for quick checks, `script_read` to verify the written file matches intent, `screen_capture` for visual changes.
- Evidence before assertions, always.

## MCP integrations available

This environment has powerful MCPs. Use them when they fit:

- **`mcp__Roblox_Studio__*`** — direct Roblox Studio integration. Key tools:
  - `script_read`, `script_search`, `script_grep` — inspect Luau code in the open place
  - `multi_edit` — batch script edits
  - `execute_luau` — run code in Studio (server or client context)
  - `inspect_instance`, `search_game_tree` — walk the DataModel
  - `screen_capture`, `get_console_output` — visual + runtime evidence
  - `insert_from_creator_store`, `search_creator_store` — find assets
  - `generate_material`, `generate_mesh`, `generate_procedural_model` — AI asset generation
  - `start_stop_play` — toggle Play Solo
  - `list_roblox_studios`, `set_active_studio` — pick which Studio to act on
- **`plugin:context7:context7`** — fetch up-to-date docs for Roblox APIs, Wally packages, etc. Prefer over web search for library docs.
- **`mcp__Claude_in_Chrome__*`** — browse Roblox docs / DevForum / creator hub when needed.
- **`mcp__c0127c3f-...__notion-*`** — log GDDs, briefs, blueprints, PRDs to Notion if the user uses it.

Always check `mcp__Roblox_Studio__list_roblox_studios` first if multiple Studios may be open; ask the user which to target if ambiguous.

## Companion superpowers (still useful alongside)

Phase 2 closed the SSOT-parity gap, but Claude Code's native `superpowers:*` family is still excellent for non-Roblox or cross-cutting work:

| Need | Roblox skill | Generic alternative |
|------|--------------|---------------------|
| Brainstorming | `roblox-deep-interview`, `roblox-brief` | `superpowers:brainstorming` |
| TDD | `roblox-tdd` | `superpowers:test-driven-development` |
| Plans | `roblox-plan` | `superpowers:writing-plans` |
| Debugging | `roblox-build-fix` (toolchain), runtime issues | `superpowers:systematic-debugging` |
| Verification | `roblox-ultraqa` | `superpowers:verification-before-completion` |
| Parallel sub-agents | `roblox-team` | `superpowers:dispatching-parallel-agents` |
| Code review | `roblox-code-review` | `superpowers:requesting-code-review` |

The Roblox-flavored skills add Roblox-specific gates (server-authority, replication, anti-slop, Studio-MCP usage) on top of the generic discipline.

## Operating defaults

- **Language:** Skill content is English (matches Roblox terminology). User chats in German — respond in German unless asked otherwise.
- **Platform:** Windows 11. Avoid POSIX-only commands in suggestions; use PowerShell or path-portable Node/Lune scripts.
- **Tool stack assumption:** Modern Rojo + Wally + StyLua + Selene is fine but not required; skills work for any layout. Detect and follow existing conventions. Toolchain reference: `references/roblox-build-toolchain.md`.
- **Server authority is not optional.** If a request implies client-trusted state mutation, push back before implementing.
- **No git push / external publish** unless explicitly requested.
