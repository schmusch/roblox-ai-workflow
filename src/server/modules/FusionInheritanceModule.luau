--!strict
-- Platziert in: src/server/modules/FusionInheritanceModule.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Clone-Bypass für DeityCatalog, um Caching-Probleme in Edit-Mode Unit-Tests zu tilgen
local DeityCatalog = require(ReplicatedStorage.Shared.DeityCatalog:Clone())

type DeityConfig = DeityCatalog.DeityConfig

local FusionInheritanceModule = {}

-- Berechnet die Vererbungswahrscheinlichkeit für den besseren Statuswert basierend auf der Stimulation S
-- Formel: P_besser = (1.0 + 0.01 * S) / (2.0 + 0.01 * S)
function FusionInheritanceModule.CalculateSuperiorInheritanceChance(S: number): number
	local stimulation = math.clamp(S, 0, 100)
	if stimulation == 100 then
		return 1.0
	end
	return (1.0 + 0.01 * stimulation) / (2.0 + 0.01 * stimulation)
end

-- Prüft, ob die Eltern-Gottheiten für eine Fusion zulässig sind (Stabilisierte Hybride blockieren!)
function FusionInheritanceModule.VerifyParents(parentA: DeityConfig, parentB: DeityConfig): (boolean, string?)
	if parentA.IsStabilized then
		return false, string.format("Gottheit '%s' ist bereits stabilisiert und kann nicht erneut fusioniert werden!", parentA.Id)
	end
	if parentB.IsStabilized then
		return false, string.format("Gottheit '%s' ist bereits stabilisiert und kann nicht erneut fusioniert werden!", parentB.Id)
	end
	return true, nil
end

-- Generiert eine neue hybride DeityConfig unter Anwendung Mendelscher Vererbungsgesetze, Komfortwerte und Mutationen
function FusionInheritanceModule.GenerateHybrid(
	parentA: DeityConfig,
	parentB: DeityConfig,
	S: number,
	comfort: number?,
	roomClass: string?,
	customRandom: (() -> number)?
): (DeityConfig, string?)
	-- 1. Zulässigkeit prüfen
	local isAllowed, err = FusionInheritanceModule.VerifyParents(parentA, parentB)
	if not isAllowed then
		return nil :: any, err
	end

	-- 2. Komfort-Sperre prüfen (Mindestkomfort 10 erforderlich)
	local c = comfort or 100
	if c < 10 then
		return nil :: any, "Raumkomfort zu gering! Mindestkomfort von 10 erforderlich."
	end

	local rand = customRandom or math.random
	local P_besser = FusionInheritanceModule.CalculateSuperiorInheritanceChance(S)

	-- Hilfsfunktion zur Vererbung eines einzelnen Wertes
	local function inheritStat(valA: number, valB: number): number
		if valA == valB then
			return valA
		end

		local betterVal = math.max(valA, valB)
		local worseVal = math.min(valA, valB)

		if rand() <= P_besser then
			return betterVal
		else
			return worseVal
		end
	end

	local hybridHP = inheritStat(parentA.BaseHP, parentB.BaseHP)
	local hybridAttack = inheritStat(parentA.BaseAttack, parentB.BaseAttack)
	local hybridSpeed = inheritStat(parentA.BaseSpeed, parentB.BaseSpeed)

	-- 3. Mutationssteuerung bei maximiertem Komfort (c == 100)
	local talent: string? = nil
	if c == 100 and roomClass then
		-- Mutation triggert mit 20% Wahrscheinlichkeit (roll <= 0.2)
		local roll = rand()
		if roll <= 0.20 then
			if roomClass == "Barracks" then
				hybridAttack = math.floor(hybridAttack * 1.20) -- Kriegszorn: +20% Angriffskraft!
				talent = "Kriegszorn"
			elseif roomClass == "Royal" then
				hybridHP = math.floor(hybridHP * 1.20) -- Göttlicher Segen: +20% HP!
				talent = "GöttlicherSegen"
			end
		end
	end

	-- Erzeugt eine neue, stabilisierte Hybrid-Konfiguration
	local hybridId = string.format("hybrid__%s__%s", parentA.Id, parentB.Id)
	local hybridName = string.format("Stabilisierter Hybrid (%s + %s)", parentA.Name, parentB.Name)

	local hybridConfig: DeityConfig = {
		Id = hybridId,
		Name = hybridName,
		Faction = parentA.Faction,
		Element = parentA.Element,
		Role = parentA.Role,
		AttackRange = math.max(parentA.AttackRange, parentB.AttackRange),
		BasePrice = math.floor((parentA.BasePrice + parentB.BasePrice) * 0.75),
		BaseProduction = math.floor((parentA.BaseProduction + parentB.BaseProduction) * 0.8),
		BaseRadius = math.max(parentA.BaseRadius, parentB.BaseRadius),
		BaseOmega = (parentA.BaseOmega + parentB.BaseOmega) * 0.5,
		BaseHP = hybridHP,
		BaseAttack = hybridAttack,
		BaseSpeed = hybridSpeed,
		IsStabilized = true,
		Talent = talent, -- Persistentes passive Talent!
	}

	return hybridConfig, nil
end

return FusionInheritanceModule
