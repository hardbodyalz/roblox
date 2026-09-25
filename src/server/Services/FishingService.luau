--!strict
-- Cast -> bite -> shake + reel -> catch. All RNG happens here; the client only ever learns what it
-- needs to play the minigame until the catch is landed.
--
-- Casting works in any water: the client sends where its bobber landed, and the server checks it
-- is water, within the rod's range, and in waters the player's boat can reach.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Equipment = require(Config.Equipment)
local Balance = require(Config.Balance)
local Modifiers = require(Shared.Modifiers)
local Roll = require(Shared.Roll)
local Clock = require(Shared.Clock)
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local Water = require(Shared.Water)
local Zones = require(Shared.Zones)
local Travel = require(Shared.Travel)

local DataService = require(script.Parent.DataService)
local PerkService = require(script.Parent.PerkService)
local AchievementService = require(script.Parent.AchievementService)
local StorageRules = require(script.Parent.StorageRules)
local RodService = require(script.Parent.RodService)
local Leaderstats = require(script.Parent.Leaderstats)

type Session = {
	token: number,
	state: string, -- "waiting" | "reeling"
	target: Vector3,
	islandId: string,
	spotId: string?,
	characterId: string?,
	mutationId: string?,
	kg: number?,
	weather: string?,
	reelStart: number?,
	minSeconds: number?,
}

local FishingService = {}

local rng = Random.new()
local sessions: { [Player]: Session } = {}
local nextToken = 0

local biteEvent = Net.event("Bite")
local fxEvent = Net.event("FishingFx")
local announceEvent = Net.event("Announce")
local notifyEvent = Net.event("Notify")

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function isFinite(v: Vector3): boolean
	for _, n in { v.X, v.Y, v.Z } do
		if n ~= n or math.abs(n) == math.huge then
			return false
		end
	end
	return true
end

local function minigameParams(characterId: string, kg: number, mods: Modifiers.Mods)
	local character = Characters.byId[characterId]
	local rarity = Rarities.byId[character.rarity]
	local base = Balance.Minigame[rarity.difficulty]
	local overweight = kg > mods.maxKg
	local gain = base.gain * mods.reelMult
	if overweight then
		gain *= math.max(mods.maxKg / kg, Balance.OVERWEIGHT_FLOOR)
	end
	local loss = base.loss * math.max(0.2, 1 - mods.resilience / Balance.RESILIENCE_DIV)
	return {
		fishSpeed = base.fishSpeed,
		erratic = base.erratic,
		gain = gain,
		loss = loss,
		barWidth = math.clamp(Balance.BAR_BASE + mods.control / Balance.BAR_CONTROL_DIV, 0.1, 0.5),
		start = Balance.MINIGAME_START_PROGRESS,
		glitch = base.glitch == true,
		overweight = overweight,
		shakes = math.max(1, Balance.Shakes[rarity.difficulty] - math.floor(mods.control / Balance.SHAKE_CONTROL_STEP)),
		-- Flavour only: how hard it's fighting. Deliberately vague about the actual rarity.
		intensity = if rarity.order >= 6 then 3 elseif rarity.order >= 4 then 2 else 1,
	}
end

local function consumeBait(player: Player, data: DataService.Profile)
	local baitId = data.baitEquipped
	if baitId == "normal" then
		return
	end
	local count = data.bait[baitId] or 0
	if count <= 1 then
		data.bait[baitId] = nil
		data.baitEquipped = "normal"
		notifyEvent:FireClient(player, { title = "Out of bait", text = "Switched back to Normal Bait." })
	else
		data.bait[baitId] = count - 1
	end
	DataService.push(player, "bait", "baitEquipped")
end

