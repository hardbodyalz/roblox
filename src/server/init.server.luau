--!strict
-- Server entry point: builds the world, starts services, routes client requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Weather = require(Shared.Config.Weather)
local Islands = require(Shared.Config.Islands)

local Services = script.Services
local DataService = require(Services.DataService)
local PerkService = require(Services.PerkService)
local EnvironmentService = require(Services.EnvironmentService)
local FishingService = require(Services.FishingService)
local InventoryService = require(Services.InventoryService)
local ShopService = require(Services.ShopService)
local TravelService = require(Services.TravelService)
local AchievementService = require(Services.AchievementService)
local Builder = require(script.World.Builder)

-- Limited-time event islands. Flip to false when Demon Academy ends: its Waifus stay tradeable
-- and in inventories, they just can't be fished any more.
ReplicatedStorage:SetAttribute("EventActive", true)

Builder.build()

-- Request routing --------------------------------------------------------------

local handlers: { [string]: (Player, any) -> (boolean, any) } = {}
local function register(from: { [string]: any })
	for action, fn in from do
		assert(handlers[action] == nil, "duplicate handler " .. action)
		handlers[action] = fn
	end
end
register(FishingService.handlers)
register(InventoryService.handlers)
register(ShopService.handlers)
register(TravelService.handlers)

handlers.Tutorial = function(player, payload)
	local data = DataService.get(player)
	local step = type(payload) == "table" and payload.step
	if data and type(step) == "number" and step > data.tutorial and step <= 10 then
		data.tutorial = math.floor(step)
		return true
	end
	return false
end

-- Simple per-player rate limit.
local budget: { [Player]: { tokens: number, last: number } } = {}
local function allow(player: Player): boolean
	local now = os.clock()
	local b = budget[player]
	if not b then
		b = { tokens = 20, last = now }
		budget[player] = b
	end
	b.tokens = math.min(20, b.tokens + (now - b.last) * 10)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

Net.func("Request").OnServerInvoke = function(player: Player, action: any, payload: any)
	if type(action) ~= "string" or not handlers[action] then
		return false, "Unknown action."
	end
	if not allow(player) then
		return false, "Slow down!"
	end
	local ok, success, result = pcall(handlers[action], player, payload)
	if not ok then
		warn("[Request]", action, "failed:", success)
		return false, "Something went wrong."
	end
	return success, result
end

-- Players ----------------------------------------------------------------------

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	return false
end

-- Test commands (Studio, or the place owner): /weather HuecoVoid, /yen 100000, /serverluck
local function runCommand(player: Player, message: string)
	if not isAdmin(player) then
		return
	end
	local args = string.split(message, " ")
	local command = string.lower(args[1] or "")
	if command == "/weather" and args[2] then
		for _, w in Weather.list do
			if string.lower(w.id) == string.lower(args[2]) then
				EnvironmentService.force(w.id)
			end
		end
	elseif command == "/yen" and tonumber(args[2]) then
		InventoryService.addYen(player, tonumber(args[2]) :: number)
	elseif command == "/serverluck" then
		ReplicatedStorage:SetAttribute("ServerLuckEnds", workspace:GetServerTimeNow() + 300)
	end
end

for _, alias in { "/weather", "/yen", "/serverluck" } do
	local command = Instance.new("TextChatCommand")
	command.Name = "Admin" .. alias:sub(2)
	command.PrimaryAlias = alias
	command.Triggered:Connect(function(source: TextSource, message: string)
		local player = Players:GetPlayerByUserId(source.UserId)
		if player then
			runCommand(player, message)
		end
	end)
	command.Parent = TextChatService
end

DataService.onLoaded(function(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local yen = Instance.new("IntValue")
	yen.Name = "Yen"
	yen.Value = data.yen
	yen.Parent = leaderstats
	local caught = Instance.new("IntValue")
	caught.Name = "Caught"
	caught.Value = data.catches
	caught.Parent = leaderstats
	leaderstats.Parent = player

	-- Respawn on the island you were last on (if you can still reach it).
	local function onCharacter(character: Model)
		local island = Islands.byId[data.island]
		if island and island.id ~= "sakura_shore" and not (island.event and not ReplicatedStorage:GetAttribute("EventActive")) then
			character:WaitForChild("HumanoidRootPart", 5)
			task.wait()
			TravelService.teleport(player, island.id)
		end
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end

	AchievementService.check(player)
end)

Players.PlayerRemoving:Connect(function(player)
	budget[player] = nil
end)

PerkService.start()
DataService.start()
EnvironmentService.start()
FishingService.start()
