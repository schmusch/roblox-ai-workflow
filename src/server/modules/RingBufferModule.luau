--!strict
local RingBufferModule = {}

-- Typ-Definitionen
export type EntitySlot = {
	Active: number,
	CatalogIndex: number,
	OwnerUserId: number,
	TileIndex: number,
	Health: number,
	ActionPoints: number,
	StatusMask: number,
}

export type CombatFrame = {
	Tick: number,
	Timestamp: number,
	Entities: { [number]: EntitySlot } -- Festes Array der Größe 18
}

-- Konstanten für Puffer-Berechnungen
local MAX_FRAMES = 90
local SLOT_SIZE = 15
local HEADER_SIZE = 12
local FRAME_SIZE = 284 -- 12 + 270 = 282 Bytes (Auf 284 gerundet für Quad-Alignment)
local BUFFER_SIZE = MAX_FRAMES * FRAME_SIZE -- 90 * 284 = 25,560 Bytes

-- Vor-allozierter Luau-Puffer
local combatHistoryBuffer = buffer.create(BUFFER_SIZE)

-- Hilfsstrukturen für die Rückgabe (Wiederverwendbare Table-Dubs, um Allocations zu minimieren)
local cachedFrame: CombatFrame = {
	Tick = 0,
	Timestamp = 0,
	Entities = {}
}

for i = 1, 18 do
	cachedFrame.Entities[i] = {
		Active = 0,
		CatalogIndex = 0,
		OwnerUserId = 0,
		TileIndex = 0,
		Health = 0,
		ActionPoints = 0,
		StatusMask = 0
	}
end

-- Berechnet den Byte-Offset eines Frames
local function getFrameOffset(tick: number): number
	return (tick % MAX_FRAMES) * FRAME_SIZE
end

-- Packt einen Kampf-Zustand direkt in den Binärpuffer
function RingBufferModule.writeFrame(tick: number, timestamp: number, entities: { [number]: EntitySlot })
	local frameOffset = getFrameOffset(tick)
	
	-- 1. Header schreiben
	buffer.writeu32(combatHistoryBuffer, frameOffset, tick)
	buffer.writef64(combatHistoryBuffer, frameOffset + 4, timestamp)
	
	-- 2. Slots schreiben
	for i = 1, 18 do
		local slotOffset = frameOffset + HEADER_SIZE + ((i - 1) * SLOT_SIZE)
		local entity = entities[i]
		
		if entity then
			buffer.writeu8(combatHistoryBuffer, slotOffset, entity.Active)
			buffer.writeu16(combatHistoryBuffer, slotOffset + 1, entity.CatalogIndex)
			buffer.writeu32(combatHistoryBuffer, slotOffset + 3, entity.OwnerUserId)
			buffer.writeu8(combatHistoryBuffer, slotOffset + 7, entity.TileIndex)
			buffer.writef32(combatHistoryBuffer, slotOffset + 8, entity.Health)
			buffer.writeu8(combatHistoryBuffer, slotOffset + 12, entity.ActionPoints)
			buffer.writeu16(combatHistoryBuffer, slotOffset + 13, entity.StatusMask)
		else
			-- Leeren Slot schreiben
			buffer.writeu8(combatHistoryBuffer, slotOffset, 0)
		end
	end
end

-- Entpackt einen Zustand aus dem Puffer in den wiederverwendbaren Cache (Zero-Allocation)
function RingBufferModule.readFrame(tick: number): CombatFrame
	local frameOffset = getFrameOffset(tick)
	
	-- Validieren, ob der geladene Tick mit dem angeforderten übereinstimmt (Puffer-Überschreibungsschutz)
	local storedTick = buffer.readu32(combatHistoryBuffer, frameOffset)
	if storedTick ~= tick then
		-- Der angeforderte Frame wurde bereits überschrieben oder existiert nicht!
		cachedFrame.Tick = -1
		return cachedFrame
	end
	
	cachedFrame.Tick = storedTick
	cachedFrame.Timestamp = buffer.readf64(combatHistoryBuffer, frameOffset + 4)
	
	for i = 1, 18 do
		local slotOffset = frameOffset + HEADER_SIZE + ((i - 1) * SLOT_SIZE)
		local slot = cachedFrame.Entities[i]
		
		slot.Active = buffer.readu8(combatHistoryBuffer, slotOffset)
		if slot.Active == 1 then
			slot.CatalogIndex = buffer.readu16(combatHistoryBuffer, slotOffset + 1)
			slot.OwnerUserId = buffer.readu32(combatHistoryBuffer, slotOffset + 3)
			slot.TileIndex = buffer.readu8(combatHistoryBuffer, slotOffset + 7)
			slot.Health = buffer.readf32(combatHistoryBuffer, slotOffset + 8)
			slot.ActionPoints = buffer.readu8(combatHistoryBuffer, slotOffset + 12)
			slot.StatusMask = buffer.readu16(combatHistoryBuffer, slotOffset + 13)
		else
			slot.CatalogIndex = 0
			slot.OwnerUserId = 0
			slot.TileIndex = 0
			slot.Health = 0
			slot.ActionPoints = 0
			slot.StatusMask = 0
		end
	end
	
	return cachedFrame
end

return RingBufferModule
