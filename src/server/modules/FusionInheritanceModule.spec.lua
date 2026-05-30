--!strict
-- Platziert in: src/server/modules/FusionInheritanceModule.spec.lua

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local PlayerDataStore = require(script.Parent.PlayerDataStore)
	local DeityCatalog = require(ReplicatedStorage.Shared.DeityCatalog:Clone())
	local FusionInheritanceModule = require(script.Parent.FusionInheritanceModule)
	local FusionTransactionModule = require(script.Parent.FusionTransactionModule)

	describe("FusionInheritanceModule - Mendelsches Vererbungssystem & Entkoppelung (Epic 4.3)", function()
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
				Name = "TestInheritancePlayer",
				UserId = 99999,
				ClassName = "Player",
				_attributes = {},
			}, MockPlayer) :: any
			
			FusionTransactionModule.ClearAll()
		end)

		afterEach(function()
			PlayerDataStore.clearPlayerState(mockPlayer)
			FusionTransactionModule.ClearAll()
		end)

		describe("Stimulations-Formel & Wahrscheinlichkeitsberechnung", function()
			it("sollte bei Stimulation S = 0 exakt 50% Vererbungschance für den besseren Wert liefern", function()
				local P = FusionInheritanceModule.CalculateSuperiorInheritanceChance(0)
				expect(math.abs(P - 0.50) < 0.001).to.equal(true)
			end)

			it("sollte bei Stimulation S = 50 exakt 60% Vererbungschance für den besseren Wert liefern", function()
				local P = FusionInheritanceModule.CalculateSuperiorInheritanceChance(50)
				expect(math.abs(P - 0.60) < 0.001).to.equal(true)
			end)

			it("sollte bei Stimulation S = 100 exakt 100% Vererbungschance für den besseren Wert liefern", function()
				local P = FusionInheritanceModule.CalculateSuperiorInheritanceChance(100)
				expect(math.abs(P - 1.00) < 0.001).to.equal(true)
			end)
		end)

		describe("Mendelsche Vererbungs-Mechanik", function()
			local parentA: DeityCatalog.DeityConfig
			local parentB: DeityCatalog.DeityConfig

			beforeEach(function()
				-- Forest Spirit (HP: 100, Attack: 10, Speed: 8)
				parentA = DeityCatalog.GetProfile(101)
				-- Sun Temple (HP: 250, Attack: 25, Speed: 4)
				parentB = DeityCatalog.GetProfile(102)
			end)

			it("sollte bei S = 100 (100% Chance) ausnahmslos alle überlegenen Basiswerte der Eltern vererben", function()
				local hybrid, err = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 100)
				expect(err).to.equal(nil)
				expect(hybrid).to.never.equal(nil)

				-- Bessere Werte: HP 250 (von B), Attack 25 (von B), Speed 8 (von A)
				expect(hybrid.BaseHP).to.equal(250)
				expect(hybrid.BaseAttack).to.equal(25)
				expect(hybrid.BaseSpeed).to.equal(8)
				expect(hybrid.IsStabilized).to.equal(true) -- Flag muss gesetzt sein!
			end)

			it("sollte bei S = 0 mit determiniertem customRandom entweder bessere oder schlechtere Werte vererben", function()
				-- Custom Random-Funktion, die 0.2 zurückgibt (also <= 0.5 -> Bessere Werte vererben)
				local mockRandBetter = function() return 0.2 end
				local hybridBetter, errBetter = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 0, nil, nil, mockRandBetter)
				expect(errBetter).to.equal(nil)
				expect(hybridBetter.BaseHP).to.equal(250)
				expect(hybridBetter.BaseAttack).to.equal(25)
				expect(hybridBetter.BaseSpeed).to.equal(8)

				-- Custom Random-Funktion, die 0.8 zurückgibt (also > 0.5 -> Schlechtere Werte vererben)
				local mockRandWorse = function() return 0.8 end
				local hybridWorse, errWorse = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 0, nil, nil, mockRandWorse)
				expect(errWorse).to.equal(nil)
				expect(hybridWorse.BaseHP).to.equal(100)
				expect(hybridWorse.BaseAttack).to.equal(10)
				expect(hybridWorse.BaseSpeed).to.equal(4)
			end)

			it("sollte Fusionsversuche blockieren, wenn mindestens ein Elternteil bereits ein stabilisierter Hybrid ist", function()
				local hybridParent = {
					Id = "hybrid__old_forest_spirit__sun_temple",
					Name = "Hybrid Parent",
					Faction = "AlteGoetter" :: any,
					Element = "Erde" :: any,
					Role = "Supporter" :: any,
					AttackRange = 4.0,
					BasePrice = 600,
					BaseProduction = 20,
					BaseRadius = 15,
					BaseOmega = 0.5,
					BaseHP = 250,
					BaseAttack = 25,
					BaseSpeed = 8,
					IsStabilized = true -- Stabilisiert!
				}

				local success, err = FusionInheritanceModule.GenerateHybrid(parentA, hybridParent, 50)
				expect(success).to.equal(nil)
				expect(string.find(err or "", "bereits stabilisiert") ~= nil).to.equal(true)
			end)
		end)

		describe("Entkoppelungssystem (Unfusing)", function()
			it("sollte eine gültige Hybrid-Gottheit entkoppeln und Elternteile sowie Gebühren korrekt verbuchen", function()
				-- Setup: Spieler besitzt den Hybrid und 300 Belief
				PlayerDataStore.setPlayerState(mockPlayer, {
					Belief = 300,
					Inventory = {
						["hybrid__old_forest_spirit__sun_temple"] = 1
					},
					LastSaveTime = os.time()
				})

				local success, err = FusionTransactionModule.UnfuseHybrid(mockPlayer, "hybrid__old_forest_spirit__sun_temple", 100)
				expect(success).to.equal(true)
				expect(err).to.equal(nil)

				-- Prüfen, ob die Ressourcen korrekt verbucht wurden
				local state = PlayerDataStore.getPlayerState(mockPlayer)
				expect(state.Belief).to.equal(200) -- 300 - 100 Gebühr
				expect(state.Inventory["hybrid__old_forest_spirit__sun_temple"]).to.equal(nil) -- Gelöscht
				expect(state.Inventory["old_forest_spirit"]).to.equal(1) -- Wiederhergestellt!
				expect(state.Inventory["sun_temple"]).to.equal(1) -- Wiederhergestellt!
			end)

			it("sollte das Entkoppeln blockieren, wenn das Glaubensguthaben zu gering ist", function()
				PlayerDataStore.setPlayerState(mockPlayer, {
					Belief = 50, -- Zu gering für 100 Gebühr!
					Inventory = {
						["hybrid__old_forest_spirit__sun_temple"] = 1
					},
					LastSaveTime = os.time()
				})

				local success, err = FusionTransactionModule.UnfuseHybrid(mockPlayer, "hybrid__old_forest_spirit__sun_temple", 100)
				expect(success).to.equal(false)
				expect(err).to.equal("Nicht genügend Glaubenspunkte für die Entkoppelungsgebühr!")

				-- Stand unverändert
				local state = PlayerDataStore.getPlayerState(mockPlayer)
				expect(state.Belief).to.equal(50)
				expect(state.Inventory["hybrid__old_forest_spirit__sun_temple"]).to.equal(1)
			end)
		end)

		describe("Raumkomfort & Mutations-Steuerung (Epic 4.4)", function()
			local parentA: DeityCatalog.DeityConfig
			local parentB: DeityCatalog.DeityConfig

			beforeEach(function()
				parentA = DeityCatalog.GetProfile(101) -- Forest Spirit (HP: 100, Attack: 10)
				parentB = DeityCatalog.GetProfile(102) -- Sun Temple (HP: 250, Attack: 25)
			end)

			it("sollte Fusionen strikt ablehnen, wenn der Komfort unter 10 liegt", function()
				local hybrid, err = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 50, 5) -- Komfort 5
				expect(hybrid).to.equal(nil)
				expect(string.find(err or "", "Raumkomfort zu gering") ~= nil).to.equal(true)
			end)

			it("sollte Fusionen zulassen, wenn der Komfort genau 10 beträgt", function()
				local hybrid, err = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 50, 10) -- Komfort 10 (Minimum)
				expect(err).to.equal(nil)
				expect(hybrid).to.never.equal(nil)
			end)

			it("sollte bei maximalem Komfort und Klasse 'Barracks' mit erfolgreichem Roll das Talent 'Kriegszorn' (+20% Attack) vergeben", function()
				-- Custom Random-Funktion: Liefert 1.0 (für S=100 Vererbungsgewährleistung) und 0.1 (für Mutations-Roll <= 0.20)
				local rolls = { 1.0, 0.1 }
				local rollIndex = 0
				local mockRand = function()
					rollIndex = rollIndex + 1
					return rolls[rollIndex] or 0.1
				end

				local hybrid, err = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 100, 100, "Barracks", mockRand)
				expect(err).to.equal(nil)
				expect(hybrid).to.never.equal(nil)
				expect(hybrid.Talent).to.equal("Kriegszorn")
				expect(hybrid.BaseAttack).to.equal(30) -- 25 * 1.20 = 30
			end)

			it("sollte bei maximalem Komfort und Klasse 'Royal' mit erfolgreichem Roll das Talent 'GöttlicherSegen' (+20% HP) vergeben", function()
				local rolls = { 1.0, 0.1 }
				local rollIndex = 0
				local mockRand = function()
					rollIndex = rollIndex + 1
					return rolls[rollIndex] or 0.1
				end

				local hybrid, err = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 100, 100, "Royal", mockRand)
				expect(err).to.equal(nil)
				expect(hybrid).to.never.equal(nil)
				expect(hybrid.Talent).to.equal("GöttlicherSegen")
				expect(hybrid.BaseHP).to.equal(300) -- 250 * 1.20 = 300
			end)

			it("sollte keine Mutation vergeben, wenn der Random Roll fehlschlägt", function()
				local rolls = { 1.0, 0.5 } -- 0.5 > 0.20 -> Mutations-Roll fehlgeschlagen
				local rollIndex = 0
				local mockRand = function()
					rollIndex = rollIndex + 1
					return rolls[rollIndex] or 0.5
				end

				local hybrid, err = FusionInheritanceModule.GenerateHybrid(parentA, parentB, 100, 100, "Barracks", mockRand)
				expect(err).to.equal(nil)
				expect(hybrid).to.never.equal(nil)
				expect(hybrid.Talent).to.equal(nil)
				expect(hybrid.BaseAttack).to.equal(25) -- Unverändert 25
			end)
		end)
	end)
end
