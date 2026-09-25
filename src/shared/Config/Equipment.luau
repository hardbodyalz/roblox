--!strict
-- Rods, boats, bait and storage. Passive *effects* are implemented in Modifiers.luau,
-- keyed by passive id; this file only holds the numbers and the text players read.

local rgb = Color3.fromRGB

export type Passive = { id: string, name: string, desc: string }

export type Rod = {
	id: string,
	name: string,
	price: number?, -- nil = not sold in the shop
	luck: number,
	control: number,
	resilience: number,
	maxKg: number,
	speed: number, -- % faster bites
	castRange: number, -- studs at full cast power
	color: Color3, -- rod model colours
	accent: Color3,
	passive: Passive,
	secret: boolean?,
}

export type Boat = {
	id: string,
	name: string,
	price: number?,
	speed: number,
	handling: number,
	capacity: number, -- extra storage slots while equipped
	luck: number,
	passive: Passive,
}

export type Bait = {
	id: string,
	name: string,
	price: number, -- per pack
	pack: number,
	luck: number,
	tagBoost: { [string]: number }?,
	mutationBoost: { [string]: number }?,
	desc: string,
}

local rods: { Rod } = {
	{
		id = "old_rod", name = "Old Rod", price = 0, luck = 5, control = 15, resilience = 10, maxKg = 25, speed = 0, castRange = 35,
		color = rgb(120, 85, 55), accent = rgb(200, 200, 205),
		passive = { id = "beginners_fortune", name = "Beginner's Fortune", desc = "Small chance to gain bonus Yen from low-rarity catches." },
	},
	{
		id = "sakura_rod", name = "Sakura Rod", price = 5000, luck = 15, control = 25, resilience = 15, maxKg = 50, speed = 5, castRange = 40,
		color = rgb(255, 180, 210), accent = rgb(255, 255, 255),
		passive = { id = "sakura_blessing", name = "Sakura Blessing", desc = "Slightly increased mutation weighting at Sakura Shore." },
	},
	{
		id = "driftwood_rod", name = "Driftwood Rod", price = 20000, luck = 25, control = 30, resilience = 20, maxKg = 75, speed = 15, castRange = 50,
		color = rgb(160, 140, 110), accent = rgb(90, 180, 200),
		passive = { id = "tidecaller", name = "Tidecaller", desc = "Bites come a further 15% faster." },
	},
	{
		id = "torii_rod", name = "Torii Rod", price = 60000, luck = 35, control = 30, resilience = 30, maxKg = 120, speed = 10, castRange = 50,
		color = rgb(210, 45, 40), accent = rgb(30, 25, 25),
		passive = { id = "shrine_ward", name = "Shrine Ward", desc = "Shrine-themed Waifus receive increased encounter weighting." },
	},
	{
		id = "kitsune_rod", name = "Kitsune Rod", price = 120000, luck = 45, control = 35, resilience = 25, maxKg = 150, speed = 10, castRange = 55,
		color = rgb(255, 150, 60), accent = rgb(255, 245, 230),
		passive = { id = "foxfire", name = "Foxfire", desc = "Fox Waifus receive greatly increased encounter weighting." },
	},
	{
		id = "demon_rod", name = "Demon Rod", price = 250000, luck = 55, control = 40, resilience = 35, maxKg = 200, speed = 10, castRange = 55,
		color = rgb(60, 20, 25), accent = rgb(230, 40, 50),
		passive = { id = "infernal_attraction", name = "Infernal Attraction", desc = "Demon-themed Waifus receive increased encounter weighting." },
	},
	{
		id = "moonlight_rod", name = "Moonlight Rod", price = 500000, luck = 70, control = 45, resilience = 40, maxKg = 250, speed = 15, castRange = 60,
		color = rgb(70, 80, 150), accent = rgb(200, 210, 255),
		passive = { id = "lunar_blessing", name = "Lunar Blessing", desc = "+15% Luck at night. Extra mutation weighting during a Full Moon." },
	},
	{
		id = "celestial_rod", name = "Celestial Rod", price = 1000000, luck = 100, control = 60, resilience = 60, maxKg = 500, speed = 20, castRange = 70,
		color = rgb(250, 245, 230), accent = rgb(255, 205, 80),
		passive = { id = "divine_favor", name = "Divine Favor", desc = "Improves weighting for Divine and Eternal Waifus." },
	},
	{
		id = "void_rod", name = "Void Rod", price = 10000000, luck = 180, control = 90, resilience = 90, maxKg = 1000, speed = 25, castRange = 80,
		color = rgb(25, 10, 40), accent = rgb(170, 60, 255),
		passive = { id = "rift_fishing", name = "Rift Fishing", desc = "During Hueco Void: massively improved Void fishing." },
	},
	{
		id = "secret_rod", name = "???", price = nil, luck = 250, control = 100, resilience = 100, maxKg = 2000, speed = 30, castRange = 90,
		color = rgb(10, 10, 12), accent = rgb(255, 255, 255), secret = true,
		passive = { id = "unknown_passive", name = "???", desc = "???" },
	},
}

