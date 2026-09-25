--!strict
-- The player-list columns. Everything that changes Yen or catches updates them through here.

local Leaderstats = {}

function Leaderstats.create(player: Player, yen: number, caught: number)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	-- Column order follows creation order.
	for _, entry in { { "Yen", yen }, { "Caught", caught } } do
		local stat = Instance.new("IntValue")
		stat.Name = entry[1] :: string
		stat.Value = entry[2] :: number
		stat.Parent = folder
	end
	folder.Parent = player
end

function Leaderstats.set(player: Player, name: string, value: number)
	local folder = player:FindFirstChild("leaderstats")
	local stat = folder and folder:FindFirstChild(name) :: IntValue?
	if stat then
		stat.Value = value
	end
end

return Leaderstats
