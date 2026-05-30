--!strict
local RollbackModule = {}

-- Engine Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Interne Server-Module
local RingBufferModule = require(script.Parent.RingBufferModule)
local PlayerDataStore = require(script.Parent.PlayerDataStore)

-- Netzwerk-Ressourcen (Sicheres Laden mit Fallback für Unit-Tests)
local EventsFolder = ReplicatedStorage:WaitForChild("Events", 2) :: Folder?
local InterventionRemote: RemoteEvent? = nil
if EventsFolder then
	InterventionRemote = EventsFolder:WaitForChild("InterventionRemote", 2) :: RemoteEvent?
end

-- Konfiguration
local MAX_ROLLBACK_TICKS = 90 -- 1,5 Sekunden bei 60 Hz
local INTERVENTION_CATALOG: { [number]: { Name: string, BeliefCost: number } } = {
	[1] = { Name = "Glaubenssturm", BeliefCost = 500 },
	[2] = { Name = "Zensur-Protokoll", BeliefCost = 750 }
}

-- Typ-Definitionen für ausstehende Interventions
export type PendingIntervention = {
	id: string,
	player: Player,
	clientTick: number,
	targetTileIndex: number,
	interventionId: number,
	castTime: number,
	active: boolean
}

local pendingInterventions: { PendingIntervention } = {}
local simulatedTime: number? = nil

local function getCurrentTime(): number
	return simulatedTime or os.clock()
end

-- Hilfsmethoden für Unit-Tests
function RollbackModule.clearPendingInterventions()
	table.clear(pendingInterventions)
	simulatedTime = nil
end

function RollbackModule.getPendingInterventions(): { PendingIntervention }
	return pendingInterventions
end

-- Verstreichen der Zeit simulieren und abgelaufene Ascension-Locks abarbeiten
function RollbackModule.updatePendingInterventions(deltaTime: number)
	if not simulatedTime then
		simulatedTime = os.clock()
	end
	simulatedTime = simulatedTime :: number + deltaTime

	local now = getCurrentTime()
	local isRealPlayer = function(p)
		local ok, res = pcall(function()
			return typeof(p) == "Instance" and p:IsA("Player")
		end)
		return ok and res
	end

	-- Rückwärts iterieren, um sicher aus der Liste zu entfernen
	for i = #pendingInterventions, 1, -1 do
		local pending = pendingInterventions[i]
		if now - pending.castTime >= 1.5 then
			if pending.active then
				-- Finale Server-Validierung des Ziels zum Ausführungszeitpunkt
				local historicalFrame = RingBufferModule.readFrame(pending.clientTick)
				if historicalFrame.Tick ~= -1 then
					local targetEntity: RingBufferModule.EntitySlot? = nil
					for j = 1, 18 do
						local entity = historicalFrame.Entities[j]
						if entity.Active == 1 and entity.TileIndex == pending.targetTileIndex then
							targetEntity = entity
							break
						end
					end

					if targetEntity and targetEntity.Health > 0 then
						-- Glaubenssturm/Intervention endgültig ausführen!
						print(string.format("[ASCENSION LOCK EXECUTED] %s von %s auf Kachel %d wurde final ausgeführt.", 
							INTERVENTION_CATALOG[pending.interventionId].Name, pending.player.Name, pending.targetTileIndex))

						if InterventionRemote and isRealPlayer(pending.player) then
							InterventionRemote:FireAllClients("Confirmed", pending.player.UserId, pending.clientTick, pending.targetTileIndex, pending.interventionId)
						end
					else
						-- Ziel ist gestorben während des Locks -> Refund oder Korrektur
						print(string.format("[ASCENSION LOCK EXPIRED] Ziel auf Kachel %d existiert nicht mehr. Intervention verworfen.", pending.targetTileIndex))
						if InterventionRemote and isRealPlayer(pending.player) then
							InterventionRemote:FireClient(pending.player, "Correction", workspace:GetAttribute("CombatTick") or 0)
						end
					end
				end
			else
				print(string.format("[ASCENSION LOCK CANCELLED] Intervention von %s wurde abgebrochen (Zensur).", pending.player.Name))
			end
			table.remove(pendingInterventions, i)
		end
	end
end

