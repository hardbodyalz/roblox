--!strict
-- The two independent RNG rolls (character, then mutation), plus weight and value.
-- Pure functions: no Instances touched, so they're easy to simulate and balance.

local Config = script.Parent.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Islands = require(Config.Islands)
local Balance = require(Config.Balance)
local Modifiers = require(script.Parent.Modifiers)

type Mods = Modifiers.Mods

export type Weighted = { id: string, w: number }

local Roll = {}

local function entryAvailable(entry: Islands.TableEntry, weather: string, moonPhase: string): boolean
	if entry.weather and not table.find(entry.weather, weather) then
		return false
	end
	if entry.moon and not table.find(entry.moon, moonPhase) then
		return false
	end
	return true
end

-- Encounter weights for one cast. Luck scales each tier by (1 + luck/100 * luckGain), so
-- higher Luck makes rarer tiers increasingly likely without flattening the whole table.
function Roll.characterWeights(islandId: string, weather: string, mods: Mods): { Weighted }
	local island = Islands.byId[islandId]
	local out: { Weighted } = {}
	local function add(entries: { Islands.TableEntry }, mult: number)
		for _, entry in entries do
			if entryAvailable(entry, weather, mods.moonPhase) then
				local character = Characters.byId[entry.id]
				local rarity = Rarities.byId[character.rarity]
				local w = entry.w * mult
				if entry.moonBoost then
					w *= entry.moonBoost[mods.moonPhase] or 1
				end
				w *= 1 + mods.luck / 100 * rarity.luckGain
				w *= mods.rarityBoost[rarity.id] or 1
				for _, tag in character.tags do
					w *= mods.tagBoost[tag] or 1
				end
				table.insert(out, { id = entry.id, w = w })
			end
		end
	end
	add(island.table, 1)
	add(Islands.globalTable, mods.secretMult)
	return out
end

function Roll.mutationWeights(characterId: string, mods: Mods): { Weighted }
	local character = Characters.byId[characterId]
	local bias = character.mutationBias
	local out: { Weighted } = {}
	for _, mutation in Mutations.list do
		local w = mutation.weight
		if mutation.id ~= "Normal" then
			w *= mods.mutationMult * (mods.mutationBoost[mutation.id] or 1)
			if bias then
				w *= bias[mutation.id] or 1
			end
		end
		table.insert(out, { id = mutation.id, w = w })
	end
	return out
end

function Roll.pick(weights: { Weighted }, rng: Random): string
	local total = 0
	for _, entry in weights do
		total += entry.w
	end
	local r = rng:NextNumber() * total
	for _, entry in weights do
		r -= entry.w
		if r <= 0 then
			return entry.id
		end
	end
	return weights[#weights].id
end

-- Probability of each id, for UI and simulations.
function Roll.odds(weights: { Weighted }): { [string]: number }
	local total = 0
	for _, entry in weights do
		total += entry.w
	end
	local out = {}
	for _, entry in weights do
		out[entry.id] = entry.w / total
	end
	return out
end

function Roll.weight(characterId: string, rng: Random): number
	local range = Characters.byId[characterId].kg
	local kg = range[1] + (range[2] - range[1]) * rng:NextNumber() ^ Balance.WEIGHT_SKEW
	return math.floor(kg * 10 + 0.5) / 10
end

function Roll.value(characterId: string, mutationId: string, kg: number): number
	local character = Characters.byId[characterId]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[mutationId]
	local mid = (character.kg[1] + character.kg[2]) / 2
	local weightFactor = (kg / mid) ^ Balance.WEIGHT_VALUE_EXP
	local value = rarity.baseValue * (character.valueMult or 1) * weightFactor * mutation.valueMult
	return math.max(1, math.floor(value + 0.5))
end

return Roll
