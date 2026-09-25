--!strict
-- Fishing locations. Every island has its own character table, and every spot on an
-- island can tilt that table (bonus Luck, mutation weighting, or a boosted tag).
--
-- table entries: { id, w } where w is the base encounter weight (only relative size matters).
--   weather = only fishable during these weather events
--   moon    = only fishable during these moon phases
--   moonBoost = weight multiplier per moon phase
--
-- Spots are placed by polar coordinates around the island centre so the world builder and the
-- fishing code agree on where they are. kind "dock" builds a pier out into the sea; "pond" builds
-- a pool on the island itself.

export type TableEntry = {
	id: string,
	w: number,
	weather: { string }?,
	moon: { string }?,
	moonBoost: { [string]: number }?,
}

export type Spot = {
	id: string,
	name: string,
	kind: string,
	angle: number,
	dist: number,
	luck: number?,
	mutationMult: number?,
	tagBoost: { [string]: number }?,
	blurb: string,
}

export type Island = {
	id: string,
	name: string,
	theme: string,
	order: number,
	center: Vector3,
	radius: number,
	minBoatSpeed: number,
	permanentNight: boolean?,
	event: boolean?,
	blurb: string,
	table: { TableEntry },
	spots: { Spot },
}

local list: { Island } = {
	{
		id = "sakura_shore", name = "Sakura Shore", theme = "sakura", order = 1,
		center = Vector3.new(0, 0, 0), radius = 150, minBoatSpeed = 0,
		blurb = "A Japanese seaside village. Where every fisher starts.",
		table = {
			{ id = "miko_airi", w = 18 },
			{ id = "nana_kato", w = 15 },
			{ id = "mimi", w = 13 },
			{ id = "maid_rina", w = 10 },
			{ id = "yuki_hanazawa", w = 8 },
			{ id = "hana", w = 7 },
			{ id = "kira_amane", w = 5 },
			{ id = "saki", w = 4 },
			{ id = "reina", w = 3 },
			{ id = "kitsune_yae", w = 1.5 },
			{ id = "demon_princess_rei", w = 0.8 },
			{ id = "crimson_heiress", w = 0.1 },
			{ id = "the_forgotten", w = 0.01 },
		},
		spots = {
			{ id = "village_pier", name = "Village Pier", kind = "dock", angle = 0, dist = 195, blurb = "Basic characters." },
			{ id = "shrine_pond", name = "Shrine Pond", kind = "pond", angle = 205, dist = 75, tagBoost = { shrine = 2.5 }, blurb = "Shrine-themed Waifus bite more often." },
			{ id = "lighthouse", name = "Lighthouse", kind = "dock", angle = 115, dist = 185, luck = 25, blurb = "+25 Luck." },
			{ id = "secret_cove", name = "Secret Cove", kind = "dock", angle = 295, dist = 175, mutationMult = 1.5, blurb = "Better mutation weighting." },
		},
	},
	{
		id = "oni_coast", name = "Oni Coast", theme = "oni", order = 2,
		center = Vector3.new(750, 0, -250), radius = 130, minBoatSpeed = 40,
		blurb = "Black sand, red torii and a burning mountain. Demon Waifus.",
		table = {
			{ id = "oni_apprentice", w = 30 },
			{ id = "fox_maiden", w = 18 },
			{ id = "demon_maid", w = 16 },
			{ id = "oni_warrior", w = 9 },
			{ id = "kitsune_princess", w = 7 },
			{ id = "demon_princess", w = 2 },
			{ id = "nine_tail_empress", w = 0.6 },
			{ id = "forgotten_oni", w = 0.08 },
		},
		spots = {
			{ id = "black_sand", name = "Black Sand Beach", kind = "dock", angle = 180, dist = 170, blurb = "The standard Oni Coast table." },
			{ id = "torii_shallows", name = "Torii Shallows", kind = "dock", angle = 60, dist = 170, tagBoost = { demon = 1.5 }, blurb = "Demon Waifus bite more often." },
			{ id = "volcano_pool", name = "Volcano Pool", kind = "pond", angle = 300, dist = 60, luck = 30, blurb = "+30 Luck." },
		},
	},
	{
		id = "moonlit_village", name = "Moonlit Village", theme = "moonlit", order = 3,
		center = Vector3.new(-750, 0, -250), radius = 130, minBoatSpeed = 60, permanentNight = true,
		blurb = "Permanent night. Vampires, witches and ghosts. The moon decides who bites.",
		table = {
			{ id = "ghost_girl", w = 28 },
			{ id = "black_cat_girl", w = 24 },
			{ id = "witch_girl", w = 15 },
			{ id = "crimson_vampire", w = 14 },
			{ id = "moon_witch", w = 8, moonBoost = { Crescent = 2 } },
			{ id = "blood_countess", w = 2.5, moonBoost = { Full = 2 } },
			{ id = "night_empress", w = 0.7, moonBoost = { New = 3 } },
			{ id = "lunar_sovereign", w = 0.15, moon = { "Full" } },
			{ id = "the_unburied", w = 0.01 },
		},
		spots = {
			{ id = "haunted_lake", name = "Haunted Lake", kind = "dock", angle = 0, dist = 170, blurb = "The standard Moonlit table." },
			{ id = "cemetery_pond", name = "Cemetery Pond", kind = "pond", angle = 140, dist = 70, tagBoost = { ghost = 2 }, blurb = "Ghost Waifus bite more often." },
			{ id = "castle_moat", name = "Castle Moat", kind = "pond", angle = 250, dist = 65, luck = 30, blurb = "+30 Luck." },
		},
	},
	{
		id = "celestial_haven", name = "Celestial Haven", theme = "celestial", order = 4,
		center = Vector3.new(0, 450, 650), radius = 110, minBoatSpeed = 70,
		blurb = "Floating heavenly waters above the clouds. Angels.",
		table = {
			{ id = "sky_maiden", w = 30 },
			{ id = "celestial_priestess", w = 22 },
			{ id = "valkyrie", w = 14 },
			{ id = "seraph", w = 5 },
			{ id = "heavenly_guardian", w = 5 },
			{ id = "six_winged_seraph", w = 0.7 },
			{ id = "fallen_angel", w = 0.7 },
			{ id = "broken_seraph", w = 0.08 },
			{ id = "starless", w = 0.03, weather = { "CelestialStorm", "HuecoVoid" } },
		},
		spots = {
			{ id = "cloud_pool", name = "Cloud Pool", kind = "pond", angle = 0, dist = 60, blurb = "The standard Celestial table." },
			{ id = "sky_falls", name = "Sky Falls", kind = "pond", angle = 130, dist = 65, mutationMult = 1.35, blurb = "Better mutation weighting." },
			{ id = "temple_spring", name = "Temple Spring", kind = "pond", angle = 240, dist = 60, luck = 35, blurb = "+35 Luck." },
		},
	},
	{
		id = "demon_academy", name = "Demon Academy", theme = "academy", order = 5,
		center = Vector3.new(0, 0, -850), radius = 120, minBoatSpeed = 40, event = true,
		blurb = "LIMITED EVENT. Event Waifus stay tradeable after it ends.",
		table = {
			{ id = "nana_kato", w = 35 },
			{ id = "kira_amane", w = 25 },
			{ id = "maid_rina", w = 20 },
			{ id = "reina", w = 10 },
			{ id = "fallen_nun", w = 3 },
			{ id = "white_dragon_princess", w = 0.8 },
			{ id = "sword_saint", w = 0.8 },
			{ id = "crimson_heiress_academy", w = 0.1 },
			{ id = "ice_queen", w = 0.1 },
		},
		spots = {
			{ id = "school_pool", name = "School Pool", kind = "pond", angle = 40, dist = 58, blurb = "The standard Academy table." },
			{ id = "academy_fountain", name = "Courtyard Fountain", kind = "pond", angle = 150, dist = 60, mutationMult = 1.3, blurb = "Better mutation weighting." },
			{ id = "hidden_pond", name = "Hidden Pond", kind = "pond", angle = 260, dist = 70, luck = 40, tagBoost = { event = 1.5 }, blurb = "+40 Luck, event Waifus bite more often." },
		},
	},
}

