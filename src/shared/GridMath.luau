--!strict
-- Platziert in: src/shared/GridMath.luau

local GridConfig = require(script.Parent.GridConfig)

local GridMath = {}

-- Wandelt physikalische Weltkoordinaten (Studs) in diskrete Rasterzellen um
function GridMath.WorldToCellCoords(worldPos: Vector3): (number, number)
	local settings = GridConfig.Settings
	local cellX = math.floor(worldPos.X / settings.CellSize) + (settings.SizeX / 2) + 1
	local cellZ = math.floor(worldPos.Z / settings.CellSize) + (settings.SizeZ / 2) + 1
	return cellX, cellZ
end

-- Wandelt diskrete Rasterzellen in physikalische Weltkoordinaten (Zentrum der Zelle) um
function GridMath.CellToWorldCoords(cellX: number, cellZ: number): Vector3
	local settings = GridConfig.Settings
	local worldX = (cellX - 1 - settings.SizeX / 2) * settings.CellSize + settings.CellSize / 2
	local worldZ = (cellZ - 1 - settings.SizeZ / 2) * settings.CellSize + settings.CellSize / 2
	return Vector3.new(worldX, 0, worldZ)
end

-- Validiert eine Platzierung geometrisch auf Kollisionen und Spielfeldbegrenzung
function GridMath.CheckPlacementValidity(
	occupiedCells: { [number]: { [number]: string? } },
	deityId: string,
	cellX: number,
	cellZ: number,
	rotation: number
): (boolean, { {number} }?)
	local profile = GridConfig.DeityProfiles[deityId]
	if not profile then
		return false, nil
	end

	local settings = GridConfig.Settings
	local w = profile.Width
	local l = profile.Length

	-- Dimensionen tauschen bei 90 oder 270 Grad Rotation
	if rotation == 90 or rotation == 270 then
		w, l = l, w
	end

	-- Out-of-bounds Check
	if cellX < 1 or (cellX + w - 1) > settings.SizeX then
		return false, nil
	end
	if cellZ < 1 or (cellZ + l - 1) > settings.SizeZ then
		return false, nil
	end

	-- Kollisionsprüfung (Zellbelegung)
	local cellsToOccupy = {}
	for x = cellX, cellX + w - 1 do
		for z = cellZ, cellZ + l - 1 do
			if occupiedCells[x] and occupiedCells[x][z] then
				return false, nil -- Zelle ist bereits belegt!
			end
			table.insert(cellsToOccupy, {x, z})
		end
	end

	return true, cellsToOccupy
end

return GridMath
