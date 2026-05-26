--!strict
local DeityCatalog = {}

export type Faction = "AlteGoetter" | "NeueGoetter"
export type Element = "Erde" | "Daten" | "Feuer" | "Medien" | "Aether" | "Finanzen"
export type CombatRole = "Tank" | "Supporter" | "Slayer" | "Controller"

export type DeityConfig = {
	Id: string,
	Name: string,
	Faction: Faction,
	Element: Element,
	Role: CombatRole,
	AttackRange: number,
	BasePrice: number,
	BaseProduction: number, -- Glaubensgenerierung pro Sekunde
	BaseRadius: number,     -- R_0 für orbitalen Halo
	BaseOmega: number,      -- w_0 für Rotationsgeschwindigkeit
}

-- Fallback-Profil für Unit-Tests oder unbekannte IDs (Zero-Allocation, statisch definiert)
local FALLBACK_PROFILE: DeityConfig = {
	Id = "unknown",
	Name = "Unknown Deity",
	Faction = "AlteGoetter",
	Element = "Erde",
	Role = "Slayer",
	AttackRange = 999.0, -- Standardmäßig sehr hohe Reichweite zur Abwärtskompatibilität in alten Specs
	BasePrice = 0,
	BaseProduction = 0,
	BaseRadius = 10.0,
	BaseOmega = 1.0,
}

-- Standardkatalog von Gottheiten
local Profiles: { [number]: DeityConfig } = {
	[101] = {
		Id = "old_forest_spirit",
		Name = "Forest Spirit",
		Faction = "AlteGoetter",
		Element = "Erde",
		Role = "Supporter",
		AttackRange = 4.0,
		BasePrice = 300,
		BaseProduction = 10,
		BaseRadius = 10,
		BaseOmega = 1.0,
	},
	[102] = {
		Id = "sun_temple",
		Name = "Sun Temple",
		Faction = "NeueGoetter",
		Element = "Feuer",
		Role = "Tank",
		AttackRange = 1.5,
		BasePrice = 1200,
		BaseProduction = 35,
		BaseRadius = 15,
		BaseOmega = 0.5,
	},
	[103] = {
		Id = "water_shrine",
		Name = "Water Shrine",
		Faction = "AlteGoetter",
		Element = "Daten",
		Role = "Slayer",
		AttackRange = 2.5,
		BasePrice = 500,
		BaseProduction = 5,
		BaseRadius = 8,
		BaseOmega = 1.5,
	},
	[104] = {
		Id = "media_nexus",
		Name = "Media Nexus",
		Faction = "NeueGoetter",
		Element = "Medien",
		Role = "Controller",
		AttackRange = 3.5,
		BasePrice = 800,
		BaseProduction = 20,
		BaseRadius = 12,
		BaseOmega = 0.8,
	}
}

-- Holt das Profil für einen gegebenen CatalogIndex (Zero-Allocation, gibt statischen Record oder Referenz zurück)
function DeityCatalog.GetProfile(catalogIndex: number): DeityConfig
	local profile = Profiles[catalogIndex]
	if not profile then
		return FALLBACK_PROFILE
	end
	return profile
end

return DeityCatalog
