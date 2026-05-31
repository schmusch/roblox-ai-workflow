# Dokumentations-Index & Quellenrangordnung

Willkommen in der zentralen Dokumentations-Steuerung dieses Projekts. Dieser Ordner dient als **Single Source of Truth (SSOT)** für dich und alle KI-Entwicklungssysteme.

## 🧭 Navigations-Index (Dateizuordnungen)

Jede Datei in diesem Verzeichnis hat eine dedizierte Funktion. Nutze die folgende Struktur, um dein Projekt sauber zu steuern:

| Ebene | Datei / Ordner | Beschreibung |
| :---: | :--- | :--- |
| **00** | [00.1_Game-Brief.md](00.1_Game-Brief.md) | **Spieldesign-Vision / GDD**: Core Loop, Zielgruppe, Monetarisierung und grober Rahmen. |
| **00** | [00.2_Blueprint.md](00.2_Blueprint.md) | **Technische Architektur**: Rojo-Projektstruktur, Server/Client-Grenzen, Remotes und Datenschemata. |
| **01** | [epics_and_stories.md](epics_and_stories.md) | **Produkt-Backlog**: Vollständige Zerlegung des Projekts in Epics und User Stories mit BDD-Kriterien. |
| **01** | [sprint-status.yaml](sprint-status.yaml) | **Sprint-Board**: Der einzige Status-Tracker für offene und fertige Stories. |
| **-** | [stories/](stories/) | **Entwicklungs-Stories**: Enthält die reichhaltigen Entwicklungsanleitungen für die KI. |
| **-** | [retrospectives/](retrospectives/) | **Sprint-Retrospektiven**: Protokolle zum Abschluss von Meilensteinen und zur Wissensextraktion. |
| **-** | [features/](features/) | **Zusatz-Features**: Enthält Feature Briefs und Blueprints aus der Ideen-Pipeline. |
| **-** | [_Archiv/](_Archiv/) | **Historisches Archiv**: Ort für veraltete oder projekt-spezifische Referenzen (z. B. frühere Prototypen oder Altsysteme). |

---

## ⚖️ Quellenrang (Source of Truth Hierarchy)

Sollte es zwischen verschiedenen Dateien zu inhaltlichen Widersprüchen kommen, gilt folgende feste Rangordnung:
1. **Der aktuelle Code + [docs/sprint-status.yaml](sprint-status.yaml)** = Absoluter Ist-Stand (Wahrheit bei Drift).
2. **[docs/epics_and_stories.md](epics_and_stories.md)** = Geplantes Soll-Verhalten (Backlog).
3. **[docs/00.1_Game-Brief.md](00.1_Game-Brief.md)** = Spieldesign-Vision & Player Fantasy.
4. **[docs/00.2_Blueprint.md](00.2_Blueprint.md)** = Technische Architektur.

> [!CAUTION]
> **Archivierte Dokumente**: Dateien im Ordner `_Archiv/` sind historisch und dürfen von KIs **NIEMALS** als aktuelle Vorgaben oder Wahrheit für Codeänderungen herangezogen werden!
