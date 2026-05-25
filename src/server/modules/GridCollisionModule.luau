--!strict
-- Platziert in: src/server/modules/GridCollisionModule.luau

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GridConfig = require(ReplicatedStorage.Shared.GridConfig)

local GridCollisionModule = {}

-- Berechnet die rotierten Abmessungen eines Objekts. Bei 90 und 270 Grad werden Breite (X) und Tiefe (Z) getauscht.
function GridCollisionModule.getRotatedDimensions(footprint: Vector3, rotation: number): (number, number, number)
	local w = footprint.X
	local h = footprint.Y
	local d = footprint.Z

	-- Normalisiere die Rotation auf einen Bereich von [0, 360)
	local normalizedRot = math.round(rotation) % 360
	if normalizedRot < 0 then
		normalizedRot += 360
	end

	if normalizedRot == 90 or normalizedRot == 270 then
		return d, h, w
	else
		return w, h, d
	end
end

-- Verifiziert eine Platzierung geometrisch auf Kollisionen und Spielfeldbegrenzung
function GridCollisionModule.verifyPlacement(
	occupiedCells: { [number]: { [number]: string? } },
	footprint: Vector3,
	cellX: number,
	cellZ: number,
	rotation: number
): (boolean, { {number} }?)
	local sizeX = GridConfig.Settings.SizeX
	local sizeZ = GridConfig.Settings.SizeZ

	local w, h, d = GridCollisionModule.getRotatedDimensions(footprint, rotation)

	-- Überprüfe, ob die Startkoordinaten überhaupt im Spielfeld liegen
	if cellX < 1 or cellX > sizeX or cellZ < 1 or cellZ > sizeZ then
		return false, nil
	end

	-- Überprüfe die Grenzen des gesamten Objekts (Out of Bounds Check)
	if (cellX + w - 1) > sizeX or (cellZ + d - 1) > sizeZ then
		return false, nil
	end

	-- Überprüfe auf Überschneidungen/Kollisionen
	local cellsToOccupy = {}
	for x = cellX, cellX + w - 1 do
		for z = cellZ, cellZ + d - 1 do
			if occupiedCells[x] and occupiedCells[x][z] ~= nil then
				return false, nil -- Zelle ist bereits belegt!
			end
			table.insert(cellsToOccupy, {x, z})
		end
	end

	return true, cellsToOccupy
end

return GridCollisionModule
