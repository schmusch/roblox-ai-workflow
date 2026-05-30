# 🏛️ Gods & Icons: Tactical Tycoon & Creed

Willkommen im offiziellen Entwickler-Portal und der System-Dokumentation für **Gods & Icons**. Dieses Repository enthält die vollständige konzeptionelle und technische Planung für ein hochgradig optimiertes, cheat-resistentes Roblox-Erlebnis der nächsten Generation (optimiert für das lukrative US-18+-Premium-DevEx-Segment).

Dieses Projekt nutzt ein fortschrittliches **Roblox AI-Workflow System (SSOT)**, um eine reibungslose und hocheffiziente Entwicklung in Zusammenarbeit mit KI-Assistenten (wie Claude Code, Gemini CLI und Codex) zu garantieren.

---

## 🌌 Core Game Loop & Experience

**Gods & Icons** verbindet das tiefe, optimierende Gameplay eines brutalistischen Tycoons mit der taktischen Tiefe eines latenz-kompensierten 3x3 Auto-Battlers:
* **Die Zitadelle (Tycoon):** Spieler errichten Monumente und Andachtsstätten auf einem zellularen Gitter, um Glauben (`Belief`) zu erzeugen, während sie metaphysische Risse und Daten-Glitches in Schach halten.
* **Der Glaubenskrieg (Auto-Battler):** Formlose, metaphysische Gottheiten (Alte Götter aus Stein vs. Neue Götter aus Chrom) treten in taktischen Rastern gegeneinander an. Die Spieler greifen durch mächtige, latenz-kompensierte Interventionen aktiv ein.

---

## 🤖 AI-Workflow & Copilot Integration (SSOT)

Dieses Repository ist als **Single Source of Truth (SSOT)** für KI-gestützte Entwicklung konzipiert. Es enthält vordefinierte Fähigkeiten ("Skills") und Entwicklungsrichtlinien, die von KIs direkt gelesen und ausgeführt werden können:

* **[CLAUDE.md](CLAUDE.md):** Einstiegspunkt und Skill-Katalog für **Claude Code**.
* **[GEMINI.md](GEMINI.md):** Einstiegspunkt und Skill-Katalog für **Gemini CLI**.
* **[AGENTS.md](AGENTS.md):** Universeller Einstiegspunkt für **Codex** und andere LLM-Agenten.

### ⚙️ Kern-Arbeitsablauf (Canonical Workflow)
```
roblox-brief  →  roblox-blueprint  →  roblox-forge
```
KIs folgen diesem Dreischritt (Anforderungsanalyse → Technische Spezifikation → Implementierung), um höchste Softwarequalität und absolute Übereinstimmung mit dem Spieldesign sicherzustellen.

---

## 📂 Workspace Map & Documentation Portal

Die Verzeichnisstruktur vereint Spieldateien, systematische Spieldesign-Dokumente und die AI-Workflow-Infrastruktur:

```
[Root]
 ├── 📄 Place1.rbxl            # Die primäre Roblox Studio Place-Datei
 ├── 📄 CLAUDE.md              # Claude Code Einstiegspunkt (AI SSOT)
 ├── 📄 GEMINI.md              # Gemini CLI Einstiegspunkt (AI SSOT)
 ├── 📄 AGENTS.md              # Codex/Agenten Einstiegspunkt (AI SSOT)
 ├── 📄 README.md              # Dieses Entwickler-Portal & Navigation
 ├── 📁 docs/                  # Zentraler Spieldesign- & Planungsordner
 │    ├── 📄 00.1_Game-Brief.md
 │    ├── 📄 00.2_Gods-and-Icons-Blueprint.md
 │    ├── 📁 01_GDD-Basis/      # Ebene 01 - Spieldesign & Ökonomie
 │    ├── 📁 02_Spezifikationen/# Ebene 02 - Technische Spezifikationen
 │    └── 📁 03_Analysen-Audits/# Ebene 03 - System-Audits & Marktanalysen
 ├── 📁 skills/                # SSOT - 36 Roblox-spezifische KI-Fähigkeiten
 ├── 📁 references/            # Geteilte Referenzen (Vokabular, Sicherheit, etc.)
 └── 📁 plans/                 # Technische Implementierungspläne der KI
```

