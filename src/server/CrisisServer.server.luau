--!strict
-- Platziert in: src/server/CrisisServer.server.luau

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local CrisisModule = require(ServerScriptService.Server.modules.CrisisModule)

-- Dynamische Anpassung des Intervalls: 15 Sekunden in Studio für rapid-testing, 120 Sekunden im Live-Spiel!
local SPAWN_INTERVAL = 120
if RunService:IsStudio() then
	SPAWN_INTERVAL = 15
	print("[CrisisServer] Studio-Modus erkannt: Katastrophen-Intervall auf 15 Sekunden gesetzt.")
else
	print("[CrisisServer] Live-Modus: Katastrophen-Intervall auf 120 Sekunden gesetzt.")
end

-- Periodische Schleife zur Erzeugung von Katastrophen
task.spawn(function()
	while true do
		task.wait(SPAWN_INTERVAL)
		
		local activePlayers = Players:GetPlayers()
		if #activePlayers > 0 then
			-- Wähle einen zufälligen aktiven Spieler aus
			local randomPlayer = activePlayers[math.random(1, #activePlayers)]
			
			-- Spawne eine Katastrophe auf dessen Zitadellengitter
			pcall(function()
				CrisisModule.SpawnCrisis(randomPlayer)
			end)
		end
	end
end)

print("[CrisisServer] Asynchroner Katastrophen-Spanner erfolgreich gestartet.")
