--!strict
-- Platziert in: src/server/modules/EpochModule.luau

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataStore = require(script.Parent.PlayerDataStore)
local GridModule = require(script.Parent.GridModule)
local MantissaExponentModule = require(ReplicatedStorage.Shared.MantissaExponentModule)

local EpochModule = {}

-- Definition aller hybriden Gottheits-IDs für den Epochenübergang
local HYBRID_DEITIES = {
	["sun_temple"] = true
}

-- Kriterium für Prestige-Reset: 1 Milliarde Belief (10^9)
local MIN_BELIEF_REQUIREMENT = 1000000000

-- Basis-Konvertierungskonstante für die erste Epoche (skaliert exponentiell)
local BASE_CONVERSION_CONSTANT = 1000000000

-- Überprüft, ob ein Spieler bereit für den Epochenübergang (Prestige-Reset) ist
function EpochModule.CanPrestige(player: Player): (boolean, string?)
	local state = PlayerDataStore.getPlayerState(player)
	
	-- 1. Belief-Prüfung (Mindestens 10^9)
	if state.Belief < MIN_BELIEF_REQUIREMENT then
		return false, string.format("Nicht genügend Glauben! Benötigt 1,000,000,000 ✨ (Aktuell: %.0f ✨)", state.Belief)
	end

	-- 2. Hybrid-Gottheiten-Besitzprüfung (Entweder platziert oder im Inventar owned)
	local hasHybrid = false
	
	-- Inventar prüfen
	for deityId, count in pairs(state.Inventory) do
		if HYBRID_DEITIES[deityId] and count > 0 then
			hasHybrid = true
			break
		end
	end
	
	-- Gitter prüfen (falls bereits platziert)
	if not hasHybrid then
		local grid = GridModule.GetOrCreateGrid(player)
		for _, obj in pairs(grid.Objects) do
			if HYBRID_DEITIES[obj.DeityId] then
				hasHybrid = true
				break
			end
		end
	end

	if not hasHybrid then
		return false, "Eine hybride Gottheit erforderlich (z. B. Sun Temple)!"
	end

	return true, nil
end

-- Führt den Prestige-Reset aus und transitioned in eine neue Epoche
function EpochModule.TriggerPrestige(player: Player): (boolean, string?)
	local canPrestige, err = EpochModule.CanPrestige(player)
	if not canPrestige then
		return false, err
	end

	local state = PlayerDataStore.getPlayerState(player)
	local currentEpoch = player:GetAttribute("CitadelEpoch") or 0

	-- 1. Berechne Sakrale Funken (Prestige-Währung) mittels Mantissa-Exponent-Überlaufschutz
	-- Formel: Sparks = floor( sqrt( B / C_epoche ) )
	-- C_epoche = 10^9 * 10^epoche
	local scalingConstant = BASE_CONVERSION_CONSTANT * math.pow(10, currentEpoch)
	
	local beliefBig = MantissaExponentModule.fromNumber(state.Belief)
	local constantBig = MantissaExponentModule.fromNumber(scalingConstant)
	
	-- Division: B / C
	local divisionBig = MantissaExponentModule.divide(beliefBig, constantBig)
	
	-- Wurzel: sqrt(B / C)
	local sqrtBig = MantissaExponentModule.sqrt(divisionBig)
	
	-- Konvertierung zurück und Runden
	local rawSparks = MantissaExponentModule.toNumber(sqrtBig)
	local newSparks = math.floor(rawSparks)

	if newSparks <= 0 then
		return false, "Berechnung ergab 0 Sakrale Funken. Prestige nicht lohnenswert!"
	end

	-- 2. Spielfeld geometrisch und physisch leeren (GridModule)
	GridModule.ClearGrid(player)

	-- 3. Glaubenskonto auf 0 zurücksetzen
	state.Belief = 0

	-- 4. Epoche inkrementieren und Sakrale Funken hinzufügen
	local nextEpoch = currentEpoch + 1
	local currentSparks = player:GetAttribute("CitadelSacralSparks") or 0
	local totalSparks = currentSparks + newSparks

	-- Attribute synchronisieren (für Client-Replikation und UI)
	pcall(function()
		player:SetAttribute("CitadelEpoch", nextEpoch)
		player:SetAttribute("CitadelSacralSparks", totalSparks)
		player:SetAttribute("CitadelBelief", 0)
		player:SetAttribute("CitadelBeliefRate", 0)
	end)

	print(string.format("[EpochModule] Prestige erfolgreich für %s! Epoche %d erreicht (+%d Funken, Gesamt: %d).", 
		player.Name, nextEpoch, newSparks, totalSparks))

	return true, nil
end

return EpochModule
