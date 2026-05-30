--!strict
-- Platziert in: src/client/DeityOrbitVisualizer.client.luau

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DeityCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DeityCatalog") :: ModuleScript)
local DeityEvolutionModule = require(ReplicatedStorage.Shared:WaitForChild("DeityEvolutionModule") :: ModuleScript)

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local placedObjectsFolder = workspace:WaitForChild("PlacedObjects", 10) :: Folder?

local activeOrbits: { [Part]: {
	HaloParts: { Part },
	BaseRadius: number,
	BaseOmega: number,
	FactionColor: Color3,
	RotationAngle: number,
	LevelConnection: RBXScriptConnection,
} } = {}

-- Bestimmt die edle Neon-Farbe basierend auf der Fraktion
local function getFactionColor(faction: string): Color3
	if faction == "AlteGoetter" then
		return Color3.fromRGB(255, 110, 0) -- Warmes, sakrales Orange-Gold
	else
		return Color3.fromRGB(0, 220, 255) -- Kaltes, hochtechnologisches Neon-Cyan
	end
end

-- Erstellt einen neuen orbitalen Neon-Halo um ein Monument-Part
local function createOrbit(monumentPart: Part)
	-- Zersplittere den Part-Namen, um deityId und objId zu extrahieren
	local nameParts = string.split(monumentPart.Name, "_")
	local deityId = ""
	
	-- Wenn das Format deityId_objId ist, setzen wir deityId zusammen (z.B. water_shrine -> multiple underscores)
	if #nameParts >= 2 then
		deityId = table.concat(nameParts, "_", 1, #nameParts - 1)
	else
		deityId = monumentPart.Name
	end

	-- Profil aus dem Katalog laden
	local catalogIndex = nil
	-- Suche im DeityCatalog nach dem passenden Index
	for index = 100, 200 do
		local profile = DeityCatalog.GetProfile(index)
		if profile and profile.Id == deityId then
			catalogIndex = index
			break
		end
	end

	local config = DeityCatalog.GetProfile(catalogIndex or 0)
	local factionColor = getFactionColor(config.Faction)

	-- Halo-Modell anlegen
	local haloParts: { Part } = {}
	local numHaloParts = 16 -- 16 glühende Segmente für einen flüssigen Ring

	for i = 1, numHaloParts do
		local segment = Instance.new("Part")
		segment.Name = "OrbitSegment_" .. i
		segment.Size = Vector3.new(0.6, 0.6, 0.6)
		segment.Material = Enum.Material.Neon
		segment.Color = factionColor
		segment.Transparency = 0.3
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanTouch = false
		segment.CanQuery = false
		segment.CastShadow = false
		segment.Parent = monumentPart
		table.insert(haloParts, segment)
	end

	-- Interne Hilfsfunktion zur Neupositionierung der Halo-Segmente basierend auf dem aktuellen Level
	local function updateOrbitVisuals()
		local level = monumentPart:GetAttribute("Level") or 1
		local radius = DeityEvolutionModule.CalculateRadius(config.BaseRadius, level)
		local currentOrbitData = activeOrbits[monumentPart]
		if not currentOrbitData then return end

		local center = monumentPart.Position
		local angleStep = (2 * math.pi) / numHaloParts
		
		for i, segment in ipairs(haloParts) do
			local currentAngle = currentOrbitData.RotationAngle + (i * angleStep)
			local offsetX = math.cos(currentAngle) * radius
			local offsetZ = math.sin(currentAngle) * radius
			-- Auf Höhe des Bodens des Monument-Parts schwebend rendern
			segment.CFrame = CFrame.new(center.X + offsetX, center.Y - 0.9, center.Z + offsetZ)
		end
	end

	-- Auf Attribut-Änderungen reagieren (Dynamische Evolution in Echtzeit!)
	local connection = monumentPart:GetAttributeChangedSignal("Level"):Connect(function()
		updateOrbitVisuals()
	end)

	activeOrbits[monumentPart] = {
		HaloParts = haloParts,
		BaseRadius = config.BaseRadius,
		BaseOmega = config.BaseOmega,
		FactionColor = factionColor,
		RotationAngle = 0,
		LevelConnection = connection,
	}

	updateOrbitVisuals()
end

-- Löscht den Orbit eines Monument-Parts
local function removeOrbit(monumentPart: Part)
	local orbitData = activeOrbits[monumentPart]
	if orbitData then
		if orbitData.LevelConnection then
			orbitData.LevelConnection:Disconnect()
		end
		for _, part in ipairs(orbitData.HaloParts) do
			part:Destroy()
		end
		activeOrbits[monumentPart] = nil
	end
end

-- Überwacht den PlacedObjects-Ordner
local function setupVisualizer(folder: Folder)
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Part") then
			task.wait(0.1) -- Kurz warten, bis Name und Attribute initialisiert sind
			createOrbit(child)
		end
	end)

	folder.ChildRemoved:Connect(function(child)
		if child:IsA("Part") then
			removeOrbit(child)
		end
	end)

	-- Bereits existierende Monumente visualisieren
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Part") then
			createOrbit(child)
		end
	end
end

if placedObjectsFolder then
	setupVisualizer(placedObjectsFolder)
else
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "PlacedObjects" and child:IsA("Folder") then
			setupVisualizer(child)
		end
	end)
end

-- Kontinuierlicher Render Loop für die geschmeidige Orbit-Rotation (Echtzeit!)
RunService.RenderStepped:Connect(function(deltaTime)
	for monumentPart, orbitData in pairs(activeOrbits) do
		local level = monumentPart:GetAttribute("Level") or 1
		local omega = DeityEvolutionModule.CalculateOmega(orbitData.BaseOmega, level)
		
		-- Rotationswinkel inkrementieren
		orbitData.RotationAngle = (orbitData.RotationAngle + (omega * deltaTime)) % (2 * math.pi)
		
		-- Positionen aktualisieren
		local center = monumentPart.Position
		local numSegments = #orbitData.HaloParts
		local angleStep = (2 * math.pi) / numSegments
		local radius = DeityEvolutionModule.CalculateRadius(orbitData.BaseRadius, level)

		for i, segment in ipairs(orbitData.HaloParts) do
			local currentAngle = orbitData.RotationAngle + (i * angleStep)
			local offsetX = math.cos(currentAngle) * radius
			local offsetZ = math.sin(currentAngle) * radius
			segment.CFrame = CFrame.new(center.X + offsetX, center.Y - 0.9, center.Z + offsetZ)
		end
	end
end)

print("[DeityOrbitVisualizer] Erfolgreich geladen und aktiv. Orbits werden visualisiert.")
