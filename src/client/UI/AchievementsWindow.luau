--!strict
-- Permanent milestones and a few lifetime stats.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Achievements = require(Shared.Config.Achievements)
local Format = require(Shared.Format)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local State = require(script.Parent.Parent.State)

local AchievementsWindow = {}

local C = Kit.Colors

local handle = Window.create("Achievements", "🏆 Achievements", Vector2.new(640, 540))
local content = handle.content

local stats = Kit.label({ Size = UDim2.new(1, 0, 0, 44), TextSize = 15, TextColor3 = C.muted, Parent = content })
local list = Window.scroller(content, { Position = UDim2.fromOffset(0, 50), Size = UDim2.new(1, 0, 1, -50) })
Kit.list(6).Parent = list

function AchievementsWindow.refresh()
	if not handle.frame.Visible or not State.data then
		return
	end
	local data = State.data
	stats.Text = string.format(
		"Catches: %s   ·   Lifetime Yen: %s   ·   Heaviest: %s   ·   Most valuable: %s",
		Format.commas(data.catches),
		Format.yen(data.totalYen),
		Format.kg(data.best.kg),
		Format.yen(data.best.value)
	)
	Window.clear(list)
	for i, achievement in Achievements.list do
		local done = data.achievements[achievement.id] == true
		local row = Kit.new("Frame", {
			BackgroundColor3 = if done then C.panel3 else C.panel2,
			Size = UDim2.new(1, -10, 0, 54),
			LayoutOrder = i,
			Parent = list,
		}, { Kit.corner(10), Kit.stroke(if done then C.gold else C.panel3, 2, 0.3) })
		Kit.label({ Text = (if done then "🏆 " else "🔒 ") .. achievement.name, Font = Kit.Font, TextSize = 18, TextColor3 = if done then C.gold else C.text, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 22), Parent = row })
		Kit.label({ Text = achievement.desc, TextSize = 14, TextColor3 = C.muted, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -24, 0, 20), Parent = row })
	end
end

handle.onOpen = AchievementsWindow.refresh
State.onChange(function(changed)
	if changed.achievements or changed.catches or changed["*"] then
		AchievementsWindow.refresh()
	end
end)

return AchievementsWindow
