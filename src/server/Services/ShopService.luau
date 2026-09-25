--!strict
-- Rods, boats, bait and storage upgrades.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Equipment = require(Shared.Config.Equipment)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local FishingService = require(script.Parent.FishingService)
local RodService = require(script.Parent.RodService)

local ShopService = {}

local notify = Net.event("Notify")

local handlers: { [string]: (Player, any) -> (boolean, any?) } = {}

local function idFrom(payload: any): string?
	return if type(payload) == "table" and type(payload.id) == "string" then payload.id else nil
end

function handlers.BuyRod(player: Player, payload: any)
	local data = DataService.get(player)
	local id = idFrom(payload)
	local rod = id and Equipment.rodsById[id]
	if not data or not rod or rod.price == nil then
		return false, "Not for sale."
	end
	if data.rods[rod.id] then
		return false, "Already owned."
	end
	if FishingService.isBusy(player) then
		return false, "Finish fishing first."
	end
	if not InventoryService.spend(player, rod.price) then
		return false, "Not enough Yen."
	end
	data.rods[rod.id] = true
	data.rod = rod.id
	DataService.push(player, "rods", "rod")
	RodService.refresh(player)
	notify:FireClient(player, { title = "New rod!", text = rod.name .. " equipped." })
	return true
end

function handlers.EquipRod(player: Player, payload: any)
	local data = DataService.get(player)
	local id = idFrom(payload)
	if not data or not id or not data.rods[id] then
		return false, "You don't own that rod."
	end
	if FishingService.isBusy(player) then
		return false, "Finish fishing first."
	end
	data.rod = id
	DataService.push(player, "rod")
	RodService.refresh(player)
	return true
end

function handlers.BuyBoat(player: Player, payload: any)
	local data = DataService.get(player)
	local id = idFrom(payload)
	local boat = id and Equipment.boatsById[id]
	if not data or not boat or boat.price == nil then
		return false, "Not for sale."
	end
	if data.boats[boat.id] then
		return false, "Already owned."
	end
	if not InventoryService.spend(player, boat.price) then
		return false, "Not enough Yen."
	end
	data.boats[boat.id] = true
	data.boat = boat.id
	DataService.push(player, "boats", "boat")
	notify:FireClient(player, { title = "New boat!", text = boat.name .. " is waiting at the harbour." })
	return true
end

function handlers.EquipBoat(player: Player, payload: any)
	local data = DataService.get(player)
	local id = idFrom(payload)
	if not data or not id or not data.boats[id] then
		return false, "You don't own that boat."
	end
	data.boat = id
	DataService.push(player, "boat")
	return true
end

function handlers.BuyBait(player: Player, payload: any)
	local data = DataService.get(player)
	local id = idFrom(payload)
	local bait = id and Equipment.baitsById[id]
	if not data or not bait or bait.pack <= 0 then
		return false, "Not for sale."
	end
	if not InventoryService.spend(player, bait.price) then
		return false, "Not enough Yen."
	end
	data.bait[bait.id] = (data.bait[bait.id] or 0) + bait.pack
	DataService.push(player, "bait")
	return true
end

function handlers.EquipBait(player: Player, payload: any)
	local data = DataService.get(player)
	local id = idFrom(payload)
	if not data or not id or not Equipment.baitsById[id] then
		return false, "Unknown bait."
	end
	if id ~= "normal" and (data.bait[id] or 0) <= 0 then
		return false, "You don't have any."
	end
	data.baitEquipped = id
	DataService.push(player, "baitEquipped")
	return true
end

function handlers.BuyStorage(player: Player)
	local data = DataService.get(player)
	if not data then
		return false
	end
	local nextTier = Equipment.storage[data.storageTier + 1]
	if not nextTier then
		return false, "Storage is maxed."
	end
	if not InventoryService.spend(player, nextTier.price) then
		return false, "Not enough Yen."
	end
	data.storageTier += 1
	DataService.push(player, "storageTier")
	return true
end

ShopService.handlers = handlers

return ShopService
