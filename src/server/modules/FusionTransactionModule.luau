--!strict
-- Platziert in: src/server/modules/FusionTransactionModule.luau

local PlayerDataStore = require(script.Parent.PlayerDataStore)

local FusionTransactionModule = {}

export type Transaction = {
	Player: Player,
	DeityA: string,
	DeityB: string,
	FusionCost: number,
	OriginalInventory: { [string]: number },
	OriginalBelief: number,
	Status: "locked" | "committed" | "rolled_back",
	Timestamp: number,
}

local activeTransactions: { [Player]: Transaction } = {}

-- Klont ein flaches Dictionary von Inventargegenständen (Deep Copy für Transaktionssicherheit)
local function cloneInventory(inventory: { [string]: number }): { [string]: number }
	local clone = {}
	for k, v in pairs(inventory) do
		clone[k] = v
	end
	return clone
end

-- Startet eine transaktionale Fusion
-- Zieht die Eltern-Deteis und die Glaubenskosten ab und legt sie in einen Sperr-Zustand (Lock)
function FusionTransactionModule.StartFusion(player: Player, deityA: string, deityB: string, fusionCost: number): (boolean, string?)
	-- Prüfen, ob bereits eine Transaktion aktiv ist
	if activeTransactions[player] then
		return false, "Bereits eine Fusion im Gange!"
	end

	local state = PlayerDataStore.getPlayerState(player)

	-- 1. Glaubenskosten prüfen
	if state.Belief < fusionCost then
		return false, "Nicht genügend Glaubenspunkte!"
	end

	-- 2. Inventarbesitz prüfen (Sonderfall: identische Essenzen erfordern Bestand >= 2)
	local countA = state.Inventory[deityA] or 0
	local countB = state.Inventory[deityB] or 0

	if deityA == deityB then
		if countA < 2 then
			return false, "Es werden mindestens 2 Instanzen derselben Gottheit benötigt!"
		end
	else
		if countA < 1 then
			return false, string.format("Gottheit '%s' nicht im Inventar vorhanden!", deityA)
		end
		if countB < 1 then
			return false, string.format("Gottheit '%s' nicht im Inventar vorhanden!", deityB)
		end
	end

	-- 3. Transaktions-Backup erstellen
	local originalInventory = cloneInventory(state.Inventory)
	local originalBelief = state.Belief

	-- 4. Ressourcen abziehen & Sperren (Lock-Phase)
	local consumeSuccessA = PlayerDataStore.consumeInventoryItem(player, deityA)
	local consumeSuccessB = PlayerDataStore.consumeInventoryItem(player, deityB)
	local adjustSuccess = PlayerDataStore.adjustBelief(player, -fusionCost)

	if not (consumeSuccessA and consumeSuccessB and adjustSuccess) then
		-- Fallback im seltenen Synchronisationsfehler
		PlayerDataStore.forceUpdateInventory(player, originalInventory)
		local stateReloaded = PlayerDataStore.getPlayerState(player)
		stateReloaded.Belief = originalBelief
		player:SetAttribute("CitadelBelief", originalBelief)
		return false, "Fehler beim Sperren der Fusions-Ressourcen!"
	end

	-- 5. Transaktion registrieren
	local tx: Transaction = {
		Player = player,
		DeityA = deityA,
		DeityB = deityB,
		FusionCost = fusionCost,
		OriginalInventory = originalInventory,
		OriginalBelief = originalBelief,
		Status = "locked",
		Timestamp = os.clock(),
	}

	activeTransactions[player] = tx
	return true
end

