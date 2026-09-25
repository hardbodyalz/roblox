--!strict
-- Weather exists to manipulate the mutation roll. It is server-wide: everyone sees the same sky.
--
-- weight: chance of being picked when the current weather ends.
-- duration: seconds { min, max }.
-- mutationBoost: multiplier on that mutation's weighting while active.
-- rarityBoost / tagBoost: multipliers on the character roll (Blood Moon, Hueco Void).
-- major: announced to the whole server when it begins.

export type Weather = {
	id: string,
	name: string,
	weight: number,
	duration: { number },
	mutationBoost: { [string]: number },
	rarityBoost: { [string]: number }?,
	tagBoost: { [string]: number }?,
	major: boolean,
	color: Color3,
	blurb: string,
}

local list: { Weather } = {
	{
		id = "Sunny", name = "Sunny", weight = 50, duration = { 150, 240 }, mutationBoost = {}, major = false,
		color = Color3.fromRGB(255, 230, 140), blurb = "Normal fishing.",
	},
	{
		id = "Rain", name = "Rain", weight = 20, duration = { 150, 240 }, mutationBoost = { Shiny = 3 }, major = false,
		color = Color3.fromRGB(130, 170, 220), blurb = "Shiny mutations boosted.",
	},
	{
		id = "GoldenHour", name = "Golden Hour", weight = 12, duration = { 120, 180 }, mutationBoost = { Golden = 3 }, major = false,
		color = Color3.fromRGB(255, 190, 70), blurb = "Golden mutations boosted.",
	},
	{
		id = "DiamondStorm", name = "Diamond Storm", weight = 7, duration = { 120, 180 }, mutationBoost = { Diamond = 3 }, major = true,
		color = Color3.fromRGB(140, 235, 255), blurb = "Diamond mutations boosted.",
	},
	{
		id = "EtherealFog", name = "Ethereal Fog", weight = 5, duration = { 120, 180 }, mutationBoost = { Ethereal = 3 }, major = true,
		color = Color3.fromRGB(215, 200, 255), blurb = "Ethereal mutations boosted.",
	},
	{
		id = "CelestialStorm", name = "Celestial Storm", weight = 3, duration = { 120, 180 }, mutationBoost = { Celestial = 4 }, major = true,
		tagBoost = { celestial = 1.5 },
		color = Color3.fromRGB(255, 240, 180), blurb = "Celestial mutations boosted. Celestial Waifus stir.",
	},
	{
		id = "BloodMoon", name = "Blood Moon", weight = 2.5, duration = { 120, 180 }, mutationBoost = {}, major = true,
		rarityBoost = { Corrupted = 5 }, tagBoost = { demon = 2 },
		color = Color3.fromRGB(220, 20, 30), blurb = "Corrupted Waifus boosted. Demons rise.",
	},
	{
		id = "HuecoVoid", name = "Hueco Void", weight = 0.45, duration = { 120, 150 }, mutationBoost = { Void = 8 }, major = true,
		tagBoost = { void = 2 },
		color = Color3.fromRGB(150, 50, 255), blurb = "Void mutations massively boosted.",
	},
	{
		id = "Mystery", name = "???", weight = 0.05, duration = { 90, 120 }, mutationBoost = { Mystery = 10 }, major = true,
		rarityBoost = { Mystery = 3 },
		color = Color3.fromRGB(255, 255, 255), blurb = "???",
	},
}

local byId: { [string]: Weather } = {}
for _, w in list do
	byId[w.id] = w
end

return {
	list = list,
	byId = byId,
	-- Seconds of full day/night cycle, and the in-game hours that count as night.
	DAY_LENGTH = 720,
	-- Oni Coast's Demon Tide: every PERIOD seconds, active for the first LENGTH seconds.
	DEMON_TIDE_PERIOD = 1800,
	DEMON_TIDE_LENGTH = 600,
}
