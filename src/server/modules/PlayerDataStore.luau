--!strict
local PlayerDataStore = {}

type PlayerState = {
	Belief: number,
	Inventory: { [string]: number }
}

local States: { [Player]: PlayerState } = {}

-- Setzt den Zustand eines Spielers (wird fuer Initialisierung und Mocking in Tests genutzt)
function PlayerDataStore.setPlayerState(player: Player, state: PlayerState)
	States[player] = state
end

-- Gibt den aktuellen Zustand des Spielers zurueck
function PlayerDataStore.getPlayerState(player: Player): PlayerState
	local state = States[player]
	if not state then
		-- Fallback-Zustand, falls nicht initialisiert
		state = {
			Belief = 0,
			Inventory = {}
		}
		States[player] = state
	end
	return state
end

-- Zieht Belief-Punkte ab oder fuegt sie hinzu
function PlayerDataStore.adjustBelief(player: Player, amount: number): boolean
	local state = PlayerDataStore.getPlayerState(player)
	if state.Belief + amount < 0 then
		return false -- Nicht genügend Glaubenspunkte!
	end
	state.Belief = state.Belief + amount
	
	-- Synchronisiere den aktuellen Kontostand auf dem Spieler-Objekt für den Client (JSON-Sync bypass via native Attribute)
	pcall(function()
		(player :: any):SetAttribute("CitadelBelief", state.Belief)
	end)
	
	return true
end

-- Ueberprueft, ob der Spieler ein Item im Inventar besitzt
function PlayerDataStore.hasInventoryItem(player: Player, deityId: string): boolean
	local state = PlayerDataStore.getPlayerState(player)
	local count = state.Inventory[deityId] or 0
	return count > 0
end

-- Zieht ein Item aus dem Inventar ab
function PlayerDataStore.consumeInventoryItem(player: Player, deityId: string): boolean
	local state = PlayerDataStore.getPlayerState(player)
	local count = state.Inventory[deityId] or 0
	if count <= 0 then
		return false -- Nicht im Inventar vorhanden!
	end
	
	state.Inventory[deityId] = count - 1
	if state.Inventory[deityId] == 0 then
		state.Inventory[deityId] = nil :: any -- Aus dem Diktionaer entfernen (Heap-Leak Schutz)
	end
	return true
end

-- Raeumt den Speicher auf, wenn ein Spieler das Spiel verlaesst
function PlayerDataStore.clearPlayerState(player: Player)
	States[player] = nil
end

return PlayerDataStore
