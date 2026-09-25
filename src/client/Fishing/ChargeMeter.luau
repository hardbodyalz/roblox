--!strict
-- The cast power meter that floats beside your head while you hold to cast. Power swings
-- 0 -> 1 -> 0, so letting go at the top (the PERFECT band) takes timing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Kit = require(script.Parent.Parent.UI.Kit)

local ChargeMeter = {}

local C = Kit.Colors

local gui = Kit.new("BillboardGui", {
	Name = "CastMeter",
	Size = UDim2.fromOffset(90, 150),
	StudsOffset = Vector3.new(2.6, 1.5, 0),
	AlwaysOnTop = true,
	LightInfluence = 0,
	Enabled = false,
})

local track = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.new(0, 18, 1, -22),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.25,
	ClipsDescendants = true,
	Parent = gui,
}, { Kit.corner(9), Kit.stroke(C.line, 1.5, 0.3) })

-- PERFECT band at the top of the track.
Kit.new("Frame", {
	Size = UDim2.fromScale(1, 1 - Balance.PERFECT_CAST),
	BackgroundColor3 = C.gold,
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = track,
})

local fill = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	Size = UDim2.fromScale(1, 0),
	BackgroundColor3 = C.accent,
	BorderSizePixel = 0,
	ZIndex = 3,
	Parent = track,
}, { Kit.corner(9) })

local caption = Kit.hudLabel({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.new(1, 0, 0, 18),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 15,
	FontFace = Kit.Title,
	Text = "",
	Parent = gui,
})

local charging = false
local power = 0
local conn: RBXScriptConnection? = nil

function ChargeMeter.start(adornee: BasePart, parent: Instance)
	ChargeMeter.stop()
	gui.Adornee = adornee
	gui.Parent = parent
	gui.Enabled = true
	charging = true
	power = 0
	local t = 0
	conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		power = 1 - math.abs((t * Balance.CHARGE_SPEED) % 2 - 1)
		local perfect = power >= Balance.PERFECT_CAST
		fill.Size = UDim2.fromScale(1, power)
		fill.BackgroundColor3 = if perfect then C.gold else C.accent:Lerp(C.good, power)
		caption.Text = if perfect then "PERFECT" else ""
		caption.TextColor3 = C.gold
	end)
end

-- Hides the meter and returns the power it stopped at (0..1).
function ChargeMeter.stop(): number
	if conn then
		conn:Disconnect()
		conn = nil
	end
	gui.Enabled = false
	local result = if charging then power else 0
	charging = false
	return result
end

return ChargeMeter
