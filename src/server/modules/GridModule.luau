--!strict
-- Platziert in: src/server/modules/GridModule.luau

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerDataStore = require(script.Parent.PlayerDataStore)
local GridConfig = require(ReplicatedStorage.Shared.GridConfig)

export type PlacedObject = {
	Id: string,
	DeityId: string,
	OriginX: number,
	OriginZ: number,
	Width: number,
	Length: number,
	Rotation: number,
}

export type PlayerGrid = {
	Player: Player,
	Objects: { [string]: PlacedObject },
	Cells: { [number]: { [number]: string? } }
}

local GridModule = {}

-- In-Memory Speicher für alle Spielergitter
local grids: { [Player]: PlayerGrid } = {}

-- Preis-Katalog für Gottheiten (Server-seitige Single Source of Truth)
local DEITY_PRICES: { [string]: number } = {
	["old_forest_spirit"] = 500,
}

function GridModule.GetOrCreateGrid(player: Player): PlayerGrid
	local grid = grids[player]
	if not grid then
		local cells = {}
		for x = 1, GridConfig.Settings.SizeX do
			cells[x] = {}
		end

		grid = {
			Player = player,
			Objects = {},
			Cells = cells,
		}
		grids[player] = grid
	end
	return grid
end

function GridModule.WorldToCellCoords(worldPos: Vector3): (number, number)
	local settings = GridConfig.Settings
	local cellX = math.floor(worldPos.X / settings.CellSize) + (settings.SizeX / 2) + 1
	local cellZ = math.floor(worldPos.Z / settings.CellSize) + (settings.SizeZ / 2) + 1
	return cellX, cellZ
end

function GridModule.CheckPlacementValidity(grid: PlayerGrid, deityId: string, cellX: number, cellZ: number, rotation: number): (boolean, { {number} }?)
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
			if grid.Cells[x] and grid.Cells[x][z] then
				return false, nil -- Zelle ist bereits belegt!
			end
			table.insert(cellsToOccupy, {x, z})
		end
	end

	return true, cellsToOccupy
end

function GridModule.PlaceObject(player: Player, deityId: string, cellX: number, cellZ: number, rotation: number): boolean
	local profile = GridConfig.DeityProfiles[deityId]
	if not profile then
		return false
	end

	local grid = GridModule.GetOrCreateGrid(player)
	local isValid, cellsToOccupy = GridModule.CheckPlacementValidity(grid, deityId, cellX, cellZ, rotation)
	if not (isValid and cellsToOccupy) then
		return false
	end

	-- Inventarprüfung
	if not PlayerDataStore.hasInventoryItem(player, deityId) then
		return false
	end

	-- Bezahlung über PlayerDataStore
	local price = DEITY_PRICES[deityId] or 0
	local paymentSuccess = PlayerDataStore.adjustBelief(player, -price)
	if not paymentSuccess then
		return false
	end

	-- Inventar verbrauchen
	PlayerDataStore.consumeInventoryItem(player, deityId)

	-- Objekt in das Gitter einfügen
	local objId = HttpService:GenerateGUID(false)
	local placedObj: PlacedObject = {
		Id = objId,
		DeityId = deityId,
		OriginX = cellX,
		OriginZ = cellZ,
		Width = profile.Width,
		Length = profile.Length,
		Rotation = rotation,
	}

	-- Zellen belegen
	for _, cell in ipairs(cellsToOccupy) do
		local cx, cz = cell[1], cell[2]
		grid.Cells[cx][cz] = objId
	end

	grid.Objects[objId] = placedObj
	return true
end

function GridModule.Update(deltaTime: number)
	for player, grid in pairs(grids) do
		local totalBeliefPerSecond = 0
		for _, obj in pairs(grid.Objects) do
			local profile = GridConfig.DeityProfiles[obj.DeityId]
			if profile then
				totalBeliefPerSecond = totalBeliefPerSecond + profile.BeliefPerSecond
			end
		end

		if totalBeliefPerSecond > 0 then
			local generated = totalBeliefPerSecond * deltaTime
			PlayerDataStore.adjustBelief(player, generated)
		end
	end
end

-- Speicherbereinigung bei Spieleraustritt
game:GetService("Players").PlayerRemoving:Connect(function(player)
	grids[player] = nil
end)

return GridModule
