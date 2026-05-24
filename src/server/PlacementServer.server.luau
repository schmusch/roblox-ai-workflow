--!strict
-- Platziert in: src/server/PlacementServer.server.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

local PlacementModule = require(ServerScriptService.Server.modules.PlacementModule)
local PlayerDataStore = require(ServerScriptService.Server.modules.PlayerDataStore)
local GridModule = require(ServerScriptService.Server.modules.GridModule)
local GridConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GridConfig") :: ModuleScript)

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

-- Startguthaben für beitretende Spieler einrichten (2000 Belief, Gottheiten im Inventar)
local function onPlayerAdded(player: Player)
	local state = PlayerDataStore.getPlayerState(player)
	state.Belief = 2000
	state.Inventory["old_forest_spirit"] = 5
	state.Inventory["sun_temple"] = 2
	state.Inventory["water_shrine"] = 4
	
	-- Gitter für den Spieler vorausinitialisieren (für den Wirtschaftskreislauf)
	GridModule.GetOrCreateGrid(player)
	
	-- Native Attribute für Replikation an das Client-UI setzen
	pcall(function()
		player:SetAttribute("CitadelBelief", 2000)
		player:SetAttribute("CitadelBeliefRate", 0)
		player:SetAttribute("CitadelInventory", HttpService:JSONEncode(state.Inventory))
	end)
	
	print(string.format("[PlacementServer] Startguthaben für %s initialisiert: 2000 Belief, Gitter vorausinitialisiert.", player.Name))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Visualisierung des Gitters in Workspace (10x10, zentriert auf 0,0,0)
local function createGridVisualization()
	local gridFolder = workspace:FindFirstChild("CitadelGrid")
	if gridFolder then
		gridFolder:Destroy() -- Frischen Stand erzwingen
	end
	
	gridFolder = Instance.new("Folder")
	gridFolder.Name = "CitadelGrid"
	gridFolder.Parent = workspace
	
	local settings = GridConfig.Settings
	local halfSizeX = (settings.SizeX * settings.CellSize) / 2
	local halfSizeZ = (settings.SizeZ * settings.CellSize) / 2
	local fullSizeX = settings.SizeX * settings.CellSize
	local fullSizeZ = settings.SizeZ * settings.CellSize
	
	-- 1. Dunkle, edle Bodenplatte als Zitadellen-Fundament
	local baseplate = Instance.new("Part")
	baseplate.Name = "GridBaseplate"
	baseplate.Size = Vector3.new(fullSizeX, 0.2, fullSizeZ)
	baseplate.CFrame = CFrame.new(0, -0.1, 0)
	baseplate.Material = Enum.Material.SmoothPlastic
	baseplate.Color = Color3.fromRGB(20, 22, 28) -- Sehr edles Dunkelgrau
	baseplate.Anchored = true
	baseplate.CanCollide = true
	baseplate.Parent = gridFolder
	
	-- 2. Dünne, leuchtende Gitterlinien prozedural generieren (Neon-Cyan, leicht transparent)
	local lineColor = Color3.fromRGB(0, 170, 255) -- Cyan-Blau
	local lineTransparency = 0.65
	
	-- Linien parallel zur X-Achse
	for i = 0, settings.SizeZ do
		local zVal = -halfSizeZ + (i * settings.CellSize)
		local line = Instance.new("Part")
		line.Name = "GridLine_X_" .. i
		line.Size = Vector3.new(fullSizeX, 0.05, 0.1)
		line.CFrame = CFrame.new(0, 0.01, zVal)
		line.Material = Enum.Material.Neon
		line.Color = lineColor
		line.Transparency = lineTransparency
		line.Anchored = true
		line.CanCollide = false
		line.CanTouch = false
		line.CanQuery = false
		line.Parent = gridFolder
	end
	
	-- Linien parallel zur Z-Achse
	for i = 0, settings.SizeX do
		local xVal = -halfSizeX + (i * settings.CellSize)
		local line = Instance.new("Part")
		line.Name = "GridLine_Z_" .. i
		line.Size = Vector3.new(0.1, 0.05, fullSizeZ)
		line.CFrame = CFrame.new(xVal, 0.01, 0)
		line.Material = Enum.Material.Neon
		line.Color = lineColor
		line.Transparency = lineTransparency
		line.Anchored = true
		line.CanCollide = false
		line.CanTouch = false
		line.CanQuery = false
		line.Parent = gridFolder
	end
	
	print("[PlacementServer] Zitadellen-Spielfeld (10x10, Neon-Cyan Gitter) erfolgreich erzeugt!")
end

createGridVisualization()

-- Live-Wirtschaftskreislauf (Passive Einkommens-Schleife mit netzwerkschonendem 1.0s Tick)
task.spawn(function()
	while true do
		task.wait(1.0)
		GridModule.Update(1.0)
	end
end)

print("[PlacementServer] Initialisiert. Lauscht auf PlacementRemote Events. Wirtschaftsschleife aktiv.")
