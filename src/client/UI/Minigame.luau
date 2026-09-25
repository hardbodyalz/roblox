--!strict
-- The reel minigame. Hold (mouse / touch / space / gamepad A) to push the catch bar right,
-- release to let it drift back. Keep the Waifu marker inside the bar to fill the progress meter.
-- Parameters come from the server; it re-checks timing when you report success.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)

local Minigame = {}

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
	intensity: number,
}

local ACCEL = 3.4
local MAX_VEL = 1.5
local BOUNCE = 0.35

local gui = Kit.new("ScreenGui", {
	Name = "Minigame",
	ResetOnSpawn = false,
	DisplayOrder = 20,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local panel = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -150),
	Size = UDim2.fromOffset(560, 130),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.1,
	Parent = gui,
}, { Kit.corner(14), Kit.stroke(C.accent, 2, 0.3), Kit.new("UIScale") })

local title = Kit.label({
	Text = "HOLD TO REEL",
	Font = Kit.Font,
	TextSize = 22,
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0, 30),
	Position = UDim2.fromOffset(0, 6),
	Parent = panel,
})

local track = Kit.new("Frame", {
	Position = UDim2.fromOffset(20, 42),
	Size = UDim2.new(1, -40, 0, 44),
	BackgroundColor3 = Color3.fromRGB(20, 60, 90),
	ClipsDescendants = true,
	Parent = panel,
}, { Kit.corner(8), Kit.stroke(Color3.new(0, 0, 0), 2, 0.4) })

local bar = Kit.new("Frame", {
	Size = UDim2.fromScale(0.2, 1),
	BackgroundColor3 = C.good,
	BackgroundTransparency = 0.45,
	Parent = track,
}, { Kit.corner(6), Kit.stroke(Color3.new(1, 1, 1), 2, 0.3) })

local fish = Kit.label({
	Text = "💗",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Center,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(34, 34),
	Position = UDim2.fromScale(0.5, 0.5),
	ZIndex = 3,
	Parent = track,
})

local progressTrack = Kit.new("Frame", {
	Position = UDim2.fromOffset(20, 98),
	Size = UDim2.new(1, -40, 0, 16),
	BackgroundColor3 = C.panel3,
	Parent = panel,
}, { Kit.corner(8) })
local progressFill = Kit.new("Frame", {
	Size = UDim2.fromScale(0.3, 1),
	BackgroundColor3 = C.accent,
	Parent = progressTrack,
}, { Kit.corner(8) })

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

-- Runs the minigame; yields until landed (true) or lost (false).
function Minigame.play(params: Params): boolean
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
	title.Text = if params.overweight then "TOO HEAVY FOR YOUR ROD! HOLD ON!" elseif params.intensity >= 3 then "SOMETHING HUGE IS FIGHTING!" elseif params.intensity == 2 then "IT'S PULLING HARD!" else "HOLD TO REEL"
	title.TextColor3 = if params.intensity >= 3 or params.overweight then C.bad elseif params.intensity == 2 then C.gold else C.text
	panel.Position = UDim2.new(0.5, 0, 1, -150)
	gui.Enabled = true

	local result: boolean? = nil
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
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
		bar.BackgroundColor3 = if inside then C.good else C.bad

		bar.Position = UDim2.fromScale(barPos, 0)
		fish.Position = UDim2.fromScale(fishPos, 0.5)
		progressFill.Size = UDim2.fromScale(progress / 100, 1)

		-- Shake for strong fighters; glitch for Corrupted.
		local shake = if params.intensity >= 3 then 3 elseif params.intensity == 2 then 1.5 else 0
		if params.glitch then
			glitchTimer -= dt
			if glitchTimer <= 0 then
				glitchTimer = rng:NextNumber(0.05, 0.5)
				fish.Text = if rng:NextNumber() < 0.3 then "▓" else "💗"
				track.BackgroundColor3 = if rng:NextNumber() < 0.2 then Color3.fromRGB(80, 0, 20) else Color3.fromRGB(20, 60, 90)
				fish.Visible = rng:NextNumber() > 0.15
			end
			shake += 2
		end
		panel.Position = UDim2.new(0.5, rng:NextNumber(-shake, shake), 1, -150 + rng:NextNumber(-shake, shake))

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
	track.BackgroundColor3 = Color3.fromRGB(20, 60, 90)
	gui.Enabled = false
	holding = false
	return result :: boolean
end

function Minigame.isOpen(): boolean
	return gui.Enabled
end

return Minigame
