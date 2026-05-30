--!strict
-- Platziert in: src/server/modules/SessionVerificationModule.spec.lua
return function()
	local SessionVerificationModule = require(script.Parent.SessionVerificationModule)

	describe("SessionVerificationModule - Anti-Speedhack & gedämpfte Offline-Progression (Epic 2.4)", function()
		local mockPlayer: Player

		beforeEach(function()
			mockPlayer = {
				Name = "TestPlayer",
				UserId = 12345,
				ClassName = "Player",
			} :: any
		end)

		it("sollte bei 10 Stunden (36000s) ohne Dämpfung 100% Einnahmen generieren", function()
			local lastSave = 1000000
			local now = 1036000 -- 10 Stunden Differenz
			local beliefRate = 5 -- 5 Belief pro Sekunde

			local earnings = SessionVerificationModule.CalculateOfflineEarnings(mockPlayer, lastSave, now, beliefRate)
			
			-- 5 * 36000 = 180000
			expect(earnings).to.equal(180000)
		end)

		it("sollte bei 24 Stunden (86400s) exakt 55% der ungedämpften Einnahmen generieren (Dämpfung jenseits 12 Stunden)", function()
			local lastSave = 1000000
			local now = 1086400 -- 24 Stunden Differenz
			local beliefRate = 5

			local earnings = SessionVerificationModule.CalculateOfflineEarnings(mockPlayer, lastSave, now, beliefRate)
			
			-- Erwartete Zeitberechnung:
			-- t_effektiv = 43200s (12 Stunden)
			-- t_overflow = 43200s (weitere 12 Stunden)
			-- damped_overflow = 43200 * 0.10 = 4320s
			-- total_earning_time = 43200 + 4320 = 47520s
			-- Einnahmen = 5 * 47520 = 237600
			-- (Zum Vergleich: Ungedämpfte Einnahmen wären 5 * 86400 = 432000, 237600 / 432000 = 0.55!)
			expect(earnings).to.equal(237600)
		end)

		it("sollte Zeitreise-Exploits (negative Zeitdifferenzen oder Delta = 0) abfangen und 0 Einnahmen generieren", function()
			local lastSave = 1000000
			local nowNormal = 1000000 -- Delta = 0
			local nowExploit = 900000  -- Delta = -100000 (Zeitreise)
			local beliefRate = 10

			local earningsNormal = SessionVerificationModule.CalculateOfflineEarnings(mockPlayer, lastSave, nowNormal, beliefRate)
			local earningsExploit = SessionVerificationModule.CalculateOfflineEarnings(mockPlayer, lastSave, nowExploit, beliefRate)

			expect(earningsNormal).to.equal(0)
			expect(earningsExploit).to.equal(0)
		end)
	end)
end
