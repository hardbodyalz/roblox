--!strict
-- Keeps the equipped rod in the player's backpack as a Tool, rebuilt whenever it changes or
-- they respawn.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Shared.Config.Equipment)
local RodModel = require(script.Parent.Parent.World.RodModel)
local DataService = require(script.Parent.DataService)

local RodService = {}

local function rodTools(player: Player): { Tool }
	local out = {}
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Rod") ~= nil then
					table.insert(out, child)
				end
			end
		end
	end
	return out
end

-- The rod the player is holding right now, if it's their equipped one.
function RodService.holding(player: Player): Tool?
	local data = DataService.get(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	if data and tool and tool:GetAttribute("Rod") == data.rod then
		return tool
	end
	return nil
end

function RodService.refresh(player: Player)
	local data = DataService.get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	local wasHeld = false
	for _, tool in rodTools(player) do
		wasHeld = wasHeld or tool.Parent == player.Character
		tool:Destroy()
	end
	local rod = Equipment.rodsById[data.rod] or Equipment.rodsById.old_rod
	local tool = RodModel.build(rod)
	tool.Parent = if wasHeld and player.Character then player.Character else backpack
end

function RodService.start()
	DataService.onLoaded(function(player)
		player.CharacterAdded:Connect(function()
			-- The new Backpack is swapped in alongside the character; let it settle first.
			task.defer(function()
				player:WaitForChild("Backpack", 10)
				RodService.refresh(player)
			end)
		end)
		if player.Character then
			RodService.refresh(player)
		end
	end)
end

return RodService
