--!strict
-- Sail to other islands. Your equipped boat's Speed decides where you can go.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Islands = require(Config.Islands)
local Equipment = require(Config.Equipment)
local Balance = require(Config.Balance)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local State = require(script.Parent.Parent.State)
local Remote = require(script.Parent.Parent.Remote)

local SailWindow = {}

local C = Kit.Colors

local handle = Window.create("Sail", "⛵ Set Sail", Vector2.new(700, 540))
local content = handle.content

local boatLabel = Kit.label({ Size = UDim2.new(1, 0, 0, 24), TextSize = 16, TextColor3 = C.muted, Parent = content })
local list = Window.scroller(content, { Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32) })
Kit.list(8).Parent = list

local currentIsland: () -> string? = function()
	return nil
end

function SailWindow.setIslandGetter(fn: () -> string?)
	currentIsland = fn
end

function SailWindow.refresh()
	if not handle.frame.Visible or not State.data then
		return
	end
	Window.clear(list)
	local boat = Equipment.boatsById[State.data.boat]
	boatLabel.Text = string.format("Boat: %s  ·  Speed %d  ·  Change boats in the Shop", boat.name, boat.speed)
	local here = currentIsland()
	for i, island in Islands.list do
		local eventOver = island.event and not ReplicatedStorage:GetAttribute("EventActive")
		local row = Kit.new("Frame", {
			BackgroundColor3 = C.panel2,
			Size = UDim2.new(1, -10, 0, 78),
			LayoutOrder = i,
			Parent = list,
		}, { Kit.corner(10) })
		Kit.label({ Text = island.name .. (if island.event then Kit.color("  EVENT", C.gold) else ""), Font = Kit.Font, TextSize = 20, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -190, 0, 24), Parent = row })
		Kit.label({ Text = island.blurb, TextSize = 14, TextColor3 = C.muted, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -190, 0, 36), Parent = row })

		local canReach = boat.speed >= island.minBoatSpeed
		local label, color, enabled
		if here == island.id then
			label, color, enabled = "You are here", C.panel3, false
		elseif eventOver then
			label, color, enabled = "Event ended", C.panel3, false
		elseif not canReach then
			label, color, enabled = "Needs Speed " .. island.minBoatSpeed, C.panel3, false
		else
			label, color, enabled = string.format("Sail (%ds)", math.ceil(Balance.TRAVEL_BASE / boat.speed + 1)), C.good, true
		end
		local b = Kit.button(label, color, {
			Size = UDim2.fromOffset(160, 40),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			TextSize = 16,
			AutoButtonColor = enabled,
			Parent = row,
		})
		b.Activated:Connect(function()
			if enabled then
				local ok = Remote.request("Travel", { id = island.id })
				if ok then
					Window.close()
				end
			end
		end)
	end
end

handle.onOpen = SailWindow.refresh
State.onChange(function(changed)
	if changed.boat or changed["*"] then
		SailWindow.refresh()
	end
end)

return SailWindow
