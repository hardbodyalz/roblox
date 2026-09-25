--!strict
-- "Is this water?" Shared by the client (to aim a cast) and the server (to validate it).
-- Water is terrain water or any part tagged with the "Water" attribute (ponds).

local Players = game:GetService("Players")

local Water = {}

-- Client-side effects (bobbers, surfacing Waifus, weather props) live here and never block a cast.
Water.FX_FOLDER = "FishingFx"

-- Every character plus the effects folder (and anything extra): the things a cast should see through.
function Water.ignoreList(extra: { Instance }?): { Instance }
	local list: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(list, player.Character)
		end
	end
	local fx = workspace:FindFirstChild(Water.FX_FOLDER)
	if fx then
		table.insert(list, fx)
	end
	if extra then
		for _, inst in extra do
			table.insert(list, inst)
		end
	end
	return list
end

local function isWaterHit(result: RaycastResult): boolean
	return result.Material == Enum.Material.Water or result.Instance:GetAttribute("Water") == true
end

-- Drops a ray straight down through (x, z) starting at fromY. Returns the water surface point,
-- or nil if the first thing below is land (or nothing at all).
function Water.surfaceBelow(x: number, z: number, fromY: number, depth: number, extra: { Instance }?): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = Water.ignoreList(extra)
	params.IgnoreWater = false
	local result = workspace:Raycast(Vector3.new(x, fromY, z), Vector3.new(0, -depth, 0), params)
	if result and isWaterHit(result) then
		return result.Position
	end
	return nil
end

-- Server-side check of a point the client says is water.
function Water.isWater(point: Vector3): boolean
	return Water.surfaceBelow(point.X, point.Z, point.Y + 6, 14) ~= nil
end

-- The effects folder, created on first use. Only clients put anything in it.
function Water.fxFolder(): Folder
	local folder = workspace:FindFirstChild(Water.FX_FOLDER)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Water.FX_FOLDER
		folder.Parent = workspace
	end
	return folder :: Folder
end

return Water