local function announceCatch(player: Player, item: DataService.Item)
	local character = Characters.byId[item.c]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[item.m]
	local bigRarity = rarity.order >= Balance.ANNOUNCE_RARITY_ORDER
	local bigMutation = mutation.order >= Balance.ANNOUNCE_MUTATION_ORDER
	if not bigRarity and not bigMutation then
		return
	end

	local title, text, color
	local who = player.DisplayName
	if bigMutation and rarity.order >= 6 then
		title = string.upper(mutation.name .. " " .. rarity.name) .. " WAIFU"
		text = string.format("%s has fished up a %s %s %s!", who, mutation.name, rarity.name, character.name)
		color = mutation.color
	elseif bigMutation then
		title = string.upper(mutation.name) .. " MUTATION"
		text = string.format("%s has fished up a %s %s!", who, mutation.name, character.name)
		color = mutation.color
	else
		title = rarity.announce or "RARE WAIFU CAUGHT"
		local prefix = if item.m ~= "Normal" then mutation.name .. " " else ""
		text = string.format("%s has caught %s%s!", who, prefix, character.name)
		color = rarity.color
	end
	text ..= string.format(" (%s, %s)", Format.kg(item.w), Format.yen(item.v))
	announceEvent:FireAllClients({
		title = title,
		text = text,
		color = color,
		big = rarity.order >= 6 or mutation.order >= 7,
		userId = player.UserId,
	})
end

local function land(player: Player, data: DataService.Profile, session: Session)
	local characterId = session.characterId :: string
	local mutationId = session.mutationId :: string
	local kg = session.kg :: number
	local character = Characters.byId[characterId]
	local rarity = Rarities.byId[character.rarity]

	local value = Roll.value(characterId, mutationId, kg)
	local fortune = false
	local rod = Equipment.rodsById[data.rod]
	if rod and rod.passive.id == "beginners_fortune" and rarity.order <= 2 and rng:NextNumber() < Balance.BEGINNERS_FORTUNE_CHANCE then
		value = math.floor(value * Balance.BEGINNERS_FORTUNE_BONUS)
		fortune = true
	end

	local item: DataService.Item = {
		c = characterId,
		m = mutationId,
		w = kg,
		v = value,
		l = false,
		i = session.islandId,
		s = session.spotId,
		x = session.weather or "Sunny",
		t = os.time(),
		f = if fortune then true else nil,
	}

	local uid = DataService.addItem(player, item)
	local newCharacter, newMutation = DataService.discover(player, characterId, mutationId)

	data.catches += 1
	data.best.kg = math.max(data.best.kg, kg)
	data.best.value = math.max(data.best.value, value)

	-- Waifu Carrier: every 100 catches, 5 minutes of +50% Luck.
	local boat = Equipment.boatsById[data.boat]
	if boat and boat.passive.id == "collector" then
		data.collectorCount += 1
		if data.collectorCount >= 100 then
			data.collectorCount = 0
			data.collectorEnds = os.time() + 300
			notifyEvent:FireClient(player, { title = "Collector", text = "+50% Luck for 5 minutes!" })
		end
	end
	DataService.push(player, "catches", "best", "collectorCount", "collectorEnds")
	Leaderstats.set(player, "Caught", data.catches)

	-- Everyone nearby sees her surface.
	fxEvent:FireAllClients({ kind = "catch", userId = player.UserId, target = session.target, c = characterId, m = mutationId, w = kg })
	announceCatch(player, item)
	AchievementService.check(player)

	return {
		uid = uid,
		item = item,
		newCharacter = newCharacter,
		newMutation = newMutation,
		storageFull = StorageRules.isFull(player),
	}
end

local function cancel(player: Player)
	if sessions[player] then
		sessions[player] = nil
		fxEvent:FireAllClients({ kind = "clear", userId = player.UserId })
	end
end

function FishingService.cancel(player: Player)
	cancel(player)
end

function FishingService.isBusy(player: Player): boolean
	return sessions[player] ~= nil
end

-- Request handlers --------------------------------------------------------------

local handlers: { [string]: (Player, any) -> (boolean, any?) } = {}

