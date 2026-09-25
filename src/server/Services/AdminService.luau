--!strict
-- Test commands for Studio (or the place owner in live servers), typed in chat:
--   /weather HuecoVoid   /yen 100000   /serverluck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Weather = require(ReplicatedStorage.Shared.Config.Weather)
local EnvironmentService = require(script.Parent.EnvironmentService)
local InventoryService = require(script.Parent.InventoryService)

local AdminService = {}

local function isAdmin(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local commands: { [string]: (Player, { string }) -> () } = {
	["/weather"] = function(_, args)
		for _, w in Weather.list do
			if args[2] and string.lower(w.id) == string.lower(args[2]) then
				EnvironmentService.force(w.id)
			end
		end
	end,
	["/yen"] = function(player, args)
		local amount = tonumber(args[2])
		if amount then
			InventoryService.addYen(player, amount)
		end
	end,
	["/serverluck"] = function()
		ReplicatedStorage:SetAttribute("ServerLuckEnds", workspace:GetServerTimeNow() + 300)
	end,
}

function AdminService.start()
	for alias, run in commands do
		local command = Instance.new("TextChatCommand")
		command.Name = "Admin" .. alias:sub(2)
		command.PrimaryAlias = alias
		command.Triggered:Connect(function(source: TextSource, message: string)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player and isAdmin(player) then
				run(player, string.split(message, " "))
			end
		end)
		command.Parent = TextChatService
	end
end

return AdminService
