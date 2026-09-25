--!strict
-- Player profiles: load, reconcile, autosave, session lock, and replication to the owning client.
--
-- Clients get one "full" snapshot on join, then small patches:
--   ("patch", { key = value, ... })          top-level fields
--   ("inv", { add = { [uid] = item }, remove = { uid, ... } })
--   ("collection", { c = id, m = mutation })

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Balance = require(Shared.Config.Balance)

export type Item = {
	c: string, -- character id
	m: string, -- mutation id
	w: number, -- kg
	v: number, -- value (before Yen multipliers)
	l: boolean, -- locked
	i: string?, -- island whose waters she came from (older saves only have s)
	s: string?, -- hotspot id, if cast into one
	x: string, -- weather when caught
	t: number, -- os.time()
	f: boolean?, -- Beginner's Fortune bonus applied
}

export type Profile = {
	version: number,
	yen: number,
	totalYen: number,
	catches: number,
	rods: { [string]: boolean },
	rod: string,
	boats: { [string]: boolean },
	boat: string,
	bait: { [string]: number },
	baitEquipped: string,
	storageTier: number,
	inventory: { [string]: Item },
	nextUid: number,
	collection: { [string]: { [string]: boolean } },
	achievements: { [string]: boolean },
	tutorial: number,
	boosts: { [string]: number }, -- boost name -> os.time() it ends
	collectorCount: number,
	collectorEnds: number,
	best: { kg: number, value: number },
	island: string,
	receipts: { [string]: boolean },
}

local STORE_NAME = "WaifuFishing_v1"
local AUTOSAVE_SECONDS = 120
local LOCK_EXPIRY = 30 * 60

local function defaults(): Profile
	return {
		version = 1,
		yen = Balance.STARTING_YEN,
		totalYen = 0,
		catches = 0,
		rods = { old_rod = true },
		rod = "old_rod",
		boats = { old_minnow = true },
		boat = "old_minnow",
		bait = {},
		baitEquipped = "normal",
		storageTier = 1,
		inventory = {},
		nextUid = 1,
		collection = {},
		achievements = {},
		tutorial = 0,
		boosts = {},
		collectorCount = 0,
		collectorEnds = 0,
		best = { kg = 0, value = 0 },
		island = "sakura_shore",
		receipts = {},
	}
end

local function reconcile(data: any, template: any)
	for key, value in template do
		if data[key] == nil then
			data[key] = if type(value) == "table" then table.clone(value) else value
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil then
			reconcile(data[key], value)
		end
	end
end

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStores unavailable, progress will not save:", result)
	end
end

local DataService = {}

local profiles: { [Player]: Profile } = {}
local loadedCallbacks: { (Player, Profile) -> () } = {}
local syncEvent = Net.event("Sync")
-- Extra fields the client sees that aren't stored (gamepass ownership etc.)
local extrasProvider: ((Player) -> { [string]: any })? = nil

local function key(player: Player): string
	return "player_" .. player.UserId
end

local function load(player: Player): Profile?
	if not store then
		return defaults()
	end
	local jobId = if RunService:IsStudio() then "studio" else game.JobId
	for attempt = 1, 5 do
		local ok, result = pcall(function()
			return (store :: DataStore):UpdateAsync(key(player), function(old)
				old = old or { data = defaults() }
				local lock = old.lock
				if lock and lock.job ~= jobId and os.time() - lock.time < LOCK_EXPIRY and attempt < 5 then
					return nil -- another server still owns it; retry
				end
				old.lock = { job = jobId, time = os.time() }
				return old
			end)
		end)
		if ok and result and result.lock and result.lock.job == jobId then
			local data = result.data
			reconcile(data, defaults())
			return data
		end
		if not ok then
			warn("[DataService] load failed:", result)
			if RunService:IsStudio() then
				-- Usually "Studio access to API services" is off: play unsaved rather than wait.
				warn("[DataService] Studio: continuing with an unsaved profile. Enable API access in Game Settings to test saving.")
				store = nil
				return defaults()
			end
		end
		task.wait(attempt * 2)
		if not player.Parent then
			return nil
		end
	end
	return nil
end

local function save(player: Player, release: boolean)
	local data = profiles[player]
	if not data or not store then
		return
	end
	local jobId = if RunService:IsStudio() then "studio" else game.JobId
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(key(player), function(old)
			old = old or {}
			if old.lock and old.lock.job ~= jobId then
				return nil -- lost the session; don't clobber the newer one
			end
			old.data = data
			old.lock = if release then nil else { job = jobId, time = os.time() }
			return old
		end)
	end)
	if not ok then
		warn("[DataService] save failed for", player.Name, err)
	end
end

function DataService.get(player: Player): Profile?
	return profiles[player]
end

function DataService.onLoaded(callback: (Player, Profile) -> ())
	table.insert(loadedCallbacks, callback)
	for player, profile in profiles do
		task.spawn(callback, player, profile)
	end
end

function DataService.setExtrasProvider(fn: (Player) -> { [string]: any })
	extrasProvider = fn
end

function DataService.syncFull(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	local snapshot = table.clone(data) :: any
	if extrasProvider then
		for k, v in extrasProvider(player) do
			snapshot[k] = v
		end
	end
	syncEvent:FireClient(player, "full", snapshot)
end

function DataService.patch(player: Player, fields: { [string]: any })
	syncEvent:FireClient(player, "patch", fields)
end

-- Convenience: push the current value of these top-level keys.
function DataService.push(player: Player, ...: string)
	local data = profiles[player] :: any
	if not data then
		return
	end
	local fields = {}
	for _, k in { ... } do
		fields[k] = data[k]
	end
	syncEvent:FireClient(player, "patch", fields)
end

function DataService.addItem(player: Player, item: Item): string
	local data = profiles[player] :: Profile
	local uid = tostring(data.nextUid)
	data.nextUid += 1
	data.inventory[uid] = item
	syncEvent:FireClient(player, "inv", { add = { [uid] = item } })
	return uid
end

function DataService.removeItems(player: Player, uids: { string })
	local data = profiles[player] :: Profile
	for _, uid in uids do
		data.inventory[uid] = nil
	end
	syncEvent:FireClient(player, "inv", { remove = uids })
end

function DataService.updateItem(player: Player, uid: string)
	local data = profiles[player] :: Profile
	syncEvent:FireClient(player, "inv", { add = { [uid] = data.inventory[uid] } })
end

function DataService.discover(player: Player, characterId: string, mutationId: string): (boolean, boolean)
	local data = profiles[player] :: Profile
	local entry = data.collection[characterId]
	local newCharacter = entry == nil
	if not entry then
		entry = {}
		data.collection[characterId] = entry
	end
	local newMutation = not entry[mutationId]
	if newMutation then
		entry[mutationId] = true
		syncEvent:FireClient(player, "collection", { c = characterId, m = mutationId })
	end
	return newCharacter, newMutation
end

function DataService.inventoryCount(player: Player): number
	local data = profiles[player]
	local n = 0
	if data then
		for _ in data.inventory do
			n += 1
		end
	end
	return n
end

local function onPlayerAdded(player: Player)
	local data = load(player)
	if not player.Parent then
		return
	end
	if not data then
		player:Kick("Couldn't load your data. Please rejoin in a moment.")
		return
	end
	profiles[player] = data
	for _, callback in loadedCallbacks do
		task.spawn(callback, player, data)
	end
	DataService.syncFull(player)
end

function DataService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		if profiles[player] then
			save(player, true)
			profiles[player] = nil
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in profiles do
				task.spawn(save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				save(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