-- Simuliert den Schreibvorgang (Database Write / DataStore save)
-- Bricht ab und rollt zurück, wenn simulatedFailure wahr ist (Blackout-Simulation)
function FusionTransactionModule.ProcessWrite(player: Player, simulatedFailure: boolean?): (boolean, string)
	local tx = activeTransactions[player]
	if not tx then
		return false, "Keine aktive Transaktionssperre für diesen Spieler gefunden!"
	end

	if simulatedFailure then
		-- Rollback ausführen
		FusionTransactionModule.Rollback(player)
		return false, "Verbindungsabbruch zur Datenbank! Die Fusion wurde sicher zurückgerollt."
	end

	-- Erfolgreiche Transaktion: Hybrid-Gottheit erstellen
	-- Benennungsschema: hybrid__deityA__deityB (Doppel-Unterstrich zur ausnahmslos sicheren Trennung)
	local hybridId = string.format("hybrid__%s__%s", tx.DeityA, tx.DeityB)
	PlayerDataStore.grantInventoryItem(player, hybridId)

	tx.Status = "committed"
	activeTransactions[player] = nil -- Aus aktiver Queue entfernen

	return true, "Fusion erfolgreich durchgeführt! Hybrid-Gottheit wurde im Inventar hinterlegt."
end

-- Entkoppelt einen stabilisierten Hybrid-Gott gegen eine Glaubensgebühr und erstattet die beiden Eltern-Essenzen zurück
function FusionTransactionModule.UnfuseHybrid(player: Player, hybridId: string, unfuseFee: number): (boolean, string?)
	local state = PlayerDataStore.getPlayerState(player)

	-- 1. Glaubensguthaben für Entkopplungsgebühr prüfen
	if state.Belief < unfuseFee then
		return false, "Nicht genügend Glaubenspunkte für die Entkoppelungsgebühr!"
	end

	-- 2. Besitz der Hybrid-Gottheit im Inventar prüfen
	if not PlayerDataStore.hasInventoryItem(player, hybridId) then
		return false, "Die angegebene Hybrid-Gottheit befindet sich nicht in deinem Inventar!"
	end

	-- 3. Hybrid-ID parsen
	if not string.match(hybridId, "^hybrid__") then
		return false, "Es handelt sich nicht um eine gültige fusionierte Hybrid-Gottheit!"
	end

	local parts = string.split(hybridId, "__")
	if #parts < 3 or parts[1] ~= "hybrid" then
		return false, "Ungültiges Format der Hybrid-Gottheit-ID!"
	end

	local deityA = parts[2]
	local deityB = parts[3]

	-- 4. Gebühr abziehen und Hybrid-Monument entfernen
	local adjustSuccess = PlayerDataStore.adjustBelief(player, -unfuseFee)
	local consumeSuccess = PlayerDataStore.consumeInventoryItem(player, hybridId)

	if not (adjustSuccess and consumeSuccess) then
		return false, "Fehler beim Abbuchen der Gebühr oder beim Entfernen des Hybrids!"
	end

	-- 5. Beide Original-Elternteile wieder im Inventar gutschreiben
	PlayerDataStore.grantInventoryItem(player, deityA)
	PlayerDataStore.grantInventoryItem(player, deityB)

	return true, nil
end

-- Führt einen sicheren Rollback aus und erstattet alle gesperrten Ressourcen zurück
function FusionTransactionModule.Rollback(player: Player): boolean
	local tx = activeTransactions[player]
	if not tx then
		return false
	end

	-- Ressourcen und Glauben aus dem Backup wiederherstellen
	local state = PlayerDataStore.getPlayerState(player)
	state.Belief = tx.OriginalBelief
	player:SetAttribute("CitadelBelief", tx.OriginalBelief)

	PlayerDataStore.forceUpdateInventory(player, tx.OriginalInventory)

	tx.Status = "rolled_back"
	activeTransactions[player] = nil -- Aus aktiver Queue entfernen

	return true
end

-- Holt die aktuell laufende Transaktionsreferenz zur Inspektion (z.B. in Tests)
function FusionTransactionModule.GetActiveTransaction(player: Player): Transaction?
	return activeTransactions[player]
end

-- Säubert alle Transaktionen (z.B. nach Tests)
function FusionTransactionModule.ClearAll()
	activeTransactions = {}
end

return FusionTransactionModule
