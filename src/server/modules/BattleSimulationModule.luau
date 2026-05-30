--!strict
local BattleSimulationModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RingBufferModule = require(script.Parent.RingBufferModule)
local DeityCatalog = require(ReplicatedStorage.Shared.DeityCatalog)

type EntitySlot = RingBufferModule.EntitySlot

-- Interner statischer Zustand für 18 Entities
local currentEntities: { [number]: EntitySlot } = {}
for i = 1, 18 do
	currentEntities[i] = {
		Active = 0,
		CatalogIndex = 0,
		OwnerUserId = 0,
		TileIndex = 0,
		Health = 0.0,
		ActionPoints = 0,
		StatusMask = 0
	}
end

-- Statische Rollenpräferenzen, einmalig definiert zur Vermeidung von GC-Allokationen
local TARGET_PREFERENCES = {
	Tank = { "Tank", "Slayer", "Controller", "Supporter" },
	Slayer = { "Supporter", "Slayer", "Controller", "Tank" },
	Supporter = { "Supporter", "Controller", "Slayer", "Tank" },
	Controller = { "Controller", "Supporter", "Slayer", "Tank" },
}

-- Berechnet die virtuellen 2D-Koordinaten auf einem 3x6-Gitter für jeden Slot
local function getSlotCoords(i: number): (number, number)
	if i <= 9 then
		return (i - 1) % 3 + 1, math.floor((i - 1) / 3) + 1
	else
		local localIdx = i - 9
		return (localIdx - 1) % 3 + 1, math.floor((localIdx - 1) / 3) + 4
	end
end

-- Initialisiert den Kampfzustand mit 18 Deities durch Kopieren der Werte (Zero-Allocation)
function BattleSimulationModule.initialize(entities: { [number]: EntitySlot })
	for i = 1, 18 do
		local source = entities[i]
		local target = currentEntities[i]
		if source then
			target.Active = source.Active
			target.CatalogIndex = source.CatalogIndex
			target.OwnerUserId = source.OwnerUserId
			target.TileIndex = source.TileIndex
			target.Health = source.Health
			target.ActionPoints = source.ActionPoints
			target.StatusMask = source.StatusMask
		else
			target.Active = 0
			target.CatalogIndex = 0
			target.OwnerUserId = 0
			target.TileIndex = 0
			target.Health = 0.0
			target.ActionPoints = 0
			target.StatusMask = 0
		end
	end
end

-- Führt einen einzelnen 60Hz-Kampf-Tick aus
function BattleSimulationModule.step(tick: number, timestamp: number)
	for i = 1, 18 do
		local entity = currentEntities[i]
		if entity.Active == 1 and entity.Health > 0 then
			-- AP inkrementieren (um 1 AP pro Tick)
			local newAP = entity.ActionPoints + 1
			if newAP >= 100 then
				-- Taktisches euklidisches Targeting (Story 3.3)
				local attackerProfile = DeityCatalog.GetProfile(entity.CatalogIndex)
				local attackerRole = attackerProfile.Role
				local attackRange = attackerProfile.AttackRange

				-- Slots 1-9 gehören Spieler A, 10-18 gehören Spieler B
				local startIdx = if i <= 9 then 10 else 1
				local endIdx = if i <= 9 then 18 else 9
				
				local bestTargetIdx = -1
				local minDistance = 999999.0
				local prefList = TARGET_PREFERENCES[attackerRole]

				-- Suche in Reihenfolge der Rollenpräferenz
				for rIdx = 1, 4 do
					local targetRole = prefList[rIdx]
					
					-- Suche nach einem aktiven, lebenden Gegner dieser Rolle im Suchbereich
					for targetIdx = startIdx, endIdx do
						local target = currentEntities[targetIdx]
						if target.Active == 1 and target.Health > 0 then
							local targetProfile = DeityCatalog.GetProfile(target.CatalogIndex)
							if targetProfile.Role == targetRole then
								-- Berechne euklidischen Abstand
								local c1, r1 = getSlotCoords(i)
								local c2, r2 = getSlotCoords(targetIdx)
								local dx = c2 - c1
								local dz = r2 - r1
								local dist = math.sqrt(dx * dx + dz * dz)
								
								if dist <= attackRange then
									-- Wähle den nähesten. Bei gleichem Abstand entscheidet der niedrigere TileIndex (Tie-Breaker)
									if dist < minDistance then
										minDistance = dist
										bestTargetIdx = targetIdx
									elseif math.abs(dist - minDistance) < 0.0001 then
										if targetIdx < bestTargetIdx then
											bestTargetIdx = targetIdx
										end
									end
								end
							end
						end
					end
					
					-- Wenn wir auf dieser Prioritätsstufe mindestens ein Ziel gefunden haben, brechen wir ab
					if bestTargetIdx ~= -1 then
						break
					end
				end

				-- Ausführen des Angriffs, wenn ein gültiges Ziel gefunden wurde
				if bestTargetIdx ~= -1 then
					entity.ActionPoints = 0
					local target = currentEntities[bestTargetIdx]
					local newHealth = target.Health - 10.0
					if newHealth < 0 then
						newHealth = 0.0
					end
					target.Health = newHealth
				else
					-- Wenn kein Ziel in Reichweite/aktiv ist, halten wir AP bei 100
					entity.ActionPoints = 100
				end
			else
				entity.ActionPoints = newAP
			end
		end
	end
	
	-- Speichere den Zustand im RingBuffer
	RingBufferModule.writeFrame(tick, timestamp, currentEntities)
end

-- Gibt das interne statische Entity-Array zurück (Achtung: nicht modifizieren, da geteilter Zustand!)
function BattleSimulationModule.getEntities(): { [number]: EntitySlot }
	return currentEntities
end

return BattleSimulationModule
