--!strict
-- Keep / Sell / Lock, Sell All, Sell Duplicates, and all Yen changes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Format = require(Shared.Format)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local PerkService = require(script.Parent.PerkService)
local AchievementService = require(script.Parent.AchievementService)

local InventoryService = {}

local notify = Net.event("Notify")

local function updateLeaderstats(player: Player, data: DataService.Profile)
	local leaderstats = player:FindFirstChild("leaderstats")
	local yen = leaderstats and leaderstats:FindFirstChild("Yen") :: IntValue?
	if yen then
		yen.Value = data.yen
	end
end

function InventoryService.addYen(player: Player, amount: number)
	local data = DataService.get(player)
	if not data then
		return
	end
	data.yen += amount
	if amount > 0 then
		data.totalYen += amount
	end
	DataService.push(player, "yen", "totalYen")
	updateLeaderstats(player, data)
end

function InventoryService.spend(player: Player, amount: number): boolean
	local data = DataService.get(player)
	if not data or data.yen < amount then
		return false
	end
	InventoryService.addYen(player, -amount)
	return true
end

-- Sells the given uids (skipping locked / missing ones). Returns Yen earned and count sold.
local function sell(player: Player, uids: { string }): (number, number)
	local data = DataService.get(player)
	if not data then
		return 0, 0
	end
	local mult = PerkService.yenMult(player)
	local total, sold = 0, {}
	for _, uid in uids do
		local item = data.inventory[uid]
		if item and not item.l then
			total += math.floor(item.v * mult + 0.5)
			table.insert(sold, uid)
		end
	end
	if #sold == 0 then
		return 0, 0
	end
	DataService.removeItems(player, sold)
	InventoryService.addYen(player, total)
	AchievementService.check(player)
	return total, #sold
end

local function soldMessage(player: Player, earned: number, count: number)
	if count > 0 then
		notify:FireClient(player, {
			kind = "sell",
			title = "Sold " .. count .. (if count == 1 then " Waifu" else " Waifus"),
			text = "+" .. Format.yen(earned),
		})
	end
end

local handlers: { [string]: (Player, any) -> (boolean, any?) } = {}

function handlers.Sell(player: Player, payload: any)
	if type(payload) ~= "table" or type(payload.uids) ~= "table" then
		return false, "Bad request."
	end
	local uids = {}
	for _, uid in payload.uids do
		if type(uid) == "string" then
			table.insert(uids, uid)
		end
	end
	local earned, count = sell(player, uids)
	soldMessage(player, earned, count)
	return count > 0, if count > 0 then earned else "Nothing to sell (locked?)."
end

function handlers.SellAll(player: Player)
	local data = DataService.get(player)
	if not data then
		return false
	end
	local uids = {}
	for uid, item in data.inventory do
		if not item.l then
			table.insert(uids, uid)
		end
	end
	local earned, count = sell(player, uids)
	soldMessage(player, earned, count)
	return true, earned
end

-- For every character + mutation combo keep the single best copy (or every locked copy) and sell the rest.
function handlers.SellDuplicates(player: Player)
	local data = DataService.get(player)
	if not data then
		return false
	end
	local groups: { [string]: { { uid: string, item: DataService.Item } } } = {}
	for uid, item in data.inventory do
		local key = item.c .. "|" .. item.m
		groups[key] = groups[key] or {}
		table.insert(groups[key], { uid = uid, item = item })
	end
	local uids = {}
	for _, group in groups do
		local hasLocked = false
		for _, entry in group do
			hasLocked = hasLocked or entry.item.l
		end
		table.sort(group, function(a, b)
			return a.item.v > b.item.v
		end)
		for i, entry in group do
			if not entry.item.l and (hasLocked or i > 1) then
				table.insert(uids, entry.uid)
			end
		end
	end
	local earned, count = sell(player, uids)
	soldMessage(player, earned, count)
	return true, earned
end

function handlers.ToggleLock(player: Player, payload: any)
	local data = DataService.get(player)
	local uid = if type(payload) == "table" and type(payload.uid) == "string" then payload.uid else nil
	local item = if data and uid then data.inventory[uid] else nil
	if not item or not uid then
		return false, "Not found."
	end
	if type(payload.locked) == "boolean" then
		item.l = payload.locked
	else
		item.l = not item.l
	end
	DataService.updateItem(player, uid)
	return true, item.l
end

InventoryService.handlers = handlers

return InventoryService
