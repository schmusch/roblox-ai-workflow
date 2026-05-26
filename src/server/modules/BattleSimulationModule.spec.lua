--!strict
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local BattleSimulationModule = require(script.Parent.BattleSimulationModule)
	local RingBufferModule = require(script.Parent.RingBufferModule)
	local DeityCatalog = require(ReplicatedStorage.Shared.DeityCatalog)

	describe("BattleSimulationModule - 60Hz Kampfsimulation & AP Berechnung (Epic 3.1)", function()
		it("sollte Entities initialisieren und AP im Takt erhoehen", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 or i == 10 then 1 else 0,
					CatalogIndex = if i == 1 or i == 10 then 999 else 0,
					OwnerUserId = if i == 1 then 1234567 else (if i == 10 then 7654321 else 0),
					TileIndex = i,
					Health = 100.0,
					ActionPoints = 0,
					StatusMask = 0,
				}
			end

			BattleSimulationModule.initialize(entities)

			-- Simuliere 50 Ticks
			for tick = 1, 50 do
				BattleSimulationModule.step(tick, 1000.0 + tick * 0.016)
			end

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[1].ActionPoints).to.equal(50)
			expect(simEntities[10].ActionPoints).to.equal(50)
			expect(simEntities[1].Health).to.equal(100.0)
			expect(simEntities[10].Health).to.equal(100.0)
		end)

		it("sollte bei AP >= 100 angreifen und AP zuruecksetzen", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 or i == 10 then 1 else 0,
					CatalogIndex = if i == 1 or i == 10 then 999 else 0,
					OwnerUserId = if i == 1 then 1234567 else (if i == 10 then 7654321 else 0),
					TileIndex = i,
					Health = 100.0,
					ActionPoints = 0,
					StatusMask = 0,
				}
			end

			BattleSimulationModule.initialize(entities)

			-- Simuliere 100 Ticks (bei Tick 100 erreicht AP 100 und setzt sich zurück, und fügt dem Feind Schaden zu)
			for tick = 1, 100 do
				BattleSimulationModule.step(tick, 1000.0 + tick * 0.016)
			end

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[1].ActionPoints).to.equal(0)
			expect(simEntities[10].ActionPoints).to.equal(0)
			-- Da beide bei Tick 100 angreifen, sollten beide Schaden genommen haben
			expect(simEntities[1].Health).to.equal(90.0)
			expect(simEntities[10].Health).to.equal(90.0)
		end)

		it("sollte Zero-Allocation bei der Simulation ueber 10.000 Schritte aufweisen", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i <= 9 or i == 10 then 1 else 0,
					CatalogIndex = i,
					OwnerUserId = if i <= 9 then 1111 else 2222,
					TileIndex = i,
					Health = 100.0,
					ActionPoints = 0,
					StatusMask = 0,
				}
			end

			BattleSimulationModule.initialize(entities)

			-- Aufwärmen
			BattleSimulationModule.step(1, 1000.0)

			task.wait(0.1) -- Ermöglicht GC
			local memoryBefore = gcinfo()

			-- Führe 10.000 Simulationsschritte aus
			for tick = 2, 10001 do
				BattleSimulationModule.step(tick, 1000.0 + tick * 0.016)
			end

			local memoryAfter = gcinfo()
			
			-- Muss 0 KB Speicherallokation aufweisen
			expect(memoryAfter - memoryBefore).to.equal(0)
		end)
	end)

	describe("BattleSimulationModule - Taktisches euklidisches Targeting (Epic 3.3)", function()
		it("sollte das naechste Ziel basierend auf euklidischem Abstand waehlen", function()
			-- Attacker in Slot 1 (Player A, Slayerfallback) bei (1, 1)
			-- Ziel 1 in Slot 10 (Player B) bei (1, 4) -> Abstand 3.0
			-- Ziel 2 in Slot 11 (Player B) bei (2, 4) -> Abstand sqrt(10) ~ 3.16
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 or i == 10 or i == 11 then 1 else 0,
					CatalogIndex = 103, -- Slayer (Reichweite 2.5) -> warte, wir brauchen Reichweite >= 3.16 für diesen Test.
					OwnerUserId = if i == 1 then 1234567 else 7654321,
					TileIndex = i,
					Health = 100.0,
					ActionPoints = if i == 1 then 99 else 0, -- Attacker ist gleich bei AP >= 100
					StatusMask = 0,
				}
			end
			-- Setze Attacker als Slayerfallback, aber überschreibe Reichweite temporär bzw. nutze Supporter (CatalogIndex 101, Range 4.0)
			entities[1].CatalogIndex = 101 -- Supporter, Range 4.0, bevorzugt Supporter/Controller/Slayer/Tank.
			entities[10].CatalogIndex = 102 -- Tank (Ziel 1)
			entities[11].CatalogIndex = 102 -- Tank (Ziel 2)
			-- Beide Ziele sind Tanks (gleiche Priorität), also entscheidet euklidischer Abstand: Ziel 1 in Slot 10 (Abstand 3.0) ist näher als Slot 11 (Abstand 3.16)

			BattleSimulationModule.initialize(entities)
			BattleSimulationModule.step(1, 1000.0) -- Erhöht AP auf 100 und triggert Angriff

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[1].ActionPoints).to.equal(0) -- Angriff ausgeführt
			expect(simEntities[10].Health).to.equal(90.0) -- Slot 10 (näher) nimmt Schaden
			expect(simEntities[11].Health).to.equal(100.0) -- Slot 11 (weiter) unberührt
		end)

		it("sollte die Rollen-Priorisierung der Targeting-Matrix beachten", function()
			-- Attacker in Slot 1 (Player A, Supporter, CatalogIndex = 101) bei (1, 1)
			-- Ziel 1 in Slot 10 (Player B, Tank, CatalogIndex = 102) bei (1, 4) -> Abstand 3.0
			-- Ziel 2 in Slot 11 (Player B, Slayer, CatalogIndex = 103) bei (2, 4) -> Abstand 3.16
			-- Supporter bevorzugt: Supporter > Controller > Slayer > Tank.
			-- Ziel 2 (Slayer, Prio 3) hat höhere Priorität als Ziel 1 (Tank, Prio 4), obwohl Ziel 1 näher ist!
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 or i == 10 or i == 11 then 1 else 0,
					CatalogIndex = 0,
					OwnerUserId = if i == 1 then 1234567 else 7654321,
					TileIndex = i,
					Health = 100.0,
					ActionPoints = if i == 1 then 99 else 0,
					StatusMask = 0,
				}
			end
			entities[1].CatalogIndex = 101 -- Supporter (Range 4.0)
			entities[10].CatalogIndex = 102 -- Tank
			entities[11].CatalogIndex = 103 -- Slayer

			BattleSimulationModule.initialize(entities)
			BattleSimulationModule.step(1, 1000.0)

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[1].ActionPoints).to.equal(0) -- Angriff ausgeführt
			expect(simEntities[10].Health).to.equal(100.0) -- Slot 10 (näher, aber Tank) unberührt
			expect(simEntities[11].Health).to.equal(90.0) -- Slot 11 (weiter, aber Slayer) nimmt Schaden!
		end)

		it("sollte bei gleichem Abstand den deterministischen Tie-Breaker (niedrigerer Slot Index) waehlen", function()
			-- Attacker in Slot 2 (Player A, Tank, CatalogIndex = 102) bei (2, 1)
			-- Ziel 1 in Slot 10 (Player B, Tank, CatalogIndex = 102) bei (1, 4) -> Abstand sqrt(1+9) = 3.16
			-- Ziel 2 in Slot 12 (Player B, Tank, CatalogIndex = 102) bei (3, 4) -> Abstand sqrt(1+9) = 3.16
			-- Beide haben exakt gleichen Abstand und gleiche Rolle (Tank).
			-- Der Tie-Breaker muss Slot 10 wählen, da 10 < 12.
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 2 or i == 10 or i == 12 then 1 else 0,
					CatalogIndex = 102, -- Tank, Range 1.5... warte, Tank-Reichweite ist 1.5. Abstand ist 3.16. Wir müssen die Reichweite anpassen!
					-- Um range limit zu umgehen, nutzen wir ein anderes Profil oder setzen Reichweite hoch.
					-- Wir können für den Test CatalogIndex 101 nutzen (Supporter, Range 4.0), aber die Rolle zu Tank machen?
					-- Halt, CatalogIndex 101 hat Supporter. 
					-- Wir können auch einfach die Abwärtskompatibilität nutzen: CatalogIndex = 999.
					-- Ein unbekannter CatalogIndex hat Reichweite 999.0 und Rolle "Slayer".
					CatalogIndex = 999, -- Unknown, Role Slayer, Range 999.0
					OwnerUserId = if i == 2 then 1234567 else 7654321,
					TileIndex = i,
					Health = 100.0,
					ActionPoints = if i == 2 then 99 else 0,
					StatusMask = 0,
				}
			end

			BattleSimulationModule.initialize(entities)
			BattleSimulationModule.step(1, 1000.0)

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[2].ActionPoints).to.equal(0)
			expect(simEntities[10].Health).to.equal(90.0) -- Slot 10 (niedrigerer Index) nimmt Schaden
			expect(simEntities[12].Health).to.equal(100.0) -- Slot 12 unberührt
		end)

		it("sollte Reichweiten-Limits strikt einhalten und AP bei Out-of-Range halten", function()
			-- Attacker in Slot 10 (Player B, Tank, CatalogIndex = 102, Reichweite = 1.5) bei (1, 4)
			-- Ziel in Slot 1 (Player A, Slayer, CatalogIndex = 103) bei (1, 1) -> Abstand 3.0
			-- Da 3.0 > 1.5, ist das Ziel ausser Reichweite.
			-- Der Attacker sollte NICHT angreifen und seine AP bei 100 halten.
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 or i == 10 then 1 else 0,
					CatalogIndex = if i == 1 then 103 else 102,
					OwnerUserId = if i == 1 then 1234567 else 7654321,
					TileIndex = i,
					Health = 100.0,
					ActionPoints = if i == 10 then 99 else 0,
					StatusMask = 0,
				}
			end

			BattleSimulationModule.initialize(entities)
			BattleSimulationModule.step(1, 1000.0) -- Erhöht AP von Slot 10 auf 100

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[10].ActionPoints).to.equal(100) -- Hält AP bei 100
			expect(simEntities[1].Health).to.equal(100.0) -- Kein Schaden erlitten
		end)

		it("sollte AP bei 100 halten, wenn keine Gegner mehr leben oder aktiv sind", function()
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 or i == 10 then 1 else 0,
					CatalogIndex = if i == 1 then 101 else 102,
					OwnerUserId = if i == 1 then 1234567 else 7654321,
					TileIndex = i,
					Health = if i == 1 then 100.0 else 0.0, -- Gegner ist tot!
					ActionPoints = if i == 1 then 99 else 0,
					StatusMask = 0,
				}
			end

			BattleSimulationModule.initialize(entities)
			BattleSimulationModule.step(1, 1000.0)

			local simEntities = BattleSimulationModule.getEntities()
			expect(simEntities[1].ActionPoints).to.equal(100) -- Hält AP bei 100
		end)
	end)
end