-- Secrets that can surface from any water in the world.
local globalTable: { TableEntry } = {
	{ id = "the_drowned", w = 0.004 },
	{ id = "unknown", w = 0.003, weather = { "Mystery" } },
}

local MOON_PHASES = { "New", "Crescent", "Half", "Gibbous", "Full" }

local byId: { [string]: Island } = {}
local spotsById: { [string]: Spot } = {}
local islandOfSpot: { [string]: Island } = {}
for _, island in list do
	byId[island.id] = island
	for _, spot in island.spots do
		spotsById[spot.id] = spot
		islandOfSpot[spot.id] = island
	end
end

local function spotPosition(island: Island, spot: Spot): Vector3
	local a = math.rad(spot.angle)
	return island.center + Vector3.new(math.cos(a) * spot.dist, 0, math.sin(a) * spot.dist)
end

local function arrivalPosition(island: Island): Vector3
	-- Just inside the shore toward the first spot.
	local first = island.spots[1]
	local a = math.rad(first.angle)
	local r = island.radius - 25
	return island.center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
end

local function islandAt(position: Vector3): Island?
	for _, island in list do
		local flat = Vector3.new(position.X - island.center.X, 0, position.Z - island.center.Z)
		if flat.Magnitude < island.radius + 90 and math.abs(position.Y - island.center.Y) < 150 then
			return island
		end
	end
	return nil
end

return {
	list = list,
	byId = byId,
	spotsById = spotsById,
	islandOfSpot = islandOfSpot,
	globalTable = globalTable,
	MOON_PHASES = MOON_PHASES,
	SPOT_RADIUS = 20,
	spotPosition = spotPosition,
	arrivalPosition = arrivalPosition,
	islandAt = islandAt,
}
