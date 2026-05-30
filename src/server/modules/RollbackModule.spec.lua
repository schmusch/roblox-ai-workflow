--!strict
return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	
	local RollbackModule = require(script.Parent.RollbackModule)
	local RingBufferModule = require(script.Parent.RingBufferModule)
	local PlayerDataStore = require(script.Parent.PlayerDataStore)

	describe("RollbackModule - Latenz-Rollback-Validierung (Epic 3.2 & 3.6)", function()
		local mockPlayer: Player
		local MockPlayer = {}
		MockPlayer.__index = MockPlayer

		function MockPlayer:GetAttribute(name: string)
			return self._attributes[name]
		end

		function MockPlayer:SetAttribute(name: string, val: any)
			self._attributes[name] = val
		end

		beforeEach(function()
			mockPlayer = setmetatable({
				Name = "TestPlayer",
				UserId = 12345,
				ClassName = "Player",
				_attributes = {},
			}, MockPlayer) :: any

			PlayerDataStore.clearPlayerState(mockPlayer)
			
			-- Mock des globalen Server-Ticks
			workspace:SetAttribute("CombatTick", 100)
		end)

		it("sollte zukünftige Ticks ablehnen (Future-Tick Spoofing)", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000,
				Inventory = {}
			})

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 105, 1, 1) -- 105 > 100 (Zukunft!)
			expect(success).to.equal(false)
			expect(err:find("Latenzfenster überschritten", 1, true)).to.be.ok()
		end)

		it("sollte abgelaufene Ticks ablehnen (Expired History > 90)", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000,
				Inventory = {}
			})

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 9, 1, 1) -- 100 - 9 = 91 Ticks delta (Limit ist 90)
			expect(success).to.equal(false)
			expect(err:find("Latenzfenster überschritten", 1, true)).to.be.ok()
		end)

		it("sollte ungültige Intervention-IDs ablehnen", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000,
				Inventory = {}
			})

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 95, 1, 999) -- 999 existiert nicht
			expect(success).to.equal(false)
			expect(err:find("Ungültige Intervention-ID", 1, true)).to.be.ok()
		end)

		it("sollte Intervention ablehnen bei unzureichendem Belief", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 100, -- Zu wenig für Glaubenssturm (500 benötigt)
				Inventory = {}
			})

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 95, 1, 1)
			expect(success).to.equal(false)
			expect(err:find("nicht leisten", 1, true)).to.be.ok()
		end)

		it("sollte Intervention ablehnen wenn kein Ziel auf der Kachel existiert", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000,
				Inventory = {}
			})

			-- Schreibe leeren Frame in den Puffer für Tick 95
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = 0,
					CatalogIndex = 0,
					OwnerUserId = 0,
					TileIndex = 0,
					Health = 0.0,
					ActionPoints = 0,
					StatusMask = 0
				}
			end
			RingBufferModule.writeFrame(95, 1000.0, entities)

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 95, 5, 1) -- Kachel 5 ist leer
			expect(success).to.equal(false)
			expect(err:find("Kein gültiges Ziel", 1, true)).to.be.ok()
		end)

		it("sollte Intervention ablehnen wenn Ziel bereits tot ist (HP <= 0)", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000,
				Inventory = {}
			})

			-- Schreibe Frame mit totem Ziel auf Kachel 5 für Tick 95
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 then 1 else 0,
					CatalogIndex = 1,
					OwnerUserId = 9999,
					TileIndex = if i == 1 then 5 else 0,
					Health = 0.0, -- Tot!
					ActionPoints = 0,
					StatusMask = 0
				}
			end
			RingBufferModule.writeFrame(95, 1000.0, entities)

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 95, 5, 1)
			expect(success).to.equal(false)
			expect(err:find("bereits tot", 1, true)).to.be.ok()
		end)

		it("sollte eine gültige Intervention erfolgreich verifizieren, Belief abziehen und bestätigen", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000,
				Inventory = {}
			})

			-- Schreibe Frame mit lebendem Ziel auf Kachel 5 für Tick 95
			local entities = {}
			for i = 1, 18 do
				entities[i] = {
					Active = if i == 1 then 1 else 0,
					CatalogIndex = 1,
					OwnerUserId = 9999,
					TileIndex = if i == 1 then 5 else 0,
					Health = 100.0, -- Lebendig!
					ActionPoints = 0,
					StatusMask = 0
				}
			end
			RingBufferModule.writeFrame(95, 1000.0, entities)

			local success, err = RollbackModule.processInterventionRequest(mockPlayer, 95, 5, 1)
			expect(success).to.equal(true)
			expect(err).to.never.be.ok()

			-- Kontostand prüfen
			local state = PlayerDataStore.getPlayerState(mockPlayer)
			expect(state.Belief).to.equal(500) -- 1000 - 500 Kosten = 500 übrig
		end)

		describe("Story 3.4 - Ascension-Lock & Zensur-Protokoll", function()
			local mockPlayerB: Player
			local MockPlayer = {}
			MockPlayer.__index = MockPlayer

			function MockPlayer:GetAttribute(name: string)
				return self._attributes[name]
			end

			function MockPlayer:SetAttribute(name: string, val: any)
				self._attributes[name] = val
			end

			beforeEach(function()
				mockPlayerB = setmetatable({
					Name = "TestPlayerB",
					UserId = 67890,
					ClassName = "Player",
					_attributes = {},
				}, MockPlayer) :: any

				PlayerDataStore.clearPlayerState(mockPlayerB)
				RollbackModule.clearPendingInterventions() -- Hilfsmethode zum Zurücksetzen der Queue
			end)

			it("sollte eine Glaubenssturm-Intervention in die Pending-Warteschlange legen (Ascension-Lock)", function()
				PlayerDataStore.setPlayerState(mockPlayer, {
					Belief = 1000,
					Inventory = {}
				})

				-- Frame mit lebendem Ziel auf Kachel 5 schreiben
				local entities = {}
				for i = 1, 18 do
					entities[i] = {
						Active = if i == 1 then 1 else 0,
						CatalogIndex = 1,
						OwnerUserId = 9999,
						TileIndex = if i == 1 then 5 else 0,
						Health = 100.0,
						ActionPoints = 0,
						StatusMask = 0
					}
				end
				RingBufferModule.writeFrame(95, 1000.0, entities)

				-- Glaubenssturm (interventionId = 1) triggern
				local success, err = RollbackModule.processInterventionRequest(mockPlayer, 95, 5, 1)
				expect(success).to.equal(true)

				-- Sollte in der ausstehenden Warteschlange sein
				local pending = RollbackModule.getPendingInterventions()
				expect(#pending).to.equal(1)
				expect(pending[1].interventionId).to.equal(1)
				expect(pending[1].targetTileIndex).to.equal(5)
				expect(pending[1].active).to.equal(true)

				-- Der Effekt sollte noch NICHT angewendet worden sein (Glaubenssturm zieht Belief ab, aber führt Effekte erst nach dem Lock aus)
				-- Wir prüfen, dass die Zeit noch nicht abgelaufen ist
				RollbackModule.updatePendingInterventions(1.0)
				expect(#RollbackModule.getPendingInterventions()).to.equal(1)

				-- Nach weiteren 0.6 Sekunden (insgesamt 1.6s > 1.5s Lock) sollte sie ausgeführt und entfernt worden sein
				RollbackModule.updatePendingInterventions(0.6)
				expect(#RollbackModule.getPendingInterventions()).to.equal(0)
			end)

			it("sollte eine ausstehende Glaubenssturm-Intervention durch ein gegnerisches Zensur-Protokoll abbrechen", function()
				-- Spieler A (mockPlayer) hat 1000 Belief
				PlayerDataStore.setPlayerState(mockPlayer, {
					Belief = 1000,
					Inventory = {}
				})
				-- Spieler B (mockPlayerB) hat 1000 Belief
				PlayerDataStore.setPlayerState(mockPlayerB, {
					Belief = 1000,
					Inventory = {}
				})

				-- Frame mit lebendem Ziel auf Kachel 5 schreiben
				local entities = {}
				for i = 1, 18 do
					entities[i] = {
						Active = if i == 1 then 1 else 0,
						CatalogIndex = 1,
						OwnerUserId = 9999,
						TileIndex = if i == 1 then 5 else 0,
						Health = 100.0,
						ActionPoints = 0,
						StatusMask = 0
					}
				end
				RingBufferModule.writeFrame(95, 1000.0, entities)

				-- Spieler A wirkt Glaubenssturm auf Kachel 5
				local successA, errA = RollbackModule.processInterventionRequest(mockPlayer, 95, 5, 1)
				expect(successA).to.equal(true)

				-- Spieler B wirkt Zensur-Protokoll auf Kachel 5 (interventionId = 2)
				local successB, errB = RollbackModule.processInterventionRequest(mockPlayerB, 95, 5, 2)
				expect(successB).to.equal(true)

				-- Die ausstehende Intervention von Spieler A sollte nun inaktiv/abgebrochen sein
				local pending = RollbackModule.getPendingInterventions()
				expect(#pending).to.equal(1)
				expect(pending[1].active).to.equal(false) -- abgebrochen!

				-- Nach Ablauf des Ascension-Locks (1.6s) sollte nichts passieren, da abgebrochen
				RollbackModule.updatePendingInterventions(1.6)
				expect(#RollbackModule.getPendingInterventions()).to.equal(0)
			end)
		end)
	end)
end
