--!strict
-- Platziert in: src/server/modules/CrisisModule.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local GridConfig = require(ReplicatedStorage.Shared.GridConfig)

export type CrisisData = {
	Id: string,
	Player: Player,
	CellX: number,
	CellZ: number,
	SpawnTime: number,
	VisualPart: Part?,
}

local CrisisModule = {}

-- In-Memory Speicher für alle aktiven Katastrophen
local activeCrises: { [string]: CrisisData } = {}

-- Spawnt eine neue Katastrophe in einem zufälligen 3x3 Voxel-Bereich auf dem Gitter des Spielers
function CrisisModule.SpawnCrisis(player: Player): string
	local sizeX = GridConfig.Settings.SizeX
	local sizeZ = GridConfig.Settings.SizeZ
	local cellSize = GridConfig.Settings.CellSize

	-- Start-Index für einen 3x3-Bereich würfeln (muss zwischen 1 und Size - 2 liegen, also 1 bis 8 bei 10x10)
	local cellX = math.random(1, sizeX - 2)
	local cellZ = math.random(1, sizeZ - 2)

	local crisisId = HttpService:GenerateGUID(false)
	local now = os.time()

	local crisis: CrisisData = {
		Id = crisisId,
		Player = player,
		CellX = cellX,
		CellZ = cellZ,
		SpawnTime = now,
	}

	-- Visualisierung im Workspace (nur für echte Roblox-Instanzen, nicht in Unit-Tests)
	local isRealPlayer = typeof(player) == "Instance" and player:IsA("Player")
	if isRealPlayer then
		local catastrophesFolder = workspace:FindFirstChild("Catastrophes")
		if not catastrophesFolder then
			local folder = Instance.new("Folder")
			folder.Name = "Catastrophes"
			folder.Parent = workspace
			catastrophesFolder = folder
		end

		-- Berechne das geometrische Zentrum des 3x3-Bereichs
		-- Die Zellen belegen cellX, cellX + 1, cellX + 2. Das Zentrum liegt exakt auf cellX + 1
		local centerX = cellX + 1
		local centerZ = cellZ + 1

		local worldX = (centerX - 1 - sizeX / 2) * cellSize + cellSize / 2
		local worldZ = (centerZ - 1 - sizeZ / 2) * cellSize + cellSize / 2
		
		-- Y = 0.25: Schwebt hauchdünn (Dicke 0.05) über den Gitterlinien (Y = 0.21), um Z-Fighting zu verhindern!
		local centerWorldPos = Vector3.new(worldX, 0.25, worldZ)

		local part = Instance.new("Part")
		part.Name = "Catastrophe_" .. crisisId
		part.Size = Vector3.new(3 * cellSize - 0.1, 0.05, 3 * cellSize - 0.1) -- Leicht kleiner für Ästhetik
		part.CFrame = CFrame.new(centerWorldPos)
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(180, 0, 255) -- Mystisches, glühendes Neon-Purpur
		part.Transparency = 0.5
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Parent = catastrophesFolder

		crisis.VisualPart = part

		-- Client benachrichtigen, um einen Warnsound abzuspielen
		local events = ReplicatedStorage:FindFirstChild("Events")
		if events then
			local remote = events:FindFirstChild("CatastropheRemote") :: RemoteEvent?
			if remote then
				remote:FireClient(player, crisisId, cellX, cellZ)
			end
		end
	end

	-- Zellen im Spielergitter belegen, um neue Platzierungen zu blockieren
	local GridModule = require(script.Parent.GridModule)
	local grid = GridModule.GetOrCreateGrid(player)
	for x = cellX, cellX + 2 do
		for z = cellZ, cellZ + 2 do
			if grid.Cells[x] and grid.Cells[x][z] == nil then
				grid.Cells[x][z] = "crisis_" .. crisisId
			end
		end
	end

	activeCrises[crisisId] = crisis
	print(string.format("[CrisisModule] Katastrophe %s auf Zelle (%d,%d) für Spieler %s gespawnt!", 
		crisisId, cellX, cellZ, player.Name))

	return crisisId
end

-- Gibt eine Liste aller aktiven Katastrophen zurück
function CrisisModule.GetActiveCrises(): { [string]: CrisisData }
	local copy = {}
	for k, v in pairs(activeCrises) do
		copy[k] = v
	end
	return copy
end

