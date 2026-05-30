--!strict
-- Platziert in: src/server/modules/EpochModule.spec.lua
return function()
	local EpochModule = require(script.Parent.EpochModule)
	local PlayerDataStore = require(script.Parent.PlayerDataStore)
	local GridModule = require(script.Parent.GridModule)

	describe("EpochModule - Synkretistischer Epochenübergang / Rebirth-System (Epic 2.5)", function()
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
			GridModule.ClearGrid(mockPlayer)
		end)

		it("sollte den Prestige-Reset ablehnen, wenn weniger als 1,000,000,000 Belief vorhanden sind", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 500000000, -- Nur 500 Mio.
				Inventory = { ["sun_temple"] = 1 }
			})

			local success, err = EpochModule.TriggerPrestige(mockPlayer)
			expect(success).to.equal(false)
			expect(err).to.be.ok()
			expect(err:find("Nicht genügend Glauben", 1, true)).to.be.ok()
		end)

		it("sollte den Prestige-Reset abweisen, wenn keine hybride Gottheit owned ist (Besitzprüfung)", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 2000000000, -- 2 Milliarden (Genug!)
				Inventory = { ["old_forest_spirit"] = 10 } -- Keine sun_temple!
			})

			local success, err = EpochModule.TriggerPrestige(mockPlayer)
			expect(success).to.equal(false)
			expect(err).to.be.ok()
			expect(err:find("Eine hybride Gottheit erforderlich", 1, true)).to.be.ok()
		end)

		it("sollte bei Erfüllung aller Kriterien den Glaubensstand auf 0 und das Gitter leeren", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 1000000000, -- Genau 1 Milliarde
				Inventory = { ["sun_temple"] = 1 }
			})

			-- Monument auf dem Gitter platzieren
			local grid = GridModule.GetOrCreateGrid(mockPlayer)
			GridModule.PlaceObject(mockPlayer, "sun_temple", 1, 1, 0)
			
			-- Sicherstellen, dass das Objekt auf dem Gitter liegt
			local countBefore = 0
			for _ in pairs(grid.Objects) do countBefore += 1 end
			expect(countBefore).to.equal(1)

			-- Belief vorübergehend wieder auf 1 Milliarde füllen (da PlaceObject Belief abgezogen hat)
			PlayerDataStore.getPlayerState(mockPlayer).Belief = 1000000000

			-- Prestige triggern
			local success, err = EpochModule.TriggerPrestige(mockPlayer)
			expect(success).to.equal(true)
			expect(err).to.never.be.ok()

			-- Kontostand und Gitter müssen leer sein!
			local state = PlayerDataStore.getPlayerState(mockPlayer)
			expect(state.Belief).to.equal(0)

			local countAfter = 0
			for _ in pairs(grid.Objects) do countAfter += 1 end
			expect(countAfter).to.equal(0)
		end)

		it("sollte die sakralen Funken sublinear und präzise auf Basis des MantissaExponentModule berechnen", function()
			PlayerDataStore.setPlayerState(mockPlayer, {
				Belief = 4000000000, -- 4 Milliarden Belief
				Inventory = { ["sun_temple"] = 1 }
			})

			-- C_epoche bei Epoche 0 = 10^9
			-- Sparks = floor(sqrt(4 * 10^9 / 10^9)) = floor(sqrt(4)) = 2 Sparks!
			local success, err = EpochModule.TriggerPrestige(mockPlayer)
			expect(success).to.equal(true)
			expect(err).to.never.be.ok()

			-- Sparks prüfen
			local sparks = mockPlayer:GetAttribute("CitadelSacralSparks")
			expect(sparks).to.equal(2)
			
			-- Neue Epoche muss 1 sein
			local epoch = mockPlayer:GetAttribute("CitadelEpoch")
			expect(epoch).to.equal(1)
		end)
	end)
end
