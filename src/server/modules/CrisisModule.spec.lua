--!strict
-- Platziert in: src/server/modules/CrisisModule.spec.lua
return function()
	local CrisisModule = require(script.Parent.CrisisModule)

	describe("CrisisModule - Asynchronous Catastrophe Spawner Logic", function()
		local mockPlayer: Player

		beforeEach(function()
			-- Erstelle ein Mock-Player-Objekt
			mockPlayer = {
				Name = "TestPlayer",
				UserId = 12345,
				ClassName = "Player",
				IsA = function(self, className)
					return className == "Player"
				end,
			} :: any

			-- Stelle sicher, dass für jeden Test der Zustand sauber zurückgesetzt ist
			CrisisModule.ClearAll()
		end)

		it("sollte eine Krise erfolgreich spawnen und registrieren", function()
			local crisisId = CrisisModule.SpawnCrisis(mockPlayer)
			expect(crisisId).to.be.a("string")

			local activeCrises = CrisisModule.GetActiveCrises()
			local crisis = activeCrises[crisisId]

			expect(crisis).to.be.ok()
			expect(crisis.Id).to.equal(crisisId)
			expect(crisis.Player).to.equal(mockPlayer)
		end)

		it("sollte die 3x3 Gitterkoordinaten innerhalb der 10x10 Grenzen berechnen", function()
			-- Führe 50 Testläufe durch, um die stochastische Grenzenprüfung abzusichern
			for i = 1, 50 do
				local crisisId = CrisisModule.SpawnCrisis(mockPlayer)
				local crisis = CrisisModule.GetActiveCrises()[crisisId]

				expect(crisis).to.be.ok()
				expect(crisis.CellX).to.be.a("number")
				expect(crisis.CellZ).to.be.a("number")

				-- Start-Koordinaten müssen so liegen, dass ein 3x3-Objekt nicht über das 10x10-Gitter hinausragt
				expect(crisis.CellX >= 1).to.equal(true)
				expect(crisis.CellX <= 8).to.equal(true)
				expect(crisis.CellZ >= 1).to.equal(true)
				expect(crisis.CellZ <= 8).to.equal(true)
				
				CrisisModule.ClearAll()
			end
		end)

		it("sollte mehrere Krisen parallel registrieren können", function()
			local id1 = CrisisModule.SpawnCrisis(mockPlayer)
			local id2 = CrisisModule.SpawnCrisis(mockPlayer)

			expect(id1).never.to.equal(id2)

			local activeCrises = CrisisModule.GetActiveCrises()
			expect(activeCrises[id1]).to.be.ok()
			expect(activeCrises[id2]).to.be.ok()
		end)

		it("sollte alle registrierten Krisen löschen können (ClearAll)", function()
			CrisisModule.SpawnCrisis(mockPlayer)
			CrisisModule.SpawnCrisis(mockPlayer)

			local activeBefore = CrisisModule.GetActiveCrises()
			local countBefore = 0
			for _ in pairs(activeBefore) do
				countBefore += 1
			end
			expect(countBefore).to.equal(2)

			CrisisModule.ClearAll()

			local activeAfter = CrisisModule.GetActiveCrises()
			local countAfter = 0
			for _ in pairs(activeAfter) do
				countAfter += 1
			end
			expect(countAfter).to.equal(0)
		end)
	end)
end
