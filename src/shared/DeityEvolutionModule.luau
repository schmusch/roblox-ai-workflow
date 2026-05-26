--!strict
-- Platziert in: src/shared/DeityEvolutionModule.luau

local DeityEvolutionModule = {}

-- Berechnet den orbitalen Radius R_L basierend auf dem Basisradius R_0 und dem Level L.
-- Formel: R_L = R_0 * (1 + ln(L + 1))
function DeityEvolutionModule.CalculateRadius(baseRadius: number, level: number): number
	-- Sicherstellen, dass das Level nicht unter 1 fällt (Mindestlevel ist 1)
	local l = math.max(1, level)
	return baseRadius * (1 + math.log(l + 1))
end

-- Berechnet die Rotationsgeschwindigkeit w_L basierend auf der Basisgeschwindigkeit w_0 und dem Level L.
-- Formel: w_L = w_0 / sqrt(L + 1)
function DeityEvolutionModule.CalculateOmega(baseOmega: number, level: number): number
	local l = math.max(1, level)
	return baseOmega / math.sqrt(l + 1)
end

return DeityEvolutionModule
