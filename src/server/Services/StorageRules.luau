--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Storage = require(ReplicatedStorage.Shared.Storage)
local DataService = require(script.Parent.DataService)
local PerkService = require(script.Parent.PerkService)

local StorageRules = {}

function StorageRules.capacity(player: Player): number
	local data = DataService.get(player)
	if not data then
		return 0
	end
	return Storage.capacity(data.storageTier, data.boat, PerkService.infiniteStorage(player))
end

function StorageRules.isFull(player: Player): boolean
	return DataService.inventoryCount(player) >= StorageRules.capacity(player)
end

return StorageRules
