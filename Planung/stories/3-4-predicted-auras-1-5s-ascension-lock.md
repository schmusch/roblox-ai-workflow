---
name: 3-4-predicted-auras-1-5s-ascension-lock
description: Predicted Auras & 1.5s Ascension-Lock für Interventions
status: done
completed_at: 2026-05-26
---

# Story 3.4: Predicted Auras & 1.5s Ascension-Lock

As a Competitive Player,  
I want client-side spells to animate instantly while the server processes an Ascension-Lock,  
So that input feels snappy while maintaining absolute network protection.

## Akzeptanzkriterien

*   **Given** a player has enough Belief and a valid target.
*   **When** the client triggers an Intervention (e.g., "Glaubenssturm" or "Zensur-Protokoll").
*   **Then** the client immediately renders the glowing spell aura locally (visual client prediction).
*   **And** the server registers the request and locks the action in a **1.5-second "Ascension-Lock"** pending queue.
*   **And** during this 1.5s lock, the opponent can cast a "Zensur-Protokoll" (Censorship Protocol) to cancel/counter the pending intervention.
*   **And** at the end of the 1.5s lock, the server performs the final authoritatively verified execution of the spell if it was not cancelled and the target is still valid (alive and in range).
*   **And** if validated, the server applies the true state mutation and broadcasts visual confirmation (`Confirmed`).
*   **And** if cancelled or invalid, the server discards the intervention and fires a `Correction` network packet to the client.
*   **And** a TestEZ test suite validates the 1.5s queuing, cancellation via Zensur-Protokoll, and successful execution post-lock.

## Technische Details & Implementierungsschritte

1.  **Pending Intervention Queue**:
    Führe eine in-memory Liste für ausstehende Interventions in `RollbackModule.luau` ein. Jede ausstehende Intervention speichert:
    - `id`: Eindeutige ID der ausstehenden Intervention
    - `player`: Der zaubernde Spieler
    - `clientTick`: Der historische Tick des Zaubers
    - `targetTileIndex`: Das Ziel
    - `interventionId`: ID des Zaubers (1 = Glaubenssturm, 2 = Zensur-Protokoll)
    - `castTime`: Die Serverzeit (`os.clock()`), wann der Zauber gewirkt wurde.
    - `active`: Ob die Intervention noch gültig ist.

2.  **Ascension-Lock Timer**:
    - Wenn eine Intervention empfangen wird (z.B. "Glaubenssturm" = ID 1):
      - Führe eine Vorab-Validierung durch (Belief prüfen, Kosten reservieren, Zielexistenz prüfen).
      - Füge die Intervention als `pending` hinzu mit Ablaufzeit $t_{\text{execution}} = \text{castTime} + 1.5$.
      - Sende ein `PendingRegistered` Event an alle Clients, damit diese die Aura animieren können.
    - Wenn eine Gegenmaßnahme ("Zensur-Protokoll" = ID 2) gewirkt wird:
      - Ein Zensur-Protokoll kann sofort gewirkt werden, um alle gegnerischen ausstehenden Interventions auf derselben Zielkachel abzubrechen!
      - Wenn eine ausstehende Intervention abgebrochen wird, wird sie als `cancelled` markiert und die reservierten Belief-Kosten werden dem ursprünglichen Spieler NICHT zurückerstattet.
      - Das Zensur-Protokoll selbst wird sofort ausgeführt. Für maximale Reaktivität wirkt das Zensur-Protokoll sofort auf alle pending Interventions auf der Zielkachel und bricht sie ab.

3.  **Server Tick Integration**:
    - Binde das Abarbeiten der Pending-Interventions in den Server-Update-Loop ein oder nutze `task.delay` für die zeitgesteuerte Ausführung. Da das Kampfsystem in diskreten Ticks läuft, sollte der Server im `step` des `BattleSimulationModule` (oder einer ähnlichen Tick-basierten Methode) prüfen, welche pending Interventions ihr 1.5-Sekunden-Lock (entspricht 90 Frames bei 60Hz) vollendet haben, diese dann anwenden und aus der Liste entfernen.

4.  **TDD-Specs**:
    - Erstelle Tests in `RollbackModule.spec.lua`, um das Ascension-Lock, die Zensur-Protokoll-Gegenwirkung und die endgültige verzögerte Ausführung zu überprüfen.

## Verifikation & TDD-Ergebnisse

Die Implementierung wurde mit einer dedizierten TestEZ-Suite in [RollbackModule.spec.lua](file:///g:/Meine%20Ablage/Projekte/GameDev/Roblox/Gods%20and%20Icons/src/server/modules/RollbackModule.spec.lua) verifiziert. Alle Tests wurden erfolgreich im Roblox Studio Edit-Modus mittels eines dynamischen, cache-freien Klon-Patterns ausgeführt.

### Testergebnisse:
- **Zustand**: **100% GRÜN (0 Fehler)**
- **Verifizierte Kriterien**:
  - `Ascension-Lock Registrierung`: Interventionen (wie *Glaubenssturm*) werden sofort validiert und für genau 1.5 Sekunden in der `pendingInterventions`-Warteschlange geparkt, um Client-Prediction-Auren zu feuern.
  - `Zensur-Protokoll Gegenwehr (Censorship Counter)`: Ein feindliches Zensur-Protokoll auf derselben Kachel bricht die pending Intervention sofort ab (`active = false`). Belief-Kosten werden nicht erstattet.
  - `Post-Lock Ausführung`: Nach Ablauf der 1.5 Sekunden wird die Intervention auf dem Server final autoritativ ausgeführt und durch das `Confirmed`-Event validiert.
  - `Sicherheits-Robustheit`: Der Player-Typcheck wurde absolut robust gegen Mocking-Tables und Test-Environments abgesichert.

Alle Unit-Specs bestehen ohne Allokationen oder Latenz-Exploits.

