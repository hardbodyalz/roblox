--!strict
-- Permanent milestones, plus the hidden unlock for the Secret Rod.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Achievements = require(Shared.Config.Achievements)
local Characters = require(Shared.Config.Characters)
local Islands = require(Shared.Config.Islands)
local Collection = require(Shared.Collection)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)

local AchievementService = {}

local notify = Net.event("Notify")

local function hasMutation(collection: { [string]: { [string]: boolean } }, mutation: string): boolean
	for _, mutations in collection do
		if mutations[mutation] then
			return true
		end
	end
	return false
end

local function mutatedCount(collection: { [string]: { [string]: boolean } }): number
	local n = 0
	for _, mutations in collection do
		for mutation in mutations do
			if mutation ~= "Normal" then
				n += 1
			end
		end
	end
	return n
end

local function anyIslandComplete(collection: { [string]: { [string]: boolean } }): boolean
	for _, island in Islands.list do
		if Collection.islandComplete(collection, island.id) then
			return true
		end
	end
	return false
end

local checks: { [string]: (DataService.Profile) -> boolean } = {
	first_catch = function(d)
		return d.catches >= 1
	end,
	catches_100 = function(d)
		return d.catches >= 100
	end,
	catches_1000 = function(d)
		return d.catches >= 1000
	end,
	mutation_hunter = function(d)
		return mutatedCount(d.collection) >= 10
	end,
	ethereal_fisher = function(d)
		return hasMutation(d.collection, "Ethereal")
	end,
	celestial_fisher = function(d)
		return hasMutation(d.collection, "Celestial")
	end,
	void_walker = function(d)
		return hasMutation(d.collection, "Void")
	end,
	impossible = function(d)
		return hasMutation(d.collection, "Mystery")
	end,
	collector = function(d)
		return anyIslandComplete(d.collection)
	end,
	millionaire = function(d)
		return d.totalYen >= 1000000
	end,
}

-- The Secret Rod: discover every Corrupted Waifu. Nothing in the game says so.
local function secretRodEarned(d: DataService.Profile): boolean
	for _, character in Characters.list do
		if character.rarity == "Corrupted" and d.collection[character.id] == nil then
			return false
		end
	end
	return true
end

function AchievementService.check(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local changed = false
	for _, achievement in Achievements.list do
		if not data.achievements[achievement.id] and checks[achievement.id](data) then
			data.achievements[achievement.id] = true
			changed = true
			notify:FireClient(player, {
				kind = "achievement",
				title = "ACHIEVEMENT: " .. achievement.name,
				text = achievement.desc,
			})
		end
	end
	if changed then
		DataService.push(player, "achievements")
	end

	if not data.rods.secret_rod and secretRodEarned(data) then
		data.rods.secret_rod = true
		DataService.push(player, "rods")
		notify:FireClient(player, {
			kind = "secret",
			title = "???",
			text = "Something new is in your tackle box.",
		})
	end
end

return AchievementService