-- Verwaltet die Validierung einer Echtzeit-Intervention und gibt (Success, ErrorMessage) zurück
function RollbackModule.processInterventionRequest(
	player: Player, 
	clientTick: number, 
	targetTileIndex: number, 
	interventionId: number
): (boolean, string?)
	-- 1. Typ-Sicherheitsprüfung
	if typeof(clientTick) ~= "number" or typeof(targetTileIndex) ~= "number" or typeof(interventionId) ~= "number" then
		local errMsg = "Typ-Verwirrung bei Intervention-Parametern"
		warn(string.format("[SECURITY] %s von %s", errMsg, player.Name))
		return false, errMsg
	end

	local serverTick = workspace:GetAttribute("CombatTick") :: number? or 0
	local tickDelta = serverTick - clientTick

	-- 2. Grenzwert-Prüfung des Latenzfensters (inklusive Future-Tick Spoofing Schutz)
	if tickDelta < 0 or tickDelta >= MAX_ROLLBACK_TICKS then
		local errMsg = string.format("Latenzfenster überschritten (Delta: %d Ticks)", tickDelta)
		warn(string.format("[ROLLBACK REJECT] %s für %s", errMsg, player.Name))
		return false, errMsg
	end

	-- 3. Abruf der Konfigurationsdaten der Intervention
	local config = INTERVENTION_CATALOG[interventionId]
	if not config then
		local errMsg = string.format("Ungültige Intervention-ID: %d", interventionId)
		warn(string.format("[ROLLBACK REJECT] %s", errMsg))
		return false, errMsg
	end

	-- 4. Finanzielle Vorab-Validierung auf dem Server
	local playerState = PlayerDataStore.getPlayerState(player)
	if not playerState or playerState.Belief < config.BeliefCost then
		local errMsg = "Spieler kann sich Intervention nicht leisten"
		warn(string.format("[ROLLBACK REJECT] %s %s!", player.Name, errMsg))
		return false, errMsg
	end

	-- 5. Historisches Rollback-Zustands-Lookup (Zero-Allocation read)
	local historicalFrame = RingBufferModule.readFrame(clientTick)
	if historicalFrame.Tick == -1 then
		local errMsg = string.format("Frame-Daten überschrieben für Tick %d", clientTick)
		warn(string.format("[ROLLBACK REJECT] %s", errMsg))
		return false, errMsg
	end

	-- 6. Sanity-Check der geometrischen Existenz
	local targetEntity: RingBufferModule.EntitySlot? = nil
	for i = 1, 18 do
		local entity = historicalFrame.Entities[i]
		if entity.Active == 1 and entity.TileIndex == targetTileIndex then
			targetEntity = entity
			break
		end
	end

	local isRealPlayer = false
	pcall(function()
		isRealPlayer = typeof(player) == "Instance" and player:IsA("Player")
	end)

	if not targetEntity then
		local errMsg = string.format("Kein gültiges Ziel auf Kachel %d zu Tick %d", targetTileIndex, clientTick)
		warn(string.format("[SECURITY/ROLLBACK REJECT] %s!", errMsg))
		
		-- Client zur Korrektur zwingen
		if InterventionRemote and isRealPlayer then
			InterventionRemote:FireClient(player, "Correction", serverTick)
		end
		return false, errMsg
	end

	-- HP-Validierung
	if targetEntity.Health <= 0 then
		local errMsg = string.format("Ziel auf Kachel %d war bereits tot", targetTileIndex)
		warn(string.format("[ROLLBACK REJECT] %s bei Tick %d!", errMsg, clientTick))
		
		if InterventionRemote and isRealPlayer then
			InterventionRemote:FireClient(player, "Correction", serverTick)
		end
		return false, errMsg
	end

	-- 7. Mutation des realen Zustands auf dem Server (Belief abziehen)
	PlayerDataStore.adjustBelief(player, -config.BeliefCost)

	-- 8. Ascension-Lock oder Zensur-Protokoll Gegenmaßnahme verarbeiten
	if interventionId == 1 then
		-- Glaubenssturm: Ascension-Lock registrieren
		local id = game:GetService("HttpService"):GenerateGUID(false)
		local newPending: PendingIntervention = {
			id = id,
			player = player,
			clientTick = clientTick,
			targetTileIndex = targetTileIndex,
			interventionId = interventionId,
			castTime = getCurrentTime(),
			active = true
		}
		table.insert(pendingInterventions, newPending)

		print(string.format("[ASCENSION LOCK REGISTERED] %s von %s auf Kachel %d gestartet. 1.5s Ascension-Lock aktiv.", 
			config.Name, player.Name, targetTileIndex))

		-- Visual confirmation an alle Clients, dass der Zauber vorbereitet/angefangen wird
		if InterventionRemote then
			InterventionRemote:FireAllClients("PendingRegistered", player.UserId, clientTick, targetTileIndex, interventionId)
		end
	elseif interventionId == 2 then
		-- Zensur-Protokoll: Bricht alle ausstehenden gegnerischen Interventions auf derselben Kachel ab!
		local cancelledAny = false
		for _, pending in ipairs(pendingInterventions) do
			if pending.targetTileIndex == targetTileIndex and pending.player.UserId ~= player.UserId then
				pending.active = false
				cancelledAny = true
				print(string.format("[CENSORSHIP] Zensur-Protokoll von %s bricht ausstehende Intervention von %s ab!", 
					player.Name, pending.player.Name))
			end
		end

		print(string.format("[ROLLBACK CONFIRMED] Zensur-Protokoll von %s erfolgreich ausgeführt (Abbruch erzielt: %s).", 
			player.Name, tostring(cancelledAny)))

		-- Zensur-Protokoll wirkt sofort, daher bestätigen wir es direkt an alle
		if InterventionRemote then
			InterventionRemote:FireAllClients("Confirmed", player.UserId, clientTick, targetTileIndex, interventionId)
		end
	end

	return true, nil
end

-- Listener für Client-Events (nur verbinden, wenn Remote vorhanden ist)
if InterventionRemote then
	InterventionRemote.OnServerEvent:Connect(function(player, clientTick, targetTileIndex, interventionId)
		RollbackModule.processInterventionRequest(player, clientTick, targetTileIndex, interventionId)
	end)
end

return RollbackModule
