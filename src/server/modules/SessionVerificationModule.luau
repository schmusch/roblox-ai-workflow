--!strict
-- Platziert in: src/server/modules/SessionVerificationModule.luau

local SessionVerificationModule = {}

-- Konstanten für die gedämpfte Offline-Progression
local TIME_CAP_SECONDS = 43200 -- 12 Stunden
local DAMPING_FACTOR = 0.10 -- 90% Dämpfung (verbleibende 10%)

-- Berechnet die Offline-Einnahmen auf Basis der absoluten Unix-Zeitstempel und der Glaubensrate.
-- Formel: B_offline = R_p * (t_effektiv + gamma * t_overflow)
function SessionVerificationModule.CalculateOfflineEarnings(
	player: Player, 
	lastSaveTime: number, 
	nowTime: number, 
	beliefRate: number
): number
	-- Schutz vor ungültigen/zukünftigen Zeitwerten (Anti-Speedhack / Zeitreise-Schutz)
	local deltaTime = nowTime - lastSaveTime
	if deltaTime <= 0 then
		return 0
	end

	-- Effektive ungedämpfte Zeit (maximal 12 Stunden)
	local effectiveTime = math.min(deltaTime, TIME_CAP_SECONDS)

	-- Ungedämpfte Overflow-Zeit über 12 Stunden
	local overflowTime = math.max(0, deltaTime - TIME_CAP_SECONDS)

	-- Berechne die gedämpfte Einnahmenzeit
	local totalEarningsTime = effectiveTime + (overflowTime * DAMPING_FACTOR)

	-- Berechne die finalen Belief-Einnahmen
	local offlineEarnings = beliefRate * totalEarningsTime

	-- Ganzzahlig runden für saubere Währungseinheiten
	return math.floor(offlineEarnings)
end

return SessionVerificationModule
