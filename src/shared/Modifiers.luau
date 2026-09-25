--!strict
-- Folds everything that affects a cast (rod, boat, bait, where the bobber landed, weather, events,
-- passives, passes, boosts) into one Mods table. Shared so the client can show the same Luck number
-- the server uses.

local Config = script.Parent.Config
local Equipment = require(Config.Equipment)
local Islands = require(Config.Islands)
local Weather = require(Config.Weather)
local Monetization = require(Config.Monetization)
local Balance = require(Config.Balance)

export type Env = {
	weather: string,
	isNight: boolean,
	moonPhase: string,
	demonTide: boolean,
	serverLuck: boolean,
}

export type Loadout = {
	rod: string,
	boat: string,
	bait: string,
}

-- Where (and how well) the line went in.
export type Cast = {
	island: string?,
	spot: string?, -- hotspot the bobber landed in
	deep: boolean?, -- open water far from shore
	perfect: boolean?, -- Perfect Cast
}

export type Perks = {
	doubleLuck: boolean,
	doubleMutation: boolean,
	fastReel: boolean,
	luckBoost: boolean,
	mutationBoost: boolean,
	collectorBoost: boolean,
}

export type Mods = {
	luck: number, -- final Luck after multipliers
	baseLuck: number,
	luckMult: number,
	mutationMult: number, -- applies to every non-Normal mutation
	mutationBoost: { [string]: number },
	tagBoost: { [string]: number },
	rarityBoost: { [string]: number },
	biteSpeed: number, -- bite delay is divided by this
	control: number,
	resilience: number,
	maxKg: number,
	reelMult: number,
	secretMult: number, -- weight multiplier for the world-wide secret table
	isNight: boolean,
	moonPhase: string,
}

local Modifiers = {}

local function mul(map: { [string]: number }, key: string, factor: number)
	map[key] = (map[key] or 1) * factor
end

local function mulAll(map: { [string]: number }, source: { [string]: number }?)
	if source then
		for key, factor in source do
			mul(map, key, factor)
		end
	end
end

-- Perks from a profile-shaped table. The server passes live gamepass ownership; the client its
-- replicated copy, so both agree.
function Modifiers.perksFrom(passes: { [string]: boolean }, boosts: { [string]: number }, collectorEnds: number, now: number): Perks
	return {
		doubleLuck = passes.DoubleLuck == true,
		doubleMutation = passes.DoubleMutation == true,
		fastReel = passes.FastReel == true,
		luckBoost = (boosts.Luck or 0) > now,
		mutationBoost = (boosts.Mutation or 0) > now,
		collectorBoost = collectorEnds > now,
	}
end

function Modifiers.compute(loadout: Loadout, cast: Cast, env: Env, perks: Perks): Mods
	local rod = Equipment.rodsById[loadout.rod] or Equipment.rodsById.old_rod
	local boat = Equipment.boatsById[loadout.boat] or Equipment.boatsById.old_minnow
	local bait = Equipment.baitsById[loadout.bait] or Equipment.baitsById.normal
	local spot = if cast.spot then Islands.spotsById[cast.spot] else nil
	local island = if cast.island then Islands.byId[cast.island] else nil
	local weather = Weather.byId[env.weather] or Weather.byId.Sunny

	local isNight = env.isNight or (island ~= nil and island.permanentNight == true)
	local islandId = if island then island.id else ""

	local mods: Mods = {
		luck = 0,
		baseLuck = rod.luck + boat.luck + bait.luck + (if spot then spot.luck or 0 else 0),
		luckMult = 1,
		mutationMult = if spot then spot.mutationMult or 1 else 1,
		mutationBoost = {},
		tagBoost = {},
		rarityBoost = {},
		biteSpeed = 1 + rod.speed / 100,
		control = rod.control,
		resilience = rod.resilience,
		maxKg = rod.maxKg,
		reelMult = 1,
		secretMult = 1,
		isNight = isNight,
		moonPhase = env.moonPhase,
	}

	-- How the line went in
	if cast.deep then
		mods.baseLuck += Balance.DEEP_WATER_LUCK
		mods.secretMult *= Balance.DEEP_WATER_SECRET_MULT
	end
	if cast.perfect then
		mods.luckMult *= Balance.PERFECT_LUCK_MULT
		mods.biteSpeed += Balance.PERFECT_BITE_SPEED
	end

	-- Spot, bait, weather
	if spot then
		mulAll(mods.tagBoost, spot.tagBoost)
	end
	mulAll(mods.tagBoost, bait.tagBoost)
	mulAll(mods.mutationBoost, bait.mutationBoost)
	mulAll(mods.mutationBoost, weather.mutationBoost)
	mulAll(mods.rarityBoost, weather.rarityBoost)
	mulAll(mods.tagBoost, weather.tagBoost)

	-- Island events
	if env.demonTide and islandId == "oni_coast" then
		mul(mods.tagBoost, "demon", 2)
		mods.mutationMult *= 1.5
	end

	-- Rod passives
	local rp = rod.passive.id
	if rp == "sakura_blessing" and islandId == "sakura_shore" then
		mods.mutationMult *= 1.25
	elseif rp == "tidecaller" then
		mods.biteSpeed += 0.15
	elseif rp == "shrine_ward" then
		mul(mods.tagBoost, "shrine", 1.75)
	elseif rp == "foxfire" then
		mul(mods.tagBoost, "fox", 2)
	elseif rp == "infernal_attraction" then
		mul(mods.tagBoost, "demon", 1.75)
	elseif rp == "lunar_blessing" then
		if isNight then
			mods.luckMult *= 1.15
		end
		if env.moonPhase == "Full" then
			mods.mutationMult *= 1.25
		end
	elseif rp == "divine_favor" then
		mul(mods.rarityBoost, "Divine", 1.5)
		mul(mods.rarityBoost, "Eternal", 1.5)
	elseif rp == "rift_fishing" then
		if env.weather == "HuecoVoid" then
			mul(mods.mutationBoost, "Void", 2)
			mul(mods.tagBoost, "void", 2)
			mods.luckMult *= 1.25
		end
	elseif rp == "unknown_passive" then
		mods.mutationMult *= 1.5
		mods.luckMult *= 1.1
	end

	-- Boat passives that affect fishing (travel ones live in TravelService)
	local bp = boat.passive.id
	if bp == "infernal_wake" then
		mul(mods.tagBoost, "demon", 1.5)
	elseif bp == "heavens_favor" then
		mods.luckMult *= 1.1
	elseif bp == "rift_drive" then
		mul(mods.mutationBoost, "Void", 1.5)
	end

	-- Passes and boosts
	if perks.doubleLuck then
		mods.luckMult *= 2
	end
	if perks.luckBoost then
		mods.luckMult *= 2
	end
	if perks.collectorBoost then
		mods.luckMult *= 1.5
	end
	if perks.doubleMutation then
		mods.mutationMult *= 2
	end
	if perks.mutationBoost then
		mods.mutationMult *= 2
	end
	if perks.fastReel then
		mods.reelMult *= Monetization.FAST_REEL_MULT
	end

	mods.luck = mods.baseLuck * mods.luckMult
	if env.serverLuck then
		mods.luck *= Monetization.SERVER_LUCK_MULT
	end
	return mods
end

return Modifiers
