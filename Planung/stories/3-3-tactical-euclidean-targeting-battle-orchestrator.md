---
name: 3-3-tactical-euclidean-targeting-battle-orchestrator
description: Tactical Euclidean Targeting & Battle Orchestrator
status: done
---

# Story 3.3: Tactical Euclidean Targeting & Battle Orchestrator

As a Tactical Deceiver,  
I want my deities to target enemies based on Euclidean targeting matrices,  
So that combat maneuvers are mathematically predictable.

## Akzeptanzkriterien

*   **Given** a deity is ready to attack (AP >= 100)
*   **When** selecting a target
*   **Then** the orchestrator computes the Euclidean distance $\sqrt{(x_2-x_1)^2 + (z_2-z_1)^2}$ to all active (`Active == 1`), alive (`Health > 0`) enemy entities.
*   **And** it selects the closest target matching its role config (Tank, Supporter, Slayer, Controller) within its configured `AttackRange`.
*   **And** if multiple targets have the same minimum Euclidean distance, the one with the lower `TileIndex` (slot index) is chosen as a deterministic tie-breaker.
*   **And** if no targets are alive or in range, the deity holds its Action Points at 100 without attacking.
*   **And** a TestEZ test suite confirms that running combat simulation with Euclidean targeting produces exactly 0 KB of Lua heap memory allocation.

## Technische Details & Implementierungsschritte

1.  **DeityCatalog.luau [NEW]**: Erstelle ein geteiltes Modul in `src/shared/DeityCatalog.luau`, welches die Gottheiten-Konfiguration inklusive `CombatRole` und `AttackRange` bereitstellt. Es muss voll abwärtskompatibel sein und Standardwerte für unbekannte IDs liefern.
2.  **Relative Pfade**: Stelle sicher, dass `BattleSimulationModule.luau` relative Pfade (`require(script.Parent.RingBufferModule)`) nutzt, um das Studio-Caching-Problem zu umgehen.
3.  **Euclidean Distance**: Implementiere eine mathematische Abstandsfunktion basierend auf den Slot-Indizes (1..9 für Team A, 10..18 für Team B) auf einem virtuellen 3x3-Spielfeld:
    *   Team A: Spalte $x = (i-1) \pmod 3 + 1$, Reihe $z = \lfloor(i-1)/3\rfloor + 1$
    *   Team B: Spalte $x = (i-10) \pmod 3 + 1$, Reihe $z = \lfloor(i-10)/3\rfloor + 4$
4.  **Targeting-Matrix**: Implementiere die bevorzugte Rollen-Reihenfolge:
    *   `Tank` $\rightarrow$ Tank, Slayer, Controller, Supporter
    *   `Slayer` $\rightarrow$ Supporter, Slayer, Controller, Tank
    *   `Supporter` $\rightarrow$ Supporter, Controller, Slayer, Tank
    *   `Controller` $\rightarrow$ Controller, Supporter, Slayer, Tank
5.  **Zero-Allocation**: Optimiere den Suchalgorithmus so, dass er keine temporären Tables, Vektoren oder Arrays erzeugt. Alles muss über lokale Variablen gelöst werden.
6.  **TDD-Verifizierung**: Schreibe umfassende Specs in `BattleSimulationModule.spec.lua`, um Abstands-Berechnungen, Reichweiten-Limits, Rollen-Targeting, Tie-Breaker und Heap-Speicher zu testen.
