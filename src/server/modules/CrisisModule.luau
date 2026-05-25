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
		activeCrises[crisisId] = nil
		print(string.format("[CrisisModule] Katastrophe %s erfolgreich entfernt.", crisisId))
	end
end

-- Setzt alle aktiven Katastrophen zurück (für Unit-Tests)
function CrisisModule.ClearAll()
	for id, crisis in pairs(activeCrises) do
		if crisis.VisualPart then
			crisis.VisualPart:Destroy()
		end
	end
	activeCrises = {}
end

return CrisisModule
