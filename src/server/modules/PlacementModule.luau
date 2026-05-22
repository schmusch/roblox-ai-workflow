--!strict
local PlayerDataStore = require(script.Parent.PlayerDataStore)
local GridModule = require(script.Parent.GridModule)

local PlacementModule = {}

-- Rate Limiting: Speichert den Zeitstempel der letzten erfolgreichen Platzierung pro Spieler
local lastPlacementTime: { [Player]: number } = {}

function PlacementModule.HandlePlacementRequest(player: Player, deityId: string, gridCoords: Vector3, rotation: number)
	-- 1. Typ-Verwirrungs-Angriffe (Type Confusion) abfangen
	-- Unterstützt sowohl echte Roblox Player-Instanzen als auch Mock-Player-Tabellen in Unit-Tests
	local isMockPlayer = typeof(player) == "table" and player.ClassName == "Player"
	local isRealPlayer = typeof(player) == "Instance" and player:IsA("Player")
	if not (isMockPlayer or isRealPlayer) then return end
	if typeof(deityId) ~= "string" then return end
	if typeof(gridCoords) ~= "Vector3" then return end
	if typeof(rotation) ~= "number" then return end

	-- 2. Spam-Schutz (Rate Limiting)
	local now = os.clock()
	local lastTime = lastPlacementTime[player] or 0
	if now - lastTime < 0.5 then
		return -- RPC-Aufruf zu schnell hintereinander, verwerfen!
	end

	-- 3. Gitter-Koordinaten-Umrechnung
	local cellX, cellZ = GridModule.WorldToCellCoords(gridCoords)

	-- 4. Server-authoritative Platzierungsvalidierung und -durchführung über GridModule
	local placementSuccess = GridModule.PlaceObject(player, deityId, cellX, cellZ, rotation)
	if not placementSuccess then
		return -- Validierung, Inventar- oder Belief-Prüfung fehlgeschlagen, verwerfen!
	end

	-- 5. Spam-Schutz Zeitstempel aktualisieren (erst nach erfolgreicher Transaktion)
	lastPlacementTime[player] = now
end

return PlacementModule