-- Löscht eine bestimmte Katastrophe aus dem Speicher und Workspace (z. B. nach Bereinigung)
function CrisisModule.RemoveCrisis(crisisId: string)
	local crisis = activeCrises[crisisId]
	if crisis then
		if crisis.VisualPart then
			crisis.VisualPart:Destroy()
		end

		-- Gitterzellen freigeben
		local GridModule = require(script.Parent.GridModule)
		local grid = GridModule.GetOrCreateGrid(crisis.Player)
		for x = crisis.CellX, crisis.CellX + 2 do
			for z = crisis.CellZ, crisis.CellZ + 2 do
				if grid.Cells[x] and grid.Cells[x][z] == "crisis_" .. crisisId then
					grid.Cells[x][z] = nil
				end
			end
		end

		-- Belief-Rate neu berechnen und replizieren (da die Dämpfung weggefallen ist!)
		local totalBeliefPerSecond = 0
		for _, obj in pairs(grid.Objects) do
			local prof = GridConfig.DeityProfiles[obj.DeityId]
			if prof then
				local beliefPerSecond = prof.BeliefPerSecond
				if GridModule.IsObjectDamped(grid, obj) then
					beliefPerSecond = beliefPerSecond * 0.5
				end
				totalBeliefPerSecond = totalBeliefPerSecond + beliefPerSecond
			end
		end
		pcall(function()
			(crisis.Player :: any):SetAttribute("CitadelBeliefRate", totalBeliefPerSecond)
		end)

		activeCrises[crisisId] = nil
		print(string.format("[CrisisModule] Katastrophe %s erfolgreich entfernt.", crisisId))
	end
end

-- Setzt alle aktiven Katastrophen zurück (für Unit-Tests)
function CrisisModule.ClearAll()
	local GridModule = require(script.Parent.GridModule)
	for id, crisis in pairs(activeCrises) do
		if crisis.VisualPart then
			crisis.VisualPart:Destroy()
		end

		-- Gitterzellen auf dem Spielergitter freigeben
		pcall(function()
			local grid = GridModule.GetOrCreateGrid(crisis.Player)
			for x = crisis.CellX, crisis.CellX + 2 do
				for z = crisis.CellZ, crisis.CellZ + 2 do
					if grid.Cells[x] and grid.Cells[x][z] == "crisis_" .. id then
						grid.Cells[x][z] = nil
					end
				end
			end
		end)
	end
	activeCrises = {}
end

local function getCrisisWorldPos(cellX: number, cellZ: number): Vector3
	local sizeX = GridConfig.Settings.SizeX
	local sizeZ = GridConfig.Settings.SizeZ
	local cellSize = GridConfig.Settings.CellSize
	local centerX = cellX + 1
	local centerZ = cellZ + 1
	local worldX = (centerX - 1 - sizeX / 2) * cellSize + cellSize / 2
	local worldZ = (centerZ - 1 - sizeZ / 2) * cellSize + cellSize / 2
	return Vector3.new(worldX, 0.25, worldZ)
end

local activeCleansings: { [Player]: { CrisisId: string, StartTime: number } } = {}

-- Setzt alle aktiven Reinigungen zurück (für Tests)
function CrisisModule.ResetCleansings()
	activeCleansings = {}
end

function CrisisModule.HandleStartCleansing(player: Player, crisisId: string): boolean
	local crisis = activeCrises[crisisId]
	if not crisis then
		return false
	end

	-- Reichweitenprüfung (Proximity Check <= 15 Studs)
	local crisisPos = getCrisisWorldPos(crisis.CellX, crisis.CellZ)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local playerPos = rootPart and rootPart.Position or Vector3.new(0, 0, 0)
	
	local distance = (playerPos - crisisPos).Magnitude
	if distance > 15 then
		warn(string.format("[SECURITY] Cleansing-Reichweitenprüfung fehlgeschlagen für %s (Distanz: %.2f Studs)", player.Name, distance))
		return false
	end

	-- Startzeit registrieren
	activeCleansings[player] = {
		CrisisId = crisisId,
		StartTime = os.clock(),
	}
	print(string.format("[CrisisModule] Reinigung gestartet für Spieler %s an Katastrophe %s.", player.Name, crisisId))
	return true
end

function CrisisModule.HandleCompleteCleansing(player: Player, crisisId: string): boolean
	local cleansing = activeCleansings[player]
	if not (cleansing and cleansing.CrisisId == crisisId) then
		return false
	end

	local crisis = activeCrises[crisisId]
	if not crisis then
		activeCleansings[player] = nil
		return false
	end

	-- 1. Kanonisches Zeitintervall prüfen (Kanalisierungsdauer >= 3.0 Sekunden)
	local elapsed = os.clock() - cleansing.StartTime
	if elapsed < 3.0 then
		warn(string.format("[SECURITY] Cleansing-Kanalisierungsprüfung fehlgeschlagen für %s (Kanalisiert: %.2fs)", player.Name, elapsed))
		activeCleansings[player] = nil
		return false
	end

	-- 2. Reichweitenprüfung am Ende (Anti-Teleport)
	local crisisPos = getCrisisWorldPos(crisis.CellX, crisis.CellZ)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local playerPos = rootPart and rootPart.Position or Vector3.new(0, 0, 0)
	
	local distance = (playerPos - crisisPos).Magnitude
	if distance > 15 then
		warn(string.format("[SECURITY] Cleansing-Verifikations-Reichweitenprüfung fehlgeschlagen für %s (Distanz: %.2f Studs)", player.Name, distance))
		activeCleansings[player] = nil
		return false
	end

	-- Erfolgreicher Abschluss: Krise löschen und Register bereinigen
	activeCleansings[player] = nil
	CrisisModule.RemoveCrisis(crisisId)
	return true
end

_G.CrisisModule = CrisisModule
return CrisisModule
