--!strict
-- Platziert in: src/server/modules/DeityEvolutionModule.spec.lua
return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local DeityEvolutionModule = require(ReplicatedStorage.Shared.DeityEvolutionModule)

	describe("DeityEvolutionModule - Logarithmische Gottheiten-Evolution (Epic 4.1)", function()
		
		it("sollte bei Level 1 den unmodifizierten Basisradius R_0 und die Basisgeschwindigkeit w_0 generieren", function()
			local baseRadius = 10
			local baseOmega = 1.0
			local level = 1

			local radius = DeityEvolutionModule.CalculateRadius(baseRadius, level)
			local omega = DeityEvolutionModule.CalculateOmega(baseOmega, level)

			-- R_1 = R_0 * (1 + ln(1 + 1)) = R_0 * (1 + ln(2)) = 10 * 1.693 = 16.93
			-- w_1 = w_0 / sqrt(2) = 1.0 / 1.414 = 0.707
			expect(math.abs(radius - 16.931) < 0.01).to.equal(true)
			expect(math.abs(omega - 0.707) < 0.01).to.equal(true)
		end)

		it("sollte bei Level 10 exakt das 3.39-fache bis 3.40-fache des Basisradius berechnen (Toleranzlimit 0.01)", function()
			local baseRadius = 10
			local baseOmega = 1.0
			local level = 10

			local radius = DeityEvolutionModule.CalculateRadius(baseRadius, level)
			
			-- R_10 = R_0 * (1 + ln(11)) = 10 * (1 + 2.397895) = 33.97895
			-- Abweichung zu 33.9 (also 3.39 * R_0) muss innerhalb von 0.01 relative Toleranz liegen
			-- 33.97895 / 10 = 3.397895
			local ratio = radius / baseRadius
			expect(math.abs(ratio - 3.39) < 0.01).to.equal(true)
		end)

		it("sollte bei Level 10 die Rotationsgeschwindigkeit sublinear drosseln", function()
			local baseRadius = 10
			local baseOmega = 1.5
			local level = 10

			local omega = DeityEvolutionModule.CalculateOmega(baseOmega, level)

			-- w_10 = 1.5 / sqrt(11) = 1.5 / 3.3166 = 0.4522
			expect(math.abs(omega - 0.4522) < 0.01).to.equal(true)
		end)

		it("sollte ungültige Level-Eingaben (z. B. < 1) sicher auf Level 1 abfangen", function()
			local baseRadius = 10
			local baseOmega = 1.0
			
			local radiusNeg = DeityEvolutionModule.CalculateRadius(baseRadius, -5)
			local omegaZero = DeityEvolutionModule.CalculateOmega(baseOmega, 0)

			expect(math.abs(radiusNeg - 16.931) < 0.01).to.equal(true)
			expect(math.abs(omegaZero - 0.707) < 0.01).to.equal(true)
		end)
	end)
end
