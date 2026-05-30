# Roblox AI-Workflow — Gemini CLI Entry Point

This workspace is a **Single Source of Truth (SSOT)** for AI-assisted Roblox game development. The canonical skill content lives in `skills/<name>/SKILL.md` and is shared with Claude Code (`CLAUDE.md`) and Codex / generic agents (`AGENTS.md`).

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

1. **Phase A: Brainstorming & PRD**: Aktiviere `roblox-deep-interview`. Stelle sokratische Fragen zu Player Fantasy, Progression, Motivationen und Exploits. Erstelle anschließend das Feature-Briefing (PRD) unter `docs/features/[feature_name]_brief.md` (Nutze `roblox-forge-init` als Schablone).
2. **Phase B: Architektur-Entwurf**: Aktiviere `roblox-blueprint`. Übersetze das Briefing in einen technischen Blueprint mit Remotes, Datenschemata und Rojo-Dateibaum unter `docs/features/[feature_name]_blueprint.md`.
3. **Phase C: Scrum-Board-Sync**: Aktiviere `roblox-scrum-create-epics`, um den Blueprint in konkrete Epics und Stories (mit Given-When-Then-Kriterien) zu zerlegen und in `docs/epics_and_stories.md` einzupflegen. Führe danach `roblox-scrum-planning` aus, um die Stories als `backlog` in `docs/sprint-status.yaml` einzusortieren.

Begleite den Creator im Chat auf Deutsch und führe ihn Schritt für Schritt durch diese Pipeline.

## Skill activation

Use the `activate_skill` tool to load a skill from `skills/<name>/SKILL.md`. Skill frontmatter follows the Anthropic Skill convention (`name`, `description`) which Gemini CLI's skill loader supports.

If `activate_skill` is unavailable for any reason, read the skill file directly and follow its instructions.

## Tool name mapping (Claude Code → Gemini equivalents)

Skills are written in platform-neutral language. Where they reference generic actions, use the Gemini equivalent:

| Generic action in skill | Gemini CLI tool |
|-------------------------|-----------------|
| "read the file" | `read_file` |
| "edit the file" | `replace` / `write_file` |
| "search the codebase" | `search_file_content`, `glob` |
| "run the command" | `run_shell_command` |
| "use available Roblox Studio integration" | `mcp__Roblox_Studio__*` (if configured) |
| "fetch up-to-date docs" | `web_fetch`, context7 MCP if available |

See `CLAUDE.md` for the full skill catalog, Roblox-native guardrails, and operating defaults — those apply identically here.

## Operating defaults

- **Language:** Skill content is English. User chats in German — respond in German unless asked otherwise.
- **Platform:** Windows 11. Avoid POSIX-only commands.
- **Server authority is not optional.** Clients request, server validates, server mutates.

## Companion skills

The SSOT now has **full Phase-2 parity** — generic workflow / quality discipline that Claude Code gets from `superpowers:*` is available here as portable `roblox-*` skills:

| Need | Skill |
|------|-------|
| Deep requirements / brainstorming | `roblox-deep-interview` (deep) or `roblox-brief` (light) |
| TDD (red-green-refactor) | `roblox-tdd` |
| Multi-step plan with consensus loop | `roblox-plan` |
| Read-only codebase analysis | `roblox-analyze` |
| Doc-grounded research | `roblox-deepsearch` |
| Toolchain debugging (Rojo/Wally/Selene/Luau-LSP) | `roblox-build-fix` |
| Git workflow (Wally lock, Rojo manifest, place file) | `roblox-git-master` |
| Parallel sub-agents | `roblox-team` |
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

Skill content is identical across platforms — only the tool invocations differ (see the tool-mapping table above).