---

## 🧭 Navigations- & Leseempfehlung (Spieldokumente)

Nutze die folgende Tabelle, um direkt in die Teildomänen einzusteigen. Jedes Dokument ist vollständig verlinkt und kurz beschrieben:

| Ebene | Datei | Beschreibung | Kerninhalte |
| :---: | :--- | :--- | :--- |
| **00** | [00.1_Game-Brief.md](docs/00.1_Game-Brief.md) | **Projekt-Zusammenfassung** | Core Loop, Zielgruppe (US 18+), Monetarisierungs-Konzept, grober Rahmen. |
| **00** | [00.2_Gods-and-Icons-Blueprint.md](docs/00.2_Gods-and-Icons-Blueprint.md) | **Technische Architektur** | Server/Client Ownership Matrix, Datei-Layout, Luau-Typen, Remote-Protokolle. |
| **01** | [01.1_Goetter-Design-Framework.md](docs/01_GDD-Basis/01.1_Goetter-Design-Framework.md) | **Visuelles Framework** | Ästhetischer Kontrast (Pantheon-Noir), R15-Rig-Anpassung, SLIM-LOD-System. |
| **01** | [01.2_Goetter-Tempel-Wirtschaft.md](docs/01_GDD-Basis/01.2_Goetter-Tempel-Wirtschaft.md) | **Tycoon-System** | Asymmetrische Wirtschaft, zellulares Gitter, Glaubensgenerierung, Katastrophen. |
| **01** | [01.3_Goetter-Kampf-Framework.md](docs/01_GDD-Basis/01.3_Goetter-Kampf-Framework.md) | **Kampfsystem** | 3x3 Auto-Battler, Einheiten-Rollen, euklidisches Targeting, Interventionen. |
| **01** | [01.4_Goetter-Evolution.md](docs/01_GDD-Basis/01.4_Goetter-Evolution.md) | **Progressions-Loop** | Prestige-System (Rebirth), Sakrale Fusion (Breeding), Gacha-Pity-System. |
| **01** | [01.5_Monetarisierung-Viralitaet.md](docs/01_GDD-Basis/01.5_Monetarisierung-Viralitaet.md) | **Wirtschaft & Social** | Fair-Play VIP-Server, Roblox Moments Integration, Sharing-Richtlinien. |
| **02** | [02.1_Spieldesign-Spielerpsychologie-Optimierung.md](docs/02_Spezifikationen/02.1_Spieldesign-Spielerpsychologie-Optimierung.md) | **Spielerpsychologie Spec** | Mastery/Progression/Status Motivationsschleifen, Burnout-Guardrails, Recovery-Pfade. |
| **02** | [02.2_Server-Authoritative-Tempel-Wirtschaft-Spezifikation.md](docs/02_Spezifikationen/02.2_Server-Authoritative-Tempel-Wirtschaft-Spezifikation.md) | **Netzwerk & Grid Spec** | Anti-Cheat Remote-Validierung, geometrische Kollisionsprüfung, Speicheroptimierung. |
| **02** | [02.3_Zero-Allocation-Latency-Rollback-Spezifikation.md](docs/02_Spezifikationen/02.3_Zero-Allocation-Latency-Rollback-Spezifikation.md) | **Combat Performance Spec** | Binärer Ringpuffer mit Luau `buffer`, Latenz-Prediction und 90-Frame-Rollback. |
| **02** | [02.4_TDD-Framework-Toolchain-Spezifikation.md](docs/02_Spezifikationen/02.4_TDD-Framework-Toolchain-Spezifikation.md) | **TDD- & Tooling-Setup** | TestEZ-Unit-Tests, Rojo-Projektmapping, Wally-Bibliotheksverwaltung. |
| **03** | [03.1_Roblox-Spielentwicklung-Marktanalyse-Strategie.md](docs/03_Analysen-Audits/03.1_Roblox-Spielentwicklung-Marktanalyse-Strategie.md) | **Marktanalyse** | DevEx US-Ages-18+-Analyse (42%-Marge), KPI-Tracking, Release-Strategie. |
| **03** | [03.2_Comprehensive-Architecture-Audit.md](docs/03_Analysen-Audits/03.2_Comprehensive-Architecture-Audit.md) | **Architektur-Tiefenaudit** | Aufdeckung mathematischer Schwachstellen, Speicherlecks und Behebung kritischer Bugs. |
| **03** | [03.3_GDD-AI-OS-Alignment-Audit.md](docs/03_Analysen-Audits/03.3_GDD-AI-OS-Alignment-Audit.md) | **Brücke GDD & Technik** | Validierungs-Matrix, Anti-Cheat-Absicherung, Code- und Test-Blueprints. |
| **03** | [03.4_Goetter-Framework-Analyse.md](docs/03_Analysen-Audits/03.4_Goetter-Framework-Analyse.md) | **Götter-Katalog & Stats** | Detaillierte mathematische Profile der Götter, Buff-Radien, Balancing-Kurven. |

