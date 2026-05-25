--!strict
-- Platziert in: src/client/PlacementController.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local GridConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GridConfig") :: ModuleScript)
local GridMath = require(ReplicatedStorage.Shared:WaitForChild("GridMath") :: ModuleScript)

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local camera = workspace.CurrentCamera
pcall(function()
	if camera then
		camera.CameraType = Enum.CameraType.Custom
	end
end)

local Events = ReplicatedStorage:WaitForChild("Events") :: Folder
local placementRemote = Events:WaitForChild("PlacementRemote") :: RemoteEvent

-- BindableEvent für Aktivierung aus anderen Skripten (z.B. Baumenü) einrichten
local activatePlacementEvent = Events:FindFirstChild("ActivatePlacement")
if not activatePlacementEvent then
	local newEvent = Instance.new("BindableEvent")
	newEvent.Name = "ActivatePlacement"
	newEvent.Parent = Events
	activatePlacementEvent = newEvent
end
local activatePlacementEventTyped = activatePlacementEvent :: BindableEvent

-- Zustandsvariablen
local active = false
local currentDeityId = "old_forest_spirit" -- Standard-Monument für Platzierungstests
local currentRotation = 0 -- Grad: 0, 90, 180, 270
local previewPart: Part? = nil
local previewIndicator: Part? = nil
local renderConnection: RBXScriptConnection? = nil

-- Hilfsfunktion: Ermittelt die Mausposition im World-Space (Schnittpunkt mit Boden/Baseplate)
local function getMouseWorldPosition(): Vector3?
	local mousePos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local filter = { player.Character }
	if previewPart then
		table.insert(filter, previewPart)
	end
	raycastParams.FilterDescendantsInstances = filter
	
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
	if result then
		return result.Position
	end
	return nil
end

-- Hilfsfunktion: Baut das occupiedCells-Gitter aus den Spieler-Attributen auf
local function getOccupiedCells(): { [number]: { [number]: string? } }
	local rawAttr = player:GetAttribute("CitadelPlacedObjects") or "{}"
	local objects = {}
	
	pcall(function()
		objects = HttpService:JSONDecode(rawAttr)
	end)
	
	local cells = {}
	for x = 1, GridConfig.Settings.SizeX do
		cells[x] = {}
	end
	
	for objId, obj in pairs(objects) do
		local profile = GridConfig.DeityProfiles[obj.DeityId]
		if profile then
			local w = profile.Width
			local l = profile.Length
			if obj.Rotation == 90 or obj.Rotation == 270 then
				w, l = l, w
			end
			
			for x = obj.OriginX, obj.OriginX + w - 1 do
				for z = obj.OriginZ, obj.OriginZ + l - 1 do
					if x >= 1 and x <= GridConfig.Settings.SizeX and z >= 1 and z <= GridConfig.Settings.SizeZ then
						cells[x][z] = objId
					end
				end
			end
		end
	end
	
	return cells
end

-- Hilfsfunktion: Berechnet das exakte geometrische Zentrum für die Platzierungsvorschau
local function getPlacementCenterWorldPos(cellX: number, cellZ: number, w: number, l: number): Vector3
	local settings = GridConfig.Settings
	local centerX = cellX + (w - 1) / 2
	local centerZ = cellZ + (l - 1) / 2
	
	local worldX = (centerX - 1 - settings.SizeX / 2) * settings.CellSize + settings.CellSize / 2
	local worldZ = (centerZ - 1 - settings.SizeZ / 2) * settings.CellSize + settings.CellSize / 2
	
	-- 1.0 Studs über dem Boden (da das Vorschau-Part 2 Studs hoch ist)
	return Vector3.new(worldX, 1, worldZ)
end

-- Beendet den Platzierungsmodus und räumt auf
local function deactivatePlacement()
	active = false
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if previewPart then
		previewPart:Destroy()
		previewPart = nil
	end
	if previewIndicator then
		previewIndicator:Destroy()
		previewIndicator = nil
	end
	print("[PlacementController] Platzierungsmodus deaktiviert.")
end

