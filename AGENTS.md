# Roblox AI-Workflow — Generic Agents Entry Point (Codex / others)

This file is the entry point for Codex CLI and any other agentic platform that reads `AGENTS.md`. The canonical skill content lives in `skills/<name>/SKILL.md` and is shared with Claude Code (`CLAUDE.md`) and Gemini CLI (`GEMINI.md`).

## Kanonischer Doku-Index & KI-Einstieg

Bevor du mit einer Aufgabe startest oder Code generierst, konsultiere immer den aktuellen Dokumentations-Kanon unter:
- **[docs/README.md](docs/README.md)**: Der Doku-Map-Index mit allen Quellenregeln und Zuordnungen.
- **[docs/AI_HANDOFF.md](docs/AI_HANDOFF.md)**: Der dedizierte KI-Einstiegspunkt mit Vision, Feature-Ist-Stand, anstehenden Backlog-Punkten, Verifikationsgates und Roblox-MCP-Tipps.

### Quellenrang (Source of Truth Hierarchy)
Sollte es zwischen verschiedenen Dateien zu inhaltlichen Widersprüchen kommen, gilt folgende feste Rangordnung:
1. **Code + [docs/sprint-status.yaml](docs/sprint-status.yaml)** = Absoluter Ist-Stand (Wahrheit bei Drift).
2. **[docs/epics_and_stories.md](docs/epics_and_stories.md)** = Geplantes Soll-Verhalten (Backlog & Acceptance Criteria).
3. **[docs/00.1_Game-Brief.md](docs/00.1_Game-Brief.md)** = Spieldesign-Vision & Player Fantasy.
4. **[docs/00.2_Blueprint.md](docs/00.2_Blueprint.md)** = Technische Architektur.
5. **[docs/Spielmechanik_Uebersicht.md](docs/Spielmechanik_Uebersicht.md)** = Aktuelle Feature-Matrix.

> [!CAUTION]
> **Archivierte Dokumente**: Dateien im Ordner `docs/_Archiv/` sind historisch und dürfen NIEMALS als aktuelle Vorgaben oder Wahrheit für Codeänderungen herangezogen werden!

## Neue Ideen & Feature-Pipeline (Ideen-Handoff)

Wenn der User neue Spielideen einbringt (Trigger: *"Ich habe eine neue Idee: [Name]"* oder *"Lass uns ein Feature brainstormen: [Name]"*), **MUSST** du dieser strukturierten Pipeline autonom folgen:

1. **Phase A: Brainstorming & PRD**: Aktiviere `roblox-deep-interview`. Stelle sokratische Fragen zu Player Fantasy, Progression, Motivationen und Exploits. Erstelle anschließend das Feature-Briefing (PRD) unter `docs/features/[feature_name]_brief.md` (Nutze `roblox-forge-init` als Schablone).
2. **Phase B: Architektur-Entwurf**: Aktiviere `roblox-blueprint`. Übersetze das Briefing in einen technischen Blueprint mit Remotes, Datenschemata und Rojo-Dateibaum unter `docs/features/[feature_name]_blueprint.md`.
3. **Phase C: Scrum-Board-Sync**: Aktiviere `roblox-scrum-create-epics`, um den Blueprint in konkrete Epics und Stories (mit Given-When-Then-Kriterien) zu zerlegen und in `docs/epics_and_stories.md` einzupflegen. Führe danach `roblox-scrum-planning` aus, um die Stories als `backlog` in `docs/sprint-status.yaml` einzusortieren.

Begleite den Creator im Chat auf Deutsch und führe ihn Schritt für Schritt durch diese Pipeline.

## How to use skills here

Skills are plain Markdown files with YAML frontmatter. There is no "Skill tool" required — read them directly, and follow the instructions as you would any prompt fragment.

When the user's request matches a skill's `description`, load that file and apply it. Skill names are namespaced `roblox-*` to avoid collision with other prompt libraries.

## Canonical workflow

```
roblox-brief  →  roblox-blueprint  →  roblox-forge
```

Skip phases only when the user's input already satisfies them. See `CLAUDE.md` for the full skill catalog with one-line descriptions.

## Roblox-native guardrails (always apply)

- **Server authority:** clients request, server validates, server mutates. Never trust client-sent payloads.
- **Roblox vocabulary:** prefer `ModuleScript`, `RemoteEvent`, `DataStoreService`, `CollectionService` over generic `Controller`/`Service`/`Repository`/`DTO`. See `references/roblox-vocabulary.md`.
- **Standard places:** `ServerScriptService` for authority logic, `ReplicatedStorage` for shared, `StarterPlayerScripts` for client-only, `StarterGui` for UI templates.
- **Verification:** evidence before assertions. Do not claim "done" from static inspection alone when runtime behavior depends on replication, remotes, or DataStore.

## MCP integrations

If the host platform has the Roblox Studio MCP configured, prefer its tools for direct Studio inspection / mutation. Otherwise, work from the codebase and ask the user to verify in Studio. See `references/studio-mcp-cheatsheet.md`.

## Operating defaults

- **Language:** Skill content is English (matches Roblox terminology). User's primary language is German — respond in German unless asked otherwise.
- **Platform:** Windows 11. Avoid POSIX-only commands.
- **No remote git operations** unless explicitly requested.

## Phase 2 skills (built — full SSOT parity)

Generic-but-portable workflow / quality skills are now available as `roblox-*` so Codex and other platforms without a native `superpowers:*` family get the same discipline:

| Need | Skill |
|------|-------|
| Deep requirements / brainstorming | `roblox-deep-interview` (deep) or `roblox-brief` (light) |
| TDD (red-green-refactor) | `roblox-tdd` |
| Multi-step plan with consensus loop | `roblox-plan` |
| Read-only codebase analysis | `roblox-analyze` |
| Doc-grounded research | `roblox-deepsearch` |
| Toolchain debugging (Rojo / Wally / Selene / Luau-LSP) | `roblox-build-fix` |
| Git workflow (Wally lock, Rojo manifest, place file) | `roblox-git-master` |
| Parallel sub-agents on independent slices | `roblox-team` |
| Long-running autonomous execution | `roblox-autopilot` |
| Extreme verification (monetization / persistence / PvP) | `roblox-ultrawork` |
| Code review with Roblox-specific gates | `roblox-code-review` |
| Exploit-vector security audit | `roblox-security-review` |
| Runtime verification before completion | `roblox-ultraqa` |
| Cross-LLM consultation | `roblox-ask-other-model` |
| PRD scaffold for a new feature | `roblox-forge-init` |
| **Roblox Epic & Story Scaffolding (BMAD)** | `roblox-scrum-create-epics` |
| **Agile SCRUM Planning (BMAD)** | `roblox-scrum-planning` |
| **Roblox Context-Rich Story Spec** | `roblox-scrum-create-story` |
| **TDD Story Dev in Roblox Studio** | `roblox-scrum-dev-story` |
| **Sprint Course Correction** | `roblox-scrum-correct-course` |
| **Sprint Retrospective** | `roblox-scrum-retrospective` |
| **Complete End-to-End Dev Cycle** | `roblox-scrum-dev-cycle` |

All skill content is platform-neutral; read the SKILL.md and follow the instructions directly.
