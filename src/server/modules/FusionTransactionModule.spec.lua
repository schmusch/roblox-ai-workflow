--!strict
-- Platziert in: src/server/modules/FusionTransactionModule.spec.lua

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PlayerDataStore = require(script.Parent.PlayerDataStore)
	local FusionTransactionModule = require(script.Parent.FusionTransactionModule)

	describe("FusionTransactionModule - Transaktionale Fusions-Sicherheit (Epic 4.2)", function()
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
			-- Mock-Player mit Metatable statt Instance.new("Player"), um WritePlayer-Restriktionen zu umgehen
			mockPlayer = setmetatable({
				Name = "TestFusionPlayer",
				UserId = 12345,
				ClassName = "Player",
				_attributes = {},
			}, MockPlayer) :: any
			
			-- Initialer Stand: 500 Belief, 2x old_forest_spirit
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 500,
				Inventory = {
					["old_forest_spirit"] = 2
				},
				LastSaveTime = os.time()
			})
			
			FusionTransactionModule.ClearAll()
		end)

		afterEach(function()
			PlayerDataStore.clearPlayerState(mockPlayer)
			FusionTransactionModule.ClearAll()
		end)

		it("sollte eine standardmäßige erfolgreiche Fusion (Happy Path) durchführen", function()
			local success, err = FusionTransactionModule.StartFusion(mockPlayer, "old_forest_spirit", "old_forest_spirit", 100)
			
			-- 1. Lock Phase prüfen
			expect(success).to.equal(true)
			expect(err).to.equal(nil)
			
			local tx = FusionTransactionModule.GetActiveTransaction(mockPlayer)
			expect(tx).to.never.equal(nil)
			if tx then
				expect(tx.Status).to.equal("locked")
			end
			
			-- Ressourcen im Lock-Zustand abgezogen
			local state = PlayerDataStore.getPlayerState(mockPlayer)
			expect(state.Belief).to.equal(400)
			expect(state.Inventory["old_forest_spirit"]).to.equal(nil) -- Komplett verbraucht in Lock-Phase

			-- 2. Process Write Phase (Erfolg)
			local writeSuccess, writeMsg = FusionTransactionModule.ProcessWrite(mockPlayer, false)
			expect(writeSuccess).to.equal(true)
			expect(writeMsg).to.never.equal(nil)
			
			-- Status nach Commit prüfen
			expect(FusionTransactionModule.GetActiveTransaction(mockPlayer)).to.equal(nil)
			
			local finalState = PlayerDataStore.getPlayerState(mockPlayer)
			expect(finalState.Belief).to.equal(400)
			expect(finalState.Inventory["hybrid__old_forest_spirit__old_forest_spirit"]).to.equal(1)
			expect(finalState.Inventory["old_forest_spirit"]).to.equal(nil)
		end)

		it("sollte bei einem simulierten Verbindungsabbruch (Database Crash) einen perfekten Rollback ausführen", function()
			local success, err = FusionTransactionModule.StartFusion(mockPlayer, "old_forest_spirit", "old_forest_spirit", 100)
			expect(success).to.equal(true)
			
			-- 1. Lock Phase verifizieren
			local stateLocked = PlayerDataStore.getPlayerState(mockPlayer)
			expect(stateLocked.Belief).to.equal(400)
			expect(stateLocked.Inventory["old_forest_spirit"]).to.equal(nil)
			
			-- 2. Process Write Phase mit Fehler (Simulated Crash)
			local writeSuccess, writeMsg = FusionTransactionModule.ProcessWrite(mockPlayer, true)
			expect(writeSuccess).to.equal(false)
			expect(string.find(writeMsg, "sicher zurückgerollt") ~= nil).to.equal(true)
			
			-- 3. Rollback-Zustand prüfen
			expect(FusionTransactionModule.GetActiveTransaction(mockPlayer)).to.equal(nil)
			
			local finalState = PlayerDataStore.getPlayerState(mockPlayer)
			-- Glaubenspunkte und Original-Essenzen müssen zu 100% restauriert sein!
			expect(finalState.Belief).to.equal(500)
			expect(finalState.Inventory["old_forest_spirit"]).to.equal(2)
			expect(finalState.Inventory["hybrid__old_forest_spirit__old_forest_spirit"]).to.equal(nil)
		end)

		it("sollte Fusionen blockieren, wenn nicht genügend Glaubenspunkte (Belief) vorhanden sind", function()
			-- Kosten von 600 überschreiten das Guthaben von 500
			local success, err = FusionTransactionModule.StartFusion(mockPlayer, "old_forest_spirit", "old_forest_spirit", 600)
			expect(success).to.equal(false)
			expect(err).to.equal("Nicht genügend Glaubenspunkte!")
			
			-- Ressourcen unverändert
			local state = PlayerDataStore.getPlayerState(mockPlayer)
			expect(state.Belief).to.equal(500)
			expect(state.Inventory["old_forest_spirit"]).to.equal(2)
		end)

		it("sollte Fusionen blockieren, wenn zu wenige Instanzen identischer Götter im Inventar sind", function()
			-- Setze Inventar auf nur 1 old_forest_spirit
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 500,
				Inventory = {
					["old_forest_spirit"] = 1
				},
				LastSaveTime = os.time()
			})
			
			local success, err = FusionTransactionModule.StartFusion(mockPlayer, "old_forest_spirit", "old_forest_spirit", 100)
			expect(success).to.equal(false)
			expect(err).to.equal("Es werden mindestens 2 Instanzen derselben Gottheit benötigt!")
			
			-- Ressourcen unverändert
			local state = PlayerDataStore.getPlayerState(mockPlayer)
			expect(state.Belief).to.equal(500)
			expect(state.Inventory["old_forest_spirit"]).to.equal(1)
		end)

		it("sollte Fusionen blockieren, wenn eine der beiden unterschiedlichen Gottheiten gänzlich fehlt", function()
			-- Nur 1 Forest Spirit vorhanden, Water Shrine fehlt komplett
			local success, err = FusionTransactionModule.StartFusion(mockPlayer, "old_forest_spirit", "water_shrine", 100)
			expect(success).to.equal(false)
			expect(string.find(err or "", "nicht im Inventar") ~= nil).to.equal(true)
			
			-- Ressourcen unverändert
			local state = PlayerDataStore.getPlayerState(mockPlayer)
			expect(state.Belief).to.equal(500)
			expect(state.Inventory["old_forest_spirit"]).to.equal(2)
		end)
	end)
end