---

## 🛠️ Technical Reference & Cheat Sheet

Dieses Kapitel dient als direkte Referenz für Entwickler und das AI-Betriebssystem. Es fasst die wichtigsten mathematischen Formeln, Systemkonfigurationen und die Ergebnisse des Sicherheitsaudits zusammen.

### 📐 1. Core Mathematical Systems

#### A. Orbit-Halos & Rotationsfrequenzen
Die Orbitalradien $R_L$ der Schwebeteile um die formlosen Götter skalieren mit der Andachtsstufe $L \in \{1, 2, 3\}$ über den Goldenen Schnitt ($\phi \approx 1{,}618$). Die Rotationsgeschwindigkeit $\omega_L$ wird gedämpft, um epileptische Trigger oder unruhige Visuals zu verhindern. 

> [!CAUTION]
> **Level 0 Division-by-Zero Fix:**
> Die mathematische Formulierung der Frequenz wurde gehärtet, um Divisionen durch Null bei $L = 0$ (uninitialisierte Rigs) zu verhindern, die zum Absturz der Roblox-Physik-Engine führen:
> 
> $$R_L = R_0 \cdot \phi^L \quad \text{und} \quad \omega_L = \frac{\omega_0}{\sqrt{\max(1, L)}}$$

#### B. Progression & Rebirth
Die Generierung Sakraler Funken $P$ bei einem Rebirth-Reset in Abhängigkeit von den passiv generierten Glaubenspunkten $B$ folgt einer degressiven Wurzelkurve:

$$P = \left\lfloor \sqrt{\frac{B}{C_{\text{epoche}}}} \right\rfloor$$

#### C. Sakrale Fusion (Zucht)
Die Wahrscheinlichkeit $P_{\text{besser}}$, bei der Verschmelzung zweier Gottheiten einen besseren Status-Wert als die Eltern zu erhalten, hängt von der Tempel-Stimulation $S \in [0, 100]$ ab (keine langweilige Mittelwert-Mischung!):

$$P_{\text{besser}} = \frac{1{,}0 + 0{,}01 \cdot S}{2{,}0 + 0{,}01 \cdot S}$$

---

### 💾 2. Perfect-Aligned Combat-Buffer (16-Byte Design)

Um Luau-Müll (Garbage Collection) im 60-Hz-Kampftakt vollständig zu vermeiden, wird ein binärer Ringpuffer über die native `buffer`-Bibliothek betrieben (Kapazität für 90 Frames / 1,5 Sekunden).

