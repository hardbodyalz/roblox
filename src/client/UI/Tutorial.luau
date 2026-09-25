--!strict
-- Guided tutorial (not a quest): a few lines from the Harbourmaster, advanced by just playing.
--   0 Rod out, cast, reel   -> first catch
--   1 Mutations; sell one   -> first sale
--   2 Upgrade your rod      -> open the Shop
--   3 Sail to new waters    -> "Got it"
--   4 done

local Players = game:GetService("Players")

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local State = require(script.Parent.Parent.State)
local Remote = require(script.Parent.Parent.Remote)

local Tutorial = {}

local player = Players.LocalPlayer
local C = Kit.Colors

local LINES = {
	[0] = "Welcome to Sakura Shore! Press <b>1</b> to take out your rod, face the water and <b>HOLD CLICK</b> to cast. Let go in the gold for a Perfect Cast. You can fish in any water, and the 🎣 hotspots off the piers give bonuses.",
	[1] = "Your first Waifu! Every catch rolls a <b>mutation</b> too: Shiny, Golden... even Void. <b>SELL DUPLICATES OR KEEP THEM FOR YOUR COLLECTION.</b> Try selling one in 🎒 Catches.",
	[2] = "Nice Yen! Save up and <b>UPGRADE YOUR ROD</b> in the 🛒 Shop. Better rods mean more Luck, heavier catches, fewer shakes and longer casts.",
	[3] = "Boats take you further. When you're ready, <b>SAIL TO NEW WATERS</b> ⛵ to find different Waifus, or swim out to the <b>open sea</b> where secrets surface more often. Good luck out there!",
}

local gui = Kit.new("ScreenGui", {
	Name = "Tutorial",
	ResetOnSpawn = false,
	DisplayOrder = 5,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local box = Kit.panel({
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.fromOffset(340, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 0.1,
	Parent = gui,
}, { Kit.padding(12), Kit.list(6) })

Kit.label({ Text = "Harbourmaster Kaito", FontFace = Kit.Title, TextSize = 18, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1, Parent = box })
local body = Kit.label({ TextSize = 15, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = box })
local buttons = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 3, Parent = box }, { Kit.list(8, true) })
local gotIt = Kit.button("Got it", C.good, { Size = UDim2.fromOffset(100, 30), TextSize = 15, TextColor3 = C.panel, Parent = buttons })
local skip = Kit.button("Skip tutorial", C.panel3, { Size = UDim2.fromOffset(120, 30), TextSize = 14, Parent = buttons })

local step = 0

local function setStep(n: number)
	step = n
	if n >= 4 then
		gui.Enabled = false
	else
		gui.Enabled = true
		body.Text = LINES[n]
		gotIt.Visible = n == 3
	end
end

local function advance(to: number)
	if to > step then
		setStep(to)
		Remote.request("Tutorial", { step = to })
	end
end

gotIt.Activated:Connect(function()
	advance(4)
end)
skip.Activated:Connect(function()
	advance(4)
end)

function Tutorial.start()
	State.onChange(function(changed)
		local data = State.data
		if changed["*"] then
			setStep(data.tutorial)
		end
		if step == 0 and data.catches >= 1 then
			advance(1)
		end
		if step == 1 and data.totalYen > 0 then
			advance(2)
		end
	end)
	Window.onOpened(function(name)
		if step == 2 and name == "Shop" then
			advance(3)
		end
	end)
end

return Tutorial