local boats: { Boat } = {
	{ id = "old_minnow", name = "Old Minnow", price = 0, speed = 25, handling = 50, capacity = 10, luck = 0,
		passive = { id = "reliable", name = "Reliable", desc = "Basic ocean hazards have reduced impact." } },
	{ id = "sakura_skiff", name = "Sakura Skiff", price = 15000, speed = 40, handling = 75, capacity = 15, luck = 2,
		passive = { id = "cherry_current", name = "Cherry Current", desc = "+10% speed around Sakura Shore." } },
	{ id = "bluefin", name = "Bluefin", price = 75000, speed = 60, handling = 60, capacity = 25, luck = 5,
		passive = { id = "swift_current", name = "Swift Current", desc = "+15% travel speed." } },
	{ id = "moonwake", name = "Moonwake", price = 250000, speed = 65, handling = 70, capacity = 30, luck = 8,
		passive = { id = "lunar_sail", name = "Lunar Sail", desc = "+20% speed at night." } },
	{ id = "crimson_cutter", name = "Crimson Cutter", price = 750000, speed = 70, handling = 55, capacity = 35, luck = 10,
		passive = { id = "blood_current", name = "Blood Current", desc = "+30% speed during Blood Moon." } },
	{ id = "demon_vessel", name = "Demon Vessel", price = 2500000, speed = 80, handling = 60, capacity = 50, luck = 15,
		passive = { id = "infernal_wake", name = "Infernal Wake", desc = "Improves demon Waifu encounter weighting." } },
	{ id = "celestial_cruiser", name = "Celestial Cruiser", price = 10000000, speed = 90, handling = 85, capacity = 75, luck = 20,
		passive = { id = "heavens_favor", name = "Heaven's Favor", desc = "+10% fishing Luck." } },
	{ id = "void_cruiser", name = "Void Cruiser", price = 50000000, speed = 110, handling = 90, capacity = 100, luck = 30,
		passive = { id = "rift_drive", name = "Rift Drive", desc = "Improved Void mutation weighting." } },
	{ id = "waifu_carrier", name = "Waifu Carrier", price = 150000000, speed = 75, handling = 50, capacity = 250, luck = 40,
		passive = { id = "collector", name = "Collector", desc = "Every 100 catches grants 5 minutes of +50% Luck." } },
}

local baits: { Bait } = {
	{ id = "normal", name = "Normal Bait", price = 0, pack = 0, luck = 0, desc = "Standard fishing table. Never runs out." },
	{ id = "sweet", name = "Sweet Bait", price = 750, pack = 10, luck = 20, desc = "+20 Luck: improved rare Waifu weighting." },
	{ id = "demon", name = "Demon Bait", price = 3000, pack = 10, luck = 5, tagBoost = { demon = 2.5 }, desc = "Improved demon Waifu weighting." },
	{ id = "angel", name = "Angel Bait", price = 8000, pack = 10, luck = 5, tagBoost = { celestial = 2.5 }, desc = "Improved celestial Waifu weighting." },
	{ id = "void", name = "Void Bait", price = 50000, pack = 10, luck = 10, tagBoost = { void = 3 }, mutationBoost = { Void = 1.5 }, desc = "Improved Void weighting and Void mutations." },
	{ id = "event", name = "Event Bait", price = 5000, pack = 10, luck = 10, tagBoost = { event = 2.5 }, desc = "Improved event Waifu weighting." },
}

-- Storage upgrades (base slots, before boat capacity).
local storage = {
	{ slots = 50, price = 0 },
	{ slots = 100, price = 2000 },
	{ slots = 250, price = 15000 },
	{ slots = 500, price = 60000 },
	{ slots = 1000, price = 250000 },
	{ slots = 2500, price = 1000000 },
	{ slots = 5000, price = 5000000 },
}

local function index<T>(items: { T }): { [string]: T }
	local out = {}
	for _, item in items do
		out[(item :: any).id] = item
	end
	return out
end

return {
	rods = rods,
	boats = boats,
	baits = baits,
	storage = storage,
	rodsById = index(rods),
	boatsById = index(boats),
	baitsById = index(baits),
}
