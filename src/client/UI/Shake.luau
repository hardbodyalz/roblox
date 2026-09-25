--!strict
-- The shake phase between a bite and the reel: SHAKE prompts pop up around the screen and you
-- click (or tap, or press Enter / A) each one. Miss the time limit and she slips off the hook.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Kit = require(script.Parent.Kit)

local Shake = {}

local player = Players.LocalPlayer
local C = Kit.Colors

local gui = Kit.new("ScreenGui", {
	Name = "Shake",
	ResetOnSpawn = false,
	DisplayOrder = 21,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local button = Kit.button("SHAKE", C.panel, {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Size = UDim2.fromOffset(120, 52),
	FontFace = Kit.Title,
	TextSize = 22,
	BackgroundTransparency = 0.15,
	Parent = gui,
})
local stroke = button:FindFirstChildOfClass("UIStroke") :: UIStroke
stroke.Thickness = 2
stroke.Transparency = 0.2
local scale = Kit.new("UIScale", { Parent = button })

local counter = Kit.hudLabel({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -170),
	Size = UDim2.fromOffset(300, 24),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextSize = 18,
	Parent = gui,
})

local rng = Random.new()
local pressed: BindableEvent = Instance.new("BindableEvent")

button.Activated:Connect(function()
	pressed:Fire()
end)
UserInputService.InputBegan:Connect(function(input)
	if gui.Enabled and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.ButtonA) then
		pressed:Fire()
	end
end)

local function place()
	button.Position = UDim2.fromScale(rng:NextNumber(0.25, 0.75), rng:NextNumber(0.3, 0.7))
	scale.Scale = 0.4
	Kit.tween(scale, 0.15, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Yields until every prompt is pressed (true) or time runs out (false).
function Shake.play(count: number, timeout: number, onShake: (() -> ())?): boolean
	local done = 0
	local deadline = os.clock() + timeout
	counter.Text = string.format("Shake! 0 / %d", count)
	place()
	gui.Enabled = true
	local conn = pressed.Event:Connect(function()
		done += 1
		counter.Text = string.format("Shake! %d / %d", done, count)
		if onShake then
			task.spawn(onShake)
		end
		if done < count then
			place()
		end
	end)
	while done < count and os.clock() < deadline do
		task.wait()
	end
	conn:Disconnect()
	gui.Enabled = false
	return done >= count
end

return Shake
