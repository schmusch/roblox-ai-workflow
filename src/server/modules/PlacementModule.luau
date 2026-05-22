--!strict
local PlayerDataStore = require(script.Parent.PlayerDataStore)

local PlacementModule = {}

-- Server-seitiger Katalog der Gottheiten (Single Source of Truth)
local DEITY_CATALOG = {
	["old_forest_spirit"] = { price = 500 }
}

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

	-- 3. Spielfeld-Validierung (Out-of-Bounds)
	-- Das Spielfeld ist auf eine max. Ausdehnung von z.B. 10 Einheiten beschränkt (z.B. max 10x10)
	if math.abs(gridCoords.X) > 10 or math.abs(gridCoords.Z) > 10 then
		return -- Außerhalb des Spielfelds, verwerfen!
	end

	-- 4. Server-Katalog Prüfung (Price Spoofing Schutz)
	local deityData = DEITY_CATALOG[deityId]
	if not deityData then
		return -- Ungültige Gottheit, verwerfen!
	end

	-- 5. Inventar-Prüfung und -Verbrauch (falls vorhanden/nötig)
	if not PlayerDataStore.hasInventoryItem(player, deityId) then
		return -- Besitzt das Item nicht!
	end

	-- 6. Belief-Transaktionsprüfung und Abbuchung
	local price = deityData.price
	local transactionSuccess = PlayerDataStore.adjustBelief(player, -price)
	if not transactionSuccess then
		return -- Nicht genügend Glaubenspunkte!
	end

	-- Inventar verbrauchen (nach erfolgreicher Bezahlung)
	PlayerDataStore.consumeInventoryItem(player, deityId)

	-- 7. Spam-Schutz Zeitstempel aktualisieren (erst nach erfolgreicher Transaktion)
	lastPlacementTime[player] = now
end

return PlacementModule
-- Sync-Trigger: Zwinge Rojo zur Neusynchronisation

