--!strict
-- Platziert in: src/server/EpochServer.server.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EpochModule = require(ServerScriptService.Server.modules.EpochModule)

local Events = ReplicatedStorage:WaitForChild("Events") :: Folder

-- RemoteEvent initialisieren
local triggerPrestigeRemote = Events:FindFirstChild("TriggerPrestige")
if not triggerPrestigeRemote then
	local remote = Instance.new("RemoteEvent")
	remote.Name = "TriggerPrestige"
	remote.Parent = Events
	triggerPrestigeRemote = remote
end

-- Lauscht auf Prestige-Reset Signale vom Client
local triggerPrestige = triggerPrestigeRemote :: RemoteEvent
triggerPrestige.OnServerEvent:Connect(function(player: Player)
	local success, err = EpochModule.TriggerPrestige(player)
	
	-- Feedback an den Client senden, falls erwünscht (wir können ein Client-Event feuern oder Attribute setzen)
	if not success then
		warn(string.format("[EpochServer] Prestige-Anfrage von Spieler %s abgewiesen: %s", player.Name, tostring(err)))
		pcall(function()
			(player :: any):SetAttribute("CitadelPrestigeError", err)
		end)
	else
		print(string.format("[EpochServer] Prestige-Anfrage von Spieler %s erfolgreich verarbeitet.", player.Name))
		pcall(function()
			(player :: any):SetAttribute("CitadelPrestigeError", nil)
		end)
	end
end)

print("[EpochServer] Prestige-Listener erfolgreich gestartet.")
