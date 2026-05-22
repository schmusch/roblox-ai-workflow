--!strict
-- Platziert in: src/server/PlacementServer.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlacementModule = require(ServerScriptService.Server.modules.PlacementModule)

local Events = ReplicatedStorage:WaitForChild("Events") :: Folder

-- RemoteEvent erstellen, falls noch nicht vorhanden
local placementRemote = Events:FindFirstChild("PlacementRemote")
if not placementRemote then
	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = "PlacementRemote"
	newRemote.Parent = Events
	placementRemote = newRemote
end

-- Auf Platzierungsanfragen vom Client lauschen
(placementRemote :: RemoteEvent).OnServerEvent:Connect(function(player: Player, deityId: any, gridCoords: any, rotation: any)
	PlacementModule.HandlePlacementRequest(player, deityId, gridCoords, rotation)
end)

print("[PlacementServer] Initialisiert. Lauscht auf PlacementRemote Events.")
