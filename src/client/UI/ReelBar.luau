--!strict
-- The reel minigame, bottom-centre. Hold (mouse / touch / space / gamepad A or R2) to push your
-- white bar right, release to let it drift back. Keep the Waifu inside it to fill the progress
-- line underneath. Parameters come from the server; it re-checks timing when you report success.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)

local ReelBar = {}

local player = Players.LocalPlayer
local C = Kit.Colors

export type Params = {
	fishSpeed: number,
	erratic: number,
	gain: number,
	loss: number,
	barWidth: number,
	start: number,
	glitch: boolean,
	overweight: boolean,
	shakes: number,
	intensity: number,
}

local ACCEL = 3.4
local MAX_VEL = 1.5
local BOUNCE = 0.35
local TRACK_COLOR = Color3.fromRGB(10, 14, 22)
local GLITCH_COLOR = Color3.fromRGB(70, 0, 20)
local BOTTOM = -110

local gui = Kit.new("ScreenGui", {
	Name = "ReelBar",
	ResetOnSpawn = false,
	DisplayOrder = 20,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local root = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, BOTTOM),
	Size = UDim2.new(0.42, 0, 0, 78),
	BackgroundTransparency = 1,
	Parent = gui,
}, { Kit.new("UISizeConstraint", { MinSize = Vector2.new(320, 78), MaxSize = Vector2.new(640, 78) }) })

local title = Kit.hudLabel({
	Text = "REEL",
	FontFace = Kit.Title,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0, 22),
	Parent = root,
})

local track = Kit.new("Frame", {
	Position = UDim2.fromOffset(0, 26),
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = TRACK_COLOR,
	BackgroundTransparency = 0.2,
	ClipsDescendants = true,
	Parent = root,
}, { Kit.corner(6), Kit.stroke(C.line, 1.5, 0.35) })

local bar = Kit.new("Frame", {
	Size = UDim2.fromScale(0.2, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	Parent = track,
}, { Kit.corner(5), Kit.stroke(C.line, 1.5, 0.1) })

local fish = Kit.label({
	Text = "💗",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(24, 24),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 3,
	Parent = track,
})

local progressTrack = Kit.new("Frame", {
	Position = UDim2.fromOffset(0, 64),
	Size = UDim2.new(1, 0, 0, 8),
	BackgroundColor3 = TRACK_COLOR,
	BackgroundTransparency = 0.3,
	Parent = root,
}, { Kit.corner(4), Kit.stroke(C.line, 1, 0.6) })
local progressFill = Kit.new("Frame", {
	Size = UDim2.fromScale(0.3, 1),
	BackgroundColor3 = C.good,
	BorderSizePixel = 0,
	Parent = progressTrack,
}, { Kit.corner(4) })

local holding = false
local function isHoldInput(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.Space
		or input.KeyCode == Enum.KeyCode.ButtonA
		or input.KeyCode == Enum.KeyCode.ButtonR2
end

UserInputService.InputBegan:Connect(function(input)
	if gui.Enabled and isHoldInput(input) then
		holding = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if isHoldInput(input) then
		holding = false
	end
end)

local function titleFor(params: Params): (string, Color3)
	if params.overweight then
		return "TOO HEAVY FOR YOUR ROD!", C.bad
	elseif params.intensity >= 3 then
		return "SOMETHING HUGE IS FIGHTING!", C.bad
	elseif params.intensity == 2 then
		return "SHE'S PULLING HARD!", C.gold
	end
	return "REEL", C.text
end

-- Runs the minigame; yields until landed (true) or lost (false).
function ReelBar.play(params: Params): boolean
	local rng = Random.new()
	local barPos = 0.5 - params.barWidth / 2
	local barVel = 0
	local fishPos = rng:NextNumber(0.2, 0.8)
	local fishTarget = fishPos
	local retargetIn = 0
	local progress = params.start
	local glitchTimer = 0
	holding = false

	bar.Size = UDim2.fromScale(params.barWidth, 1)
	title.Text, title.TextColor3 = titleFor(params)
	root.Position = UDim2.new(0.5, 0, 1, BOTTOM)
	gui.Enabled = true

	local result: boolean? = nil
	local connection = RunService.RenderStepped:Connect(function(dt)
		dt = math.min(dt, 1 / 20)

		-- Catch bar physics
		barVel = math.clamp(barVel + (if holding then ACCEL else -ACCEL) * dt, -MAX_VEL, MAX_VEL)
		barPos += barVel * dt
		local maxPos = 1 - params.barWidth
		if barPos < 0 then
			barPos = 0
			barVel = -barVel * BOUNCE
		elseif barPos > maxPos then
			barPos = maxPos
			barVel = -barVel * BOUNCE
		end

		-- Waifu movement: pick a new target now and then; erratic ones dart further and more often.
		retargetIn -= dt
		if retargetIn <= 0 then
			local reach = 0.15 + params.erratic * 0.6
			fishTarget = math.clamp(fishPos + rng:NextNumber(-reach, reach), 0.03, 0.97)
			retargetIn = rng:NextNumber(0.4, 1.6) * (1.2 - params.erratic * 0.7)
		end
		local speed = params.fishSpeed * (0.6 + rng:NextNumber() * 0.8)
		local delta = fishTarget - fishPos
		fishPos += math.sign(delta) * math.min(math.abs(delta), speed * dt)

		-- Progress
		local inside = fishPos >= barPos and fishPos <= barPos + params.barWidth
		progress = math.clamp(progress + (if inside then params.gain else -params.loss) * dt, 0, 100)
		bar.BackgroundTransparency = if inside then 0.45 else 0.7

		bar.Position = UDim2.fromScale(barPos, 0)
		fish.Position = UDim2.fromScale(fishPos, 0.5)
		progressFill.Size = UDim2.fromScale(progress / 100, 1)
		progressFill.BackgroundColor3 = C.bad:Lerp(C.good, progress / 100)

		-- Shake for strong fighters; glitch for Corrupted.
		local shake = if params.intensity >= 3 then 3 elseif params.intensity == 2 then 1.5 else 0
		if params.glitch then
			glitchTimer -= dt
			if glitchTimer <= 0 then
				glitchTimer = rng:NextNumber(0.05, 0.5)
				fish.Text = if rng:NextNumber() < 0.3 then "▓" else "💗"
				track.BackgroundColor3 = if rng:NextNumber() < 0.2 then GLITCH_COLOR else TRACK_COLOR
				fish.Visible = rng:NextNumber() > 0.15
			end
			shake += 2
		end
		root.Position = UDim2.new(0.5, rng:NextNumber(-shake, shake), 1, BOTTOM + rng:NextNumber(-shake, shake))

		if progress >= 100 then
			result = true
		elseif progress <= 0 then
			result = false
		end
	end)

	while result == nil do
		task.wait()
	end
	connection:Disconnect()
	fish.Visible = true
	fish.Text = "💗"
	track.BackgroundColor3 = TRACK_COLOR
	gui.Enabled = false
	holding = false
	return result :: boolean
end

return ReelBar