-- Startet den Platzierungsmodus
local function activatePlacement(deityId: string)
	if active then
		deactivatePlacement()
	end
	
	currentDeityId = deityId
	currentRotation = 0
	active = true
	
	local profile = GridConfig.DeityProfiles[deityId]
	if not profile then
		warn("[PlacementController] Kein Profil für Gottheit:", deityId)
		active = false
		return
	end
	
	-- Erzeuge das halbtransparente Vorschau-Part
	local w = profile.Width * GridConfig.Settings.CellSize
	local l = profile.Length * GridConfig.Settings.CellSize
	
	local part = Instance.new("Part")
	part.Name = "CitadelPlacementPreview"
	part.Size = Vector3.new(w, 2, l)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.4
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Anchored = true
	part.CastShadow = false
	part.Parent = workspace
	
	previewPart = part

	-- Visueller Front-Indikator (um die Rotation auch bei quadratischen Monumenten extrem gut sichtbar zu machen!)
	local indicator = Instance.new("Part")
	indicator.Name = "FrontIndicator"
	indicator.Size = Vector3.new(w, 0.5, 1) -- Deutlich größer: Breite des Parts, 0.5 Studs hoch, 1 Stud tief
	indicator.Material = Enum.Material.SmoothPlastic
	indicator.Color = Color3.fromRGB(0, 170, 255) -- Wunderschönes Cyan-Blau
	indicator.CanCollide = false
	indicator.CanTouch = false
	indicator.CanQuery = false
	indicator.Anchored = true
	indicator.Parent = workspace
	
	previewIndicator = indicator
	
	print("[PlacementController] Platzierungsmodus aktiviert für Gottheit:", deityId)
	
	-- Render Loop für Echtzeit-Snapping, Kollisionsprüfung und Vorschau-Aktualisierung
	renderConnection = RunService.RenderStepped:Connect(function()
		if not previewPart then return end
		
		-- Sanfte "atmende" Transparenz-Animation für einen modernen Premium-Look
		local baseTransparency = 0.35
		previewPart.Transparency = baseTransparency + math.sin(os.clock() * 6) * 0.1
		
		local mouseWorldPos = getMouseWorldPosition()
		if not mouseWorldPos then
			previewPart.Transparency = 1.0 -- Unsichtbar machen, wenn die Maus im Leeren ist
			if indicator then indicator.Transparency = 1.0 end
			return
		end
		
		-- 1. Konvertiere in Grid-Koordinaten
		local cellX, cellZ = GridMath.WorldToCellCoords(mouseWorldPos)
		
		-- 2. Berechne aktuelle Dimensionen basierend auf der Rotation
		local currentW = profile.Width
		local currentL = profile.Length
		if currentRotation == 90 or currentRotation == 270 then
			currentW, currentL = currentL, currentW
		end
		
		-- 3. Berechne zentrierte physikalische Position
		local centerWorldPos = getPlacementCenterWorldPos(cellX, cellZ, currentW, currentL)
		
		-- 4. Setze Position und Rotation des Vorschauparts
		previewPart.CFrame = CFrame.new(centerWorldPos) * CFrame.Angles(0, math.rad(currentRotation), 0)
		previewPart.Transparency = baseTransparency + math.sin(os.clock() * 6) * 0.1
		
		-- 5. Aktualisiere Position des Front-Indikators relativ zum Hauptpart
		if indicator then
			indicator.Transparency = previewPart.Transparency
			-- Positioniere ihn auf der Oberseite (Y = 1.25) an der Vorderkante
			indicator.CFrame = previewPart.CFrame * CFrame.new(0, 1.25, -currentL * GridConfig.Settings.CellSize / 2 + 0.5)
		end
		
		-- 6. Lokale Kollisions- und Boundsprüfung
		local occupiedCells = getOccupiedCells()
		local isValid, _ = GridMath.CheckPlacementValidity(occupiedCells, currentDeityId, cellX, cellZ, currentRotation)
		
		-- 7. Visuelles Feedback (Neon Grün bei Valide, Neon Rot bei Blockiert)
		if isValid then
			previewPart.Color = Color3.fromHSV(0.333, 1, 1) -- Neon-Lime
		else
			previewPart.Color = Color3.fromHSV(0, 1, 1) -- Neon-Crimson
		end
	end)
end

-- BindableEvent für Aktivierung verknüpfen
activatePlacementEventTyped.Event:Connect(function(deityId: string?)
	if deityId and deityId ~= "" then
		activatePlacement(deityId)
	else
		deactivatePlacement()
	end
end)

-- Eingabe-Verarbeitung
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	-- Tastenbefehle im aktiven Platzierungsmodus
	if active then
		if input.KeyCode == Enum.KeyCode.R then
			-- Rotation im Uhrzeigersinn um 90 Grad wechseln
			currentRotation = (currentRotation + 90) % 360
			
			-- Bounding-Box Größe des Vorschauparts anpassen
			local profile = GridConfig.DeityProfiles[currentDeityId]
			if previewPart and profile then
				local w = profile.Width * GridConfig.Settings.CellSize
				local l = profile.Length * GridConfig.Settings.CellSize
				if currentRotation == 90 or currentRotation == 270 then
					w, l = l, w
				end
				previewPart.Size = Vector3.new(w, 2, l)
			end
			print("[PlacementController] Rotation gewechselt auf:", currentRotation, "Grad")
			
		elseif input.KeyCode == Enum.KeyCode.Escape then
			deactivatePlacement()
			
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			-- Rechtsklick bricht ebenfalls ab
			deactivatePlacement()
			
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Linksklick platziert das Monument
			local mouseWorldPos = getMouseWorldPosition()
			if mouseWorldPos and previewPart then
				local cellX, cellZ = GridMath.WorldToCellCoords(mouseWorldPos)
				local currentW = GridConfig.DeityProfiles[currentDeityId].Width
				local currentL = GridConfig.DeityProfiles[currentDeityId].Length
				if currentRotation == 90 or currentRotation == 270 then
					currentW, currentL = currentL, currentW
				end
				
				-- Lokale Validierung vor dem Absenden
				local occupiedCells = getOccupiedCells()
				local isValid, _ = GridMath.CheckPlacementValidity(occupiedCells, currentDeityId, cellX, cellZ, currentRotation)
				
				if isValid then
					-- Sende den RPC mit Weltkoordinaten und Rotation an den Server
					print("[PlacementController] Sende Platzierungsanfrage an den Server...")
					placementRemote:FireServer(currentDeityId, mouseWorldPos, currentRotation)
					
					-- Der Platzierungsmodus bleibt für fortlaufendes Platzieren aktiv!
					-- Zum Beenden: Rechtsklick, Escape oder P drücken.
					print("[PlacementController] Objekt platziert. Modus bleibt aktiv (Rechtsklick/Escape zum Beenden).")
				else
					warn("[PlacementController] Ungültige Platzierung! Anfrage wird nicht gesendet.")
				end
			end
		end
	end
end)

print("[PlacementController] Initialisiert. Drücke 'P' um den Platzierungsmodus zu starten.")