```
Slot-Byte-Layout (16 Bytes, 100% Aligned):
+-----------------------------------------------------------------------------------------------+
| Byte 0      | Byte 1      | Byte 2 - 3            | Byte 4 - 7                                |
| Active (u8) | TileIdx(u8) | CatalogIndex (uint16) | OwnerUserId (uint32)                      |
+-----------------------------------------------------------------------------------------------+
| Byte 8 - 11               | Byte 12    | Byte 13  | Byte 14 - 15                              |
| Health (float32)          | AP (u8)    | Padding  | StatusMask (uint16)                       |
+-----------------------------------------------------------------------------------------------+
```

* **Header-Größe:** $16 \text{ Bytes}$ (`0-3`: Tick [u32], `4-7`: Padding, `8-15`: Timestamp [f64/double]).
* **Frame-Größe ($S_{\text{frame}}$):**
  $$S_{\text{frame}} = 16 + (18 \cdot 16) = 304\text{ Bytes}$$
* **Puffer-Gesamtgröße ($S_{\text{buffer}}$) für 90 Frames:**
  $$S_{\text{buffer}} = 90 \cdot 304 = 27.360\text{ Bytes}$$

---

### ⚡ 3. Voxel-Grid: Zero-Allocation Indexing

Kollisions- und Aurenprüfungen im Voxel-Raster der Zitadelle generierten zuvor Heap-Strings via `string.format("%d_%d_%d")`, was zu massiven GC-Spikes führte.

#### Mathematische Bit-Codierung (Zero-Allocation):
Da die Rastergrenzen $64 \times 64 \times 64$ nicht überschreiten, codieren wir dreidimensionale Koordinaten direkt in einen einzigen 32-Bit-Integer:

$$\text{Index} = (Z \ll 20) + (Y \ll 10) + X$$

```luau
local function getCellIndex(x: number, y: number, z: number): number
    return bit32.lshift(z, 20) + bit32.lshift(y, 10) + x
end
```

---

### 🚨 4. Critical Security & Engineering Audits

#### A. R15 Torso-Deformations-Bug (Engine-Bug)
* **Problem:** Beim Instanziieren der abstrakten Götter-Geometrie an ein transparentes R15-Skelett löscht die Engine Knochenverbindungen im Torso, wenn die Avatar-Struktur ohne AJU geladen wird.
* **Lösung:** Im Roblox-Projekt muss die Eigenschaft `Workspace.AvatarJointUpgrade` permanent auf `Enabled` gesetzt sein.

#### B. Rojo-Pfadkollision im ServerScriptService
* **Problem:** Doppelte Pfad-Replizierung in Roblox Studio, da sowohl `src/server` als auch `src/server/modules` in `default.project.json` überlappend gemappt waren.
* **Lösung:** Strikt getrennte Quellordner im Dateisystem und Rojo-Tree:
  ```json
  "ServerScriptService": {
    "Scripts": { "$path": "src/server/scripts" },
    "Modules": { "$path": "src/server/modules" }
  }
  ```

#### C. Heap-Memory-Leak in Grid-Bereinigung
* **Problem:** Das Zuweisen von `nil` an Felder innerhalb von Tabellen (`{ OccupiedByDeityId = nil }`) löscht den Koordinatenschlüssel nicht. Bei häufigem Umbau sammelt die Gittertabelle verwaiste Tabellenleichen, was Mobilgeräte zum Absturz bringt.
* **Lösung:** Vollständiges Entfernen des Schlüssels aus dem Diktionär:
  ```luau
  grid.Cells[cellIndex] = nil
  ```

#### D. TDD TestEZ Mocking Crash
* **Problem:** Der Mock-Player im TDD-Test mied die Struktur für das Inventar und wies stattdessen eine nackte Zahl zu (`Inventory = { ["old_forest_spirit"] = 1 }`), was zu einem Absturz bei Eigentumsprüfungen (`attempt to index number with 'IsPlaced'`) führte.
* **Lösung:** Bereitstellung eines präzise typisierten Mock-Objekts, das alle Attribute und Metamethoden eines echten Players und dessen ProfileService-State abbildet.
