# 🚀 Roblox AI-Assisted Game Development Workflow

Willkommen im **Roblox AI-Assisted Game Development Workflow**. Dies ist ein strukturiertes, hochdiszipliniertes Framework zur Zusammenarbeit zwischen menschlichen Creatoren und KI-Entwicklungssystemen (wie Claude Code, Gemini CLI und autonomen Codierungs-Agenten).

Das Ziel dieses Frameworks ist es, eine **Single Source of Truth (SSOT)** zu etablieren, um Dokumentendrift zu verhindern, serverseitige Sicherheit standardmäßig zu erzwingen und die Qualität der Implementierung durch Test-Driven Development (TDD) abzusichern.

---

## 📂 Ordnerstruktur & Dokumenten-Architektur

Die Struktur dieses Repositories trennt Planungsdaten, KI-Fähigkeiten (Skills) und die eigentliche Codebasis:

```text
[Root]
 ├── Place1.rbxl            # Die primäre Roblox Studio Place-Datei
 ├── CLAUDE.md              # Claude Code Einstiegspunkt (AI SSOT)
 ├── GEMINI.md              # Gemini CLI Einstiegspunkt (AI SSOT)
 ├── AGENTS.md              # Universeller Einstiegspunkt für KI-Agenten
 ├── README.md              # Dieses Entwickler-Portal & Navigation
 ├── 📁 docs/                  # Zentraler Spieldesign- & Planungsordner (Vorlagen)
 │    ├── 📄 00.1_Game-Brief.md  # Vision, Core Loop & MVP-Umfang
 │    ├── 📄 00.2_Blueprint.md   # Technische Architektur & Netzwerk-Grenzen
 │    ├── 📄 epics_and_stories.md# Produkt-Backlog: Epics & User Stories
 │    ├── 📄 sprint-status.yaml  # Sprint-Board & agile Status-Verfolgung
 │    ├── 📄 AI_HANDOFF.md       # Übergabe-Protokoll & aktueller Feature-Stand
 │    ├── 📁 stories/            # Detail-Spezifikationen für Entwicklungs-Stories
 │    ├── 📁 retrospectives/     # Protokolle zum Abschluss von Sprints
 │    ├── 📁 features/           # Feature Briefs für zukünftige Meilensteine
 │    └── 📁 _Archiv/            # Historische Referenzen (z. B. Best Practices)
 ├── 📁 skills/                # SSOT - Roblox-spezifische KI-Fähigkeiten (Skills)
 ├── 📁 references/            # Geteilte Referenzen (Vokabular, Security)
 └── 📁 src/                   # Die Rojo-Codebasis (Client, Server, Shared)
```

---

## 🤖 AI-Workflow & Copilot Integration

Dieses Repository nutzt einen klar definierten, phasenbasierten Entwicklungsprozess, der durch die Skills in `skills/` gesteuert wird.

### ⚙️ Der Standard-Workflow (Canonical Loop)
1. **`roblox-brief`**: Der Creator definiert die Vision und den MVP-Rahmen in `docs/00.1_Game-Brief.md`.
2. **`roblox-blueprint`**: Die technische Struktur, Rojo-Mappings, Datenschemata und Remotes werden in `docs/00.2_Blueprint.md` definiert.
3. **`roblox-scrum-create-epics`**: Die KI zerlegt die Spezifikationen in modulare Epics und User Stories mit BDD-Kriterien in `docs/epics_and_stories.md`.
4. **`roblox-scrum-planning`**: Der Sprint wird initialisiert und das Sprint-Board in `docs/sprint-status.yaml` aufgebaut.
5. **`roblox-scrum-dev-story`**: Eine Story wird im strikten Test-Driven Development (TDD) Modus implementiert.
6. **`roblox-scrum-retrospective`**: Am Sprintende wird das Gelernte analysiert und das Dokumentations-Set aktualisiert.

---

## ⚖️ Quellenrang (Source of Truth Hierarchy)

Sollte es zwischen verschiedenen Dateien zu inhaltlichen Widersprüchen kommen, gilt folgende feste Rangordnung:
1. **Der aktuelle Code + [docs/sprint-status.yaml](docs/sprint-status.yaml)** = Absoluter Ist-Stand (Wahrheit bei Drift).
2. **[docs/epics_and_stories.md](docs/epics_and_stories.md)** = Geplantes Soll-Verhalten (Backlog).
3. **[docs/00.1_Game-Brief.md](docs/00.1_Game-Brief.md)** = Spieldesign-Vision & Player Fantasy.
4. **[docs/00.2_Blueprint.md](docs/00.2_Blueprint.md)** = Technische Architektur.

> [!CAUTION]
> **Archivierte Dokumente**: Dateien im Ordner `docs/_Archiv/` (z. B. das historische "Gods & Icons" Projekt) sind historische Referenzen und dienen rein als architektonische Anschauungsobjekte (Best Practices). Sie dürfen von KIs **NIEMALS** als aktuelle Vorgaben für Codeänderungen herangezogen werden!

---

## 🏛️ Best Practice Referenz: Gods & Icons

Im Ordner `docs/_Archiv/gods-and-icons/` findest du die vollständige Dokumentation und die technischen Systementwürfe des Projekts **„Gods & Icons: Tactical Tycoon & Creed“**. 
Es dient als perfektes Architektur-Beispiel für:
* **Server-Authoritative Wirtschaftssysteme** (Cheat-sichere Platzierungsprüfungen)
* **Zero-Allocation Latency Rollback-Netcode** unter Verwendung der Luau `buffer`-Bibliothek
* **Zero-Allocation Bitwise Koordinaten-Indexing** für Voxel-Welten
* **Professionelles Test-Driven Development (TDD)** mit TestEZ
