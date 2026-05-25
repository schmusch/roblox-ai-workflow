--!strict
-- Platziert in: src/server/modules/CrisisModule.spec.lua
return function()
	local CrisisModule = require(script.Parent.CrisisModule)

	describe("CrisisModule - Asynchronous Catastrophe Spawner Logic", function()
		local mockPlayer: Player
		local MockPlayer = {}
		MockPlayer.__index = MockPlayer

		function MockPlayer:GetAttribute(name: string)
			return self._attributes[name]
		end

		function MockPlayer:SetAttribute(name: string, val: any)
			self._attributes[name] = val
		end

		local mockRootPart: { Position: Vector3 }
		local mockCharacter: { FindFirstChild: (self: any, name: string) -> any }

		beforeEach(function()
			mockRootPart = {
				Position = Vector3.new(0, 0, 0)
			}
			mockCharacter = {
				FindFirstChild = function(self, name)
					if name == "HumanoidRootPart" then
						return mockRootPart
					end
					return nil
				end
			}

			-- Erstelle ein Mock-Player-Objekt mit voller Attribut- und Positions-Unterstützung
			mockPlayer = setmetatable({
				Name = "TestPlayer",
				UserId = 12345,
				ClassName = "Player",
				_attributes = {},
				Character = mockCharacter,
				IsA = function(self, className)
					return className == "Player"
				end,
			}, MockPlayer) :: any

			-- Stelle sicher, dass für jeden Test der Zustand sauber zurückgesetzt ist
			CrisisModule.ClearAll()
			CrisisModule.ResetCleansings()
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

		describe("Anti-Exploit Proximity Cleansing (Epic 2.3)", function()
			local ReplicatedStorage = game:GetService("ReplicatedStorage")
			local GridConfig = require(ReplicatedStorage.Shared.GridConfig)

			local function getCrisisWorldPos(cellX: number, cellZ: number): Vector3
				local sizeX = GridConfig.Settings.SizeX
				local sizeZ = GridConfig.Settings.SizeZ
				local cellSize = GridConfig.Settings.CellSize
				local centerX = cellX + 1
				local centerZ = cellZ + 1
				local worldX = (centerX - 1 - sizeX / 2) * cellSize + cellSize / 2
				local worldZ = (centerZ - 1 - sizeZ / 2) * cellSize + cellSize / 2
				return Vector3.new(worldX, 0.25, worldZ)
			end

			it("sollte den legitimen Reinigungsprozess (Start -> 3s Warten -> Complete) erfolgreich durchführen", function()
				local crisisId = CrisisModule.SpawnCrisis(mockPlayer)
				local crisis = CrisisModule.GetActiveCrises()[crisisId]
				expect(crisis).to.be.ok()

				-- 1. Positioniere Spieler direkt auf der Krise
				local crisisPos = getCrisisWorldPos(crisis.CellX, crisis.CellZ)
				mockRootPart.Position = crisisPos

				-- 2. Starte Reinigung auf dem Server
				local startSuccess = CrisisModule.HandleStartCleansing(mockPlayer, crisisId)
				expect(startSuccess).to.equal(true)

				-- 3. Simuliere 3.1 Sekunden Wartezeit (Mock-Zeitsteuerungen oder Yields)
				-- In Unit-Tests können wir den Zeitstempel im in-memory Speicher manipulieren
				-- Dazu mocken wir os.clock() oder verändern direkt das interne Cleansing-Register, wenn nötig.
				-- Aber wir können auch einfach task.wait(3.1) in Echtzeit laufen lassen, da es sehr kurz ist!
				task.wait(3.1)

				-- 4. Schließe Reinigung erfolgreich ab
				local completeSuccess = CrisisModule.HandleCompleteCleansing(mockPlayer, crisisId)
				expect(completeSuccess).to.equal(true)

				-- Die Krise muss gelöscht sein!
				local activeAfter = CrisisModule.GetActiveCrises()
				expect(activeAfter[crisisId]).to.never.be.ok()
			end)

			it("sollte Sofort-Reinigungs-Versuche (Instant-Cleansing Exploit) unter 3 Sekunden abfangen und ablehnen", function()
				local crisisId = CrisisModule.SpawnCrisis(mockPlayer)
				local crisis = CrisisModule.GetActiveCrises()[crisisId]
				expect(crisis).to.be.ok()

				local crisisPos = getCrisisWorldPos(crisis.CellX, crisis.CellZ)
				mockRootPart.Position = crisisPos

				local startSuccess = CrisisModule.HandleStartCleansing(mockPlayer, crisisId)
				expect(startSuccess).to.equal(true)

				-- Sofortiges Abschließen ohne Wartezeit (0 Sekunden)
				local completeSuccess = CrisisModule.HandleCompleteCleansing(mockPlayer, crisisId)
				expect(completeSuccess).to.equal(false) -- MUSS abgelehnt werden!

				-- Die Krise darf nicht gelöscht sein!
				local activeAfter = CrisisModule.GetActiveCrises()
				expect(activeAfter[crisisId]).to.be.ok()
			end)

			it("sollte Reinigungs-Versuche außerhalb der Reichweite (Teleport-Cleansing Exploit > 15 Studs) ablehnen", function()
				local crisisId = CrisisModule.SpawnCrisis(mockPlayer)
				local crisis = CrisisModule.GetActiveCrises()[crisisId]
				expect(crisis).to.be.ok()

				-- Spieler ist 20 Studs entfernt platziert
				local crisisPos = getCrisisWorldPos(crisis.CellX, crisis.CellZ)
				mockRootPart.Position = crisisPos + Vector3.new(20, 0, 0)

				-- Start-Reinigung muss bereits wegen Reichweite abgelehnt werden
				local startSuccess = CrisisModule.HandleStartCleansing(mockPlayer, crisisId)
				expect(startSuccess).to.equal(false) -- MUSS abgelehnt werden!
			end)
		end)
	end)
end