function handlers.Cast(player: Player, payload: any)
	local data = DataService.get(player)
	if not data then
		return false, "Loading..."
	end
	local target = if type(payload) == "table" then payload.target else nil
	if typeof(target) ~= "Vector3" or not isFinite(target) then
		return false, "Bad cast."
	end
	local root = rootOf(player)
	if not root or not RodService.holding(player) then
		return false, "Equip your rod first."
	end
	local rod = Equipment.rodsById[data.rod] or Equipment.rodsById.old_rod
	local offset = target - root.Position
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > rod.castRange + Balance.CAST_RANGE_MARGIN or math.abs(offset.Y) > 60 then
		return false, "That's out of your rod's range."
	end
	if not Water.isWater(target) then
		return false, "You can only fish in water!"
	end
	local zone = Zones.at(target)
	local island = zone.island
	if not island then
		return false, "Nothing bites here."
	end
	if not Travel.canReach(data.boat, island.id) then
		return false, string.format("These waters need a boat with %d+ Speed.", island.minBoatSpeed)
	end
	if StorageRules.isFull(player) then
		return false, "Storage full! Sell some catches to keep fishing."
	end

	-- A new cast always replaces the old one, so a lost reply can never leave you stuck.
	cancel(player)
	nextToken += 1
	local session: Session = {
		token = nextToken,
		state = "waiting",
		target = target,
		islandId = island.id,
		spotId = if zone.spot then zone.spot.id else nil,
	}
	sessions[player] = session

	-- Luck and the table are locked in at cast time, so the bait you cast with is the bait that counts.
	-- The Perfect Cast flag is trusted from the client; its bonus is deliberately small.
	local perks = PerkService.perks(player)
	local loadout = { rod = data.rod, boat = data.boat, bait = data.baitEquipped }
	local mods = Modifiers.compute(loadout, Zones.cast(zone, payload.perfect == true), Clock.env(), perks)
	local weather = Clock.weather()
	consumeBait(player, data)
	fxEvent:FireAllClients({ kind = "cast", userId = player.UserId, target = target })

	local delay = rng:NextNumber(Balance.BITE_DELAY[1], Balance.BITE_DELAY[2]) / mods.biteSpeed
	task.delay(delay, function()
		if sessions[player] ~= session then
			return
		end
		local characterId = Roll.pick(Roll.characterWeights(island.id, weather, mods), rng)
		local mutationId = Roll.pick(Roll.mutationWeights(characterId, mods), rng)
		local kg = Roll.weight(characterId, rng)
		local params = minigameParams(characterId, kg, mods)

		session.characterId = characterId
		session.mutationId = mutationId
		session.kg = kg
		session.weather = weather
		session.state = "reeling"
		session.reelStart = os.clock()
		session.minSeconds = (100 - params.start) / params.gain * Balance.MIN_REEL_FRACTION
		biteEvent:FireClient(player, session.token, params)
		fxEvent:FireAllClients({ kind = "bite", userId = player.UserId })
	end)

	return true, { delay = delay }
end

-- Returns the landed catch, or { lost = true, rarity } if she got away.
function handlers.Reel(player: Player, payload: any)
	local data = DataService.get(player)
	local session = sessions[player]
	if not data or not session or type(payload) ~= "table" or payload.token ~= session.token then
		return false, "No bite."
	end
	if session.state ~= "reeling" then
		return false, "Nothing on the line yet."
	end
	sessions[player] = nil

	local elapsed = os.clock() - (session.reelStart :: number)
	local success = payload.success == true
	if success and elapsed < (session.minSeconds :: number) then
		warn(string.format("[FishingService] %s reeled too fast (%.2fs < %.2fs)", player.Name, elapsed, session.minSeconds :: number))
		success = false
	end
	if elapsed > Balance.MAX_REEL_SECONDS then
		success = false
	end

	if success then
		return true, land(player, data, session)
	end
	fxEvent:FireAllClients({ kind = "clear", userId = player.UserId })
	local character = Characters.byId[session.characterId :: string]
	return true, { lost = true, rarity = character.rarity }
end

function handlers.CancelCast(player: Player)
	cancel(player)
	return true
end

FishingService.handlers = handlers

function FishingService.start()
	Players.PlayerRemoving:Connect(cancel)
end

return FishingService
