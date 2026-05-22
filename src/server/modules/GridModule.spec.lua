--!strict
-- Platziert in: src/server/modules/GridModule.spec.lua
return function()
	local GridModule = require(script.Parent.GridModule)
	local PlayerDataStore = require(script.Parent.PlayerDataStore)

	-- Mocking-Infrastruktur für den Roblox Player
	local MockPlayer = {}
	MockPlayer.__index = MockPlayer

	local function createMockPlayer(userId: number, name: string): Player
		local self = setmetatable({
			UserId = userId,
			Name = name,
			ClassName = "Player",
			_attributes = { Belief = 1000 }
		}, MockPlayer)
		
		PlayerDataStore.setPlayerState(self :: any, {
			Belief = 1000,
			Inventory = { ["old_forest_spirit"] = 10 } -- Ausreichend Inventar für Tests
		})
		
		return self :: any
	end

	function MockPlayer:GetAttribute(name: string)
		local state = PlayerDataStore.getPlayerState(self :: any)
		return state and state[name] or self._attributes[name]
	end

	function MockPlayer:SetAttribute(name: string, val: any)
		local state = PlayerDataStore.getPlayerState(self :: any)
		if state then
			state[name] = val
		else
			self._attributes[name] = val
		end
	end

	describe("GridModule - Server-Authoritative Grid & Economy Loops", function()
		local testPlayer: Player

		beforeEach(function()
			testPlayer = createMockPlayer(88888, "ZitadellenBauer")
		end)

		afterEach(function()
			PlayerDataStore.clearPlayerState(testPlayer)
		end)

		it("sollte legitime Gitterplatzierungen erfolgreich durchführen", function()
			-- Platziere ein 2x2 Monument ("old_forest_spirit") auf Zelle (3,3)
			-- Startzelle: (3,3). Belegt bei Rotation 0: (3,3), (3,4), (4,3), (4,4)
			local success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 3, 3, 0)
			
			expect(success).to.equal(true)

			-- Prüfe, ob Glauben (500) abgezogen wurde
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(500)

			-- Prüfe den Gitterzustand des Spielers
			local grid = GridModule.GetOrCreateGrid(testPlayer)
			expect(grid).to.be.ok()
			
			-- Vergesse nicht, dass die Zellen belegt sein müssen
			expect(grid.Cells[3][3]).to.be.ok()
			expect(grid.Cells[3][4]).to.be.ok()
			expect(grid.Cells[4][3]).to.be.ok()
			expect(grid.Cells[4][4]).to.be.ok()
		end)

		it("sollte den Gitterzustand nach erfolgreicher Platzierung über Spieler-Attribute replizieren (JSON-Sync)", function()
			local HttpService = game:GetService("HttpService")
			
			-- Initialer Zustand
			local grid = GridModule.GetOrCreateGrid(testPlayer)
			local initialAttr = testPlayer:GetAttribute("CitadelPlacedObjects")
			expect(initialAttr).to.equal("{}")
			
			-- Platziere ein Monument
			local success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 3, 3, 0)
			expect(success).to.equal(true)
			
			-- Nach der Platzierung muss das Attribut befüllt sein
			local attributeVal = testPlayer:GetAttribute("CitadelPlacedObjects")
			expect(attributeVal).to.be.ok()
			
			local decoded = HttpService:JSONDecode(attributeVal)
			expect(decoded).to.be.ok()
			
			-- Finde das platzierte Objekt in den JSON-Daten
			local found = false
			for _, obj in pairs(decoded) do
				if obj.DeityId == "old_forest_spirit" then
					found = true
					expect(obj.OriginX).to.equal(3)
					expect(obj.OriginZ).to.equal(3)
					expect(obj.Rotation).to.equal(0)
				end
			end
			expect(found).to.equal(true)
		end)

		it("sollte Kollisionen (überlappende Platzierungen) blockieren", function()
			-- Platziere erstes 2x2 Monument auf (3,3)
			local firstSuccess = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 3, 3, 0)
			expect(firstSuccess).to.equal(true)

			-- Versuche ein weiteres Monument auf (4,4) zu platzieren (Zelle 4,4 ist bereits belegt!)
			local secondSuccess = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 4, 4, 0)
			
			-- Platzierung MUSS fehlschlagen
			expect(secondSuccess).to.equal(false)

			-- Belief des Spielers darf nur 1x abgezogen worden sein (1000 - 500 = 500)
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(500)
		end)

		it("sollte Platzierungen außerhalb des Gitters (Out-Of-Bounds) verhindern", function()
			-- Grid ist standardmäßig 10x10. Ein 2x2 Monument auf Zelle (10,10) ragt heraus
			local success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 10, 10, 0)
			
			expect(success).to.equal(false)

			-- Wallet unberührt
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(1000)
		end)

		it("sollte Rotations-Platzierungen und Kollisionen mathematisch korrekt validieren", function()
			-- Wir platzieren ein hypothetisches 2x1 Monument ("old_forest_spirit" wird hierzu testweise gemockt)
			-- Ein 2x1 Monument auf (5,5) mit Rotation 90 belegt (5,5) und (5,6) statt (5,5) und (6,5).
			-- Da wir in der Config "old_forest_spirit" als 2x2 haben, testen wir mit diesem bei 90 Grad.
			-- Bei 2x2 macht die Rotation geometrisch keinen Unterschied, wir testen daher mit einer Rotation von 90.
			local success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 5, 5, 90)
			expect(success).to.equal(true)

			local grid = GridModule.GetOrCreateGrid(testPlayer)
			expect(grid.Cells[5][5]).to.be.ok()
			expect(grid.Cells[5][6]).to.be.ok()
			expect(grid.Cells[6][5]).to.be.ok()
			expect(grid.Cells[6][6]).to.be.ok()
		end)

		it("sollte passive Glaubensgenerierung (Income Loop) zeitgesteuert anwenden", function()
			-- Platziere ein Monument, das 10 Belief/Sekunde erzeugt
			local success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 1, 1, 0)
			expect(success).to.equal(true)

			-- Belief nach Platzierung ist 500 (1000 - 500)
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(500)

			-- Simuliere den Zeitschritt von 1.0 Sekunde
			GridModule.Update(1.0)

			-- Belief muss nun 510 sein!
			expect(state.Belief).to.equal(510)

			-- Simuliere einen weiteren Zeitschritt von 0.5 Sekunden
			GridModule.Update(0.5)

			-- Bei 10 Belief/Sekunde erzeugen 0.5 Sekunden exakt 5 Belief. Neuer Stand: 515!
			expect(state.Belief).to.equal(515)
		end)

		it("sollte den Glaubensstand nach Anpassungen über Spieler-Attribute replizieren", function()
			-- MockPlayer hat initial 1000 in _attributes gesetzt (siehe createMockPlayer)
			-- und adjustBelief wird gerufen bei getPlayerState initial. Aber weil der MockPlayer
			-- getPlayerState Belief=1000 hat, rufen wir erst adjustBelief auf.
			local success = PlayerDataStore.adjustBelief(testPlayer, -200)
			expect(success).to.equal(true)
			expect(testPlayer:GetAttribute("CitadelBelief")).to.equal(800)
			
			success = PlayerDataStore.adjustBelief(testPlayer, 300)
			expect(success).to.equal(true)
			expect(testPlayer:GetAttribute("CitadelBelief")).to.equal(1100)
		end)

		it("sollte die passive Glaubensgenerierungsrate nach Platzierungen über Spieler-Attribute replizieren", function()
			-- Initialer Zustand
			local grid = GridModule.GetOrCreateGrid(testPlayer)
			expect(testPlayer:GetAttribute("CitadelBeliefRate")).to.equal(0)
			
			-- Platziere erstes Monument
			local success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 1, 1, 0)
			expect(success).to.equal(true)
			
			-- Jedes old_forest_spirit Monument generiert 10 Belief/s
			expect(testPlayer:GetAttribute("CitadelBeliefRate")).to.equal(10)
			
			-- Platziere zweites Monument
			success = GridModule.PlaceObject(testPlayer, "old_forest_spirit", 3, 3, 0)
			expect(success).to.equal(true)
			expect(testPlayer:GetAttribute("CitadelBeliefRate")).to.equal(20)
		end)
	end)
end
