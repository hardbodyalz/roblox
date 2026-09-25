--!strict
-- Small accessors for the local player's character, rod and whereabouts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Islands = require(ReplicatedStorage.Shared.Config.Islands)

local LocalCharacter = {}

local player = Players.LocalPlayer

function LocalCharacter.root(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function LocalCharacter.humanoid(): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

-- Island the player is standing on or next to.
function LocalCharacter.island(): string?
	local root = LocalCharacter.root()
	local island = root and Islands.islandAt(root.Position)
	return island and island.id
end

local function rodIn(container: Instance?): Tool?
	if not container then
		return nil
	end
	for _, child in container:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("Rod") ~= nil then
			return child
		end
	end
	return nil
end

-- The rod in hand, if any.
function LocalCharacter.heldRod(): Tool?
	return rodIn(player.Character)
end

-- The rod whether held or in the backpack.
function LocalCharacter.rod(): Tool?
	return rodIn(player.Character) or rodIn(player:FindFirstChildOfClass("Backpack"))
end

-- The attachment the fishing line hangs from, for any player.
function LocalCharacter.rodTip(of: Player?): Attachment?
	local rod = rodIn((of or player).Character)
	local handle = rod and rod:FindFirstChild("Handle")
	return handle and handle:FindFirstChild("Tip") :: Attachment?
end

function LocalCharacter.toggleRod()
	local humanoid = LocalCharacter.humanoid()
	if not humanoid then
		return
	end
	if LocalCharacter.heldRod() then
		humanoid:UnequipTools()
	else
		local rod = LocalCharacter.rod()
		if rod then
			humanoid:EquipTool(rod)
		end
	end
end

return LocalCharacter
