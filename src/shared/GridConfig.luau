--!strict
-- Platziert in: src/shared/GridConfig.luau

export type DeityGridProfile = {
	Width: number,            -- Breite in Gitterzellen (X)
	Length: number,           -- Länge in Gitterzellen (Z)
	BeliefPerSecond: number,  -- Passive Glaubensgenerierung pro Sekunde
	DisplayName: string,      -- Anzeigename im Baumenü
}

export type GridSettings = {
	SizeX: number,            -- Breite des Gitters (Zellenzahl X)
	SizeZ: number,            -- Länge des Gitters (Zellenzahl Z)
	CellSize: number,         -- Größe einer Zelle in Studs (z.B. 4 Studs)
}

local GridConfig = {}

-- Globale Gittereinstellungen für die Zitadelle
GridConfig.Settings = {
	SizeX = 10,
	SizeZ = 10,
	CellSize = 4, -- Jede Zelle ist 4x4 Studs groß
} :: GridSettings

-- Katalog aller Gottheiten und Monument-Profile
GridConfig.DeityProfiles = {
	["old_forest_spirit"] = {
		Width = 2,
		Length = 2,
		BeliefPerSecond = 10, -- Erzeugt passiv 10 Glaubenspunkte pro Sekunde
		DisplayName = "Forest Spirit",
	},
	["sun_temple"] = {
		Width = 3,
		Length = 3,
		BeliefPerSecond = 35,
		DisplayName = "Sun Temple",
	},
	["water_shrine"] = {
		Width = 1,
		Length = 3,
		BeliefPerSecond = 5,
		DisplayName = "Water Shrine",
	},
} :: { [string]: DeityGridProfile }

return GridConfig
