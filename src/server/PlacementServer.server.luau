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
	
	-- Nur beim ALLERERSTEN Beitritt initialisieren (wenn Belief noch auf Standard-Fallback 0 steht)
	if state.Belief == 0 and not player:GetAttribute("CitadelBelief") then
		state.Belief = 2000
		state.Inventory["old_forest_spirit"] = 5
		state.Inventory["sun_temple"] = 2
		state.Inventory["water_shrine"] = 4
	end
	
	-- Gitter für den Spieler vorausinitialisieren (für den Wirtschaftskreislauf)
	local grid = GridModule.GetOrCreateGrid(player)
	
	-- Glaubensrate auf Basis der geladenen Gitterobjekte berechnen (für Offline-Progression)
	local totalBeliefRate = 0
	for _, obj in pairs(grid.Objects) do
		local prof = GridConfig.DeityProfiles[obj.DeityId]
		if prof then
			local beliefPerSecond = prof.BeliefPerSecond
			if GridModule.IsObjectDamped(grid, obj) then
				beliefPerSecond = beliefPerSecond * 0.5
			end
			totalBeliefRate = totalBeliefRate + beliefPerSecond
		end
	end
	
	-- Offline-Progression berechnen (Story 2.4)
	local now = os.time()
	local lastSave = state.LastSaveTime
	if lastSave and lastSave > 0 and totalBeliefRate > 0 then
		local SessionVerificationModule = require(ServerScriptService.Server.modules.SessionVerificationModule)
		local offlineEarnings = SessionVerificationModule.CalculateOfflineEarnings(player, lastSave, now, totalBeliefRate)
		if offlineEarnings > 0 then
			state.Belief = state.Belief + offlineEarnings
			print(string.format("[SessionVerification] Spieler %s erhält %d gedämpfte Offline-Belief-Einnahmen für %d Sekunden Abwesenheit.", 
				player.Name, offlineEarnings, now - lastSave))
		end
	end
	state.LastSaveTime = now
	
	-- Native Attribute für Replikation an das Client-UI setzen
	pcall(function()
		player:SetAttribute("CitadelBelief", state.Belief)
		player:SetAttribute("CitadelBeliefRate", totalBeliefRate)
		player:SetAttribute("CitadelInventory", HttpService:JSONEncode(state.Inventory))
	end)
	
	print(string.format("[PlacementServer] Startguthaben für %s initialisiert: %d Belief, Gitter vorausinitialisiert.", player.Name, state.Belief))
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Heartbeat zur persistenten Sicherung des Aktivitäts-Zeitstempels (Schutz gegen Crash-Datenverlust)
task.spawn(function()
	while true do
		task.wait(60.0)
		for _, player in ipairs(Players:GetPlayers()) do
			pcall(function()
				local state = PlayerDataStore.getPlayerState(player)
				state.LastSaveTime = os.time()
			end)
		end
	end
end)

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
	baseplate.CFrame = CFrame.new(0, 0.1, 0)
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
		line.CFrame = CFrame.new(0, 0.21, zVal)
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
		line.CFrame = CFrame.new(xVal, 0.21, 0)
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
