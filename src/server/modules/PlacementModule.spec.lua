--!strict
-- Platziert in: src/server/modules/PlacementModule.spec.lua
return function()
	local PlacementModule = require(script.Parent.PlacementModule)
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
		
		-- Registrierung im PlayerDataStore Mocking-Zweig
		PlayerDataStore.setPlayerState(self :: any, {
			Belief = 1000,
			Inventory = { ["old_forest_spirit"] = 1 }
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

	describe("PlacementModule - Adversarial Security Checks", function()
		local testPlayer: Player
		
		beforeEach(function()
			testPlayer = createMockPlayer(99999, "GottExploiter")
		end)

		it("sollte legitime Platzierungen erfolgreich durchführen", function()
			local request = {
				DeityId = "old_forest_spirit",
				GridCoords = Vector3.new(5, 0, 5),
				Rotation = 0
			}
			
			local success = false
			local err = nil
			
			success, err = pcall(function()
				PlacementModule.HandlePlacementRequest(testPlayer, request.DeityId, request.GridCoords, request.Rotation)
			end)
			
			expect(success).to.equal(true)
			
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state).to.be.ok()
			expect(state.Belief).to.equal(500) -- Kanonischer Preis (500) abgezogen
		end)

		it("sollte manipulierte Preissubventionen (Client-Side Price Spoofing) vollständig ignorieren", function()
			local request = {
				DeityId = "old_forest_spirit",
				GridCoords = Vector3.new(3, 0, 3),
				Rotation = 0,
				Price = 1 -- Versuchte Client-seitige Subventionierung!
			}
			
			-- Der Server darf keine "Price"-Variable aus der RPC-Schnittstelle akzeptieren!
			-- Die Platzierung wird ausgeführt, aber es MUSS der echte Serverkatalog-Preis (500) abgezogen werden.
			local success = pcall(function()
				PlacementModule.HandlePlacementRequest(testPlayer, request.DeityId, request.GridCoords, request.Rotation)
			end)
			
			expect(success).to.equal(true)
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(500) -- Abzug von 500, NICHT von 1!
		end)

		it("sollte Typ-Verwirrungs-Angriffe (Type-Confusion Attacks) abfangen ohne abzustürzen", function()
			local corruptRequest = {
				DeityId = 12345, -- Zahl statt String
				GridCoords = "Vector3(1,1,1)", -- String statt Vector3
				Rotation = "90Grad" -- String statt Zahl
			}
			
			local success = pcall(function()
				-- Erzwingung der Ausführung mit fehlerhaften Typen zur Prüfung des Type Guards
				PlacementModule.HandlePlacementRequest(testPlayer, corruptRequest.DeityId :: any, corruptRequest.GridCoords :: any, corruptRequest.Rotation :: any)
			end)
			
			-- Der Server darf NICHT abstürzen (muss robust abfangen)
			expect(success).to.equal(true)
			
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(1000) -- Wallet unberührt
		end)

		it("sollte Platzierungen außerhalb des Spielfelds (Out-Of-Bounds) blockieren", function()
			local outOfBoundsRequest = {
				DeityId = "old_forest_spirit",
				GridCoords = Vector3.new(99, 0, 5), -- Weit außerhalb des Spielfelds (z.B. max 10x10)
				Rotation = 0
			}
			
			PlacementModule.HandlePlacementRequest(testPlayer, outOfBoundsRequest.DeityId, outOfBoundsRequest.GridCoords, outOfBoundsRequest.Rotation)
			
			local state = PlayerDataStore.getPlayerState(testPlayer)
			expect(state.Belief).to.equal(1000) -- Wallet unberührt
		end)

		it("sollte Spam-Anfragen (Rate Limiting) serverseitig verwerfen", function()
			local request = {
				DeityId = "old_forest_spirit",
				GridCoords = Vector3.new(2, 0, 2),
				Rotation = 0
			}
			
			-- Simuliere 5 direkte, hochfrequente RPC-Anfragen auf demselben Thread
			for i = 1, 5 do
				PlacementModule.HandlePlacementRequest(testPlayer, request.DeityId, request.GridCoords, request.Rotation)
			end
			
			local state = PlayerDataStore.getPlayerState(testPlayer)
			-- Nur die allererste Platzierung durfte erfolgreich sein. Die restlichen 4 müssen blockiert werden.
			expect(state.Belief).to.equal(500) -- Genau eine Abbuchung
		end)
	end)
end
