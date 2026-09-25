--!strict
-- Everyone else's fishing, drawn locally from the server's FishingFx broadcasts: their bobbers
-- and lines, their bites, and the Waifus they pull out of the water.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Characters = require(ReplicatedStorage.Shared.Config.Characters)
local Net = require(ReplicatedStorage.Shared.Net)

local LocalCharacter = require(script.Parent.Parent.LocalCharacter)
local Emerge = require(script.Parent.Parent.Visuals.Emerge)
local Bobber = require(script.Parent.Bobber)

local Others = {}

local VIEW_DISTANCE = 300
local LINGER_SECONDS = 5

local player = Players.LocalPlayer
local bobbers: { [number]: Bobber.Bobber } = {}

local function inView(position: any): boolean
	local camera = workspace.CurrentCamera
	return typeof(position) == "Vector3" and camera ~= nil and (camera.CFrame.Position - position).Magnitude < VIEW_DISTANCE
end

local function take(userId: number): Bobber.Bobber?
	local b = bobbers[userId]
	bobbers[userId] = nil
	return b
end

local function onFx(info: any)
	if type(info) ~= "table" or info.userId == player.UserId then
		return
	end
	local userId = info.userId
	local angler = Players:GetPlayerByUserId(userId)
	if info.kind == "cast" then
		local old = take(userId)
		if old then
			old:destroy()
		end
		if angler and inView(info.target) then
			bobbers[userId] = Bobber.new(LocalCharacter.rodTip(angler), info.target)
		end
	elseif info.kind == "bite" then
		local b = bobbers[userId]
		if b then
			b:bite()
		end
	elseif info.kind == "catch" then
		local b = take(userId)
		if b then
			b:destroy()
		end
		if inView(info.target) and Characters.byId[info.c] then
			local character = angler and angler.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local handle = Emerge.surface(info, info.target, root)
			task.wait(LINGER_SECONDS)
			Emerge.dismiss(handle)
		end
	elseif info.kind == "clear" then
		local b = take(userId)
		if b then
			b:reelIn()
		end
	end
end

function Others.start()
	Net.event("FishingFx").OnClientEvent:Connect(function(info)
		task.spawn(onFx, info)
	end)
	Players.PlayerRemoving:Connect(function(leaving)
		local b = take(leaving.UserId)
		if b then
			b:destroy()
		end
	end)
end

return Others
