--!strict
-- Client side of fishing: spot detection, cast, bobber, bite, minigame, result.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Islands = require(Config.Islands)
local Rarities = require(Config.Rarities)
local Net = require(Shared.Net)

local Remote = require(script.Parent.Remote)
local Minigame = require(script.Parent.UI.Minigame)
local CatchScreen = require(script.Parent.UI.CatchScreen)
local Notices = require(script.Parent.UI.Notices)

local Fishing = {}

local player = Players.LocalPlayer

-- "idle" | "casting" | "waiting" | "reeling"
Fishing.state = "idle"
local currentSpot: string? = nil
local castSpot: string? = nil
local bobber: BasePart? = nil
local bobberConn: RBXScriptConnection? = nil
local statusListeners: { (string?) -> () } = {}

local function setStatus(text: string?)
	for _, fn in statusListeners do
		task.spawn(fn, text)
	end
end

function Fishing.onStatus(fn: (string?) -> ())
	table.insert(statusListeners, fn)
end

function Fishing.currentSpot(): string?
	return currentSpot
end

local function rootPart(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function nearestSpot(): string?
	local root = rootPart()
	if not root then
		return nil
	end
	local best, bestDist = nil, math.huge
	for _, island in Islands.list do
		for _, spot in island.spots do
			local p = Islands.spotPosition(island, spot)
			local d = Vector3.new(root.Position.X - p.X, 0, root.Position.Z - p.Z).Magnitude
			if d <= Islands.SPOT_RADIUS and math.abs(root.Position.Y - p.Y) < 30 and d < bestDist then
				best, bestDist = spot.id, d
			end
		end
	end
	return best
end

-- Bobber -------------------------------------------------------------------------

local function clearBobber()
	if bobberConn then
		bobberConn:Disconnect()
		bobberConn = nil
	end
	if bobber then
		bobber:Destroy()
		bobber = nil
	end
end

local function spawnBobber(spotId: string)
	clearBobber()
	local spot = Islands.spotsById[spotId]
	local island = Islands.islandOfSpot[spotId]
	local p = Islands.spotPosition(island, spot)
	local target: Vector3
	if spot.kind == "dock" then
		local a = math.rad(spot.angle)
		target = p + Vector3.new(math.cos(a), 0, math.sin(a)) * 20 + Vector3.new(0, 0.2, 0)
	else
		local rng = Random.new()
		target = p + Vector3.new(rng:NextNumber(-5, 5), 3 + 0.9, rng:NextNumber(-5, 5))
	end

	local part = Instance.new("Part")
	part.Name = "Bobber"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(0.9, 0.9, 0.9)
	part.Color = Color3.fromRGB(255, 70, 90)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Position = target
	part.Parent = workspace

	local character = player.Character
	local hand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")) :: BasePart?
	if hand then
		local a0 = Instance.new("Attachment")
		a0.Parent = hand
		local a1 = Instance.new("Attachment")
		a1.Parent = part
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Width0 = 0.06
		beam.Width1 = 0.06
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1))
		beam.FaceCamera = true
		beam.CurveSize0 = -2
		beam.Segments = 12
		beam.Parent = part
		-- The hand attachment dies with the bobber.
		part.Destroying:Connect(function()
			a0:Destroy()
		end)
	end

	local t0 = os.clock()
	bobber = part
	bobberConn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local dip = if Fishing.state == "reeling" then -0.6 + math.sin(t * 25) * 0.3 else math.sin(t * 2.5) * 0.12
		part.Position = target + Vector3.new(0, dip, 0)
	end)
end

-- Movement lock while reeling ------------------------------------------------------

local saved: { walk: number, jump: number, jumpHeight: number }? = nil
local function lockMovement(lock: boolean)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if lock and not saved then
		saved = { walk = humanoid.WalkSpeed, jump = humanoid.JumpPower, jumpHeight = humanoid.JumpHeight }
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
	elseif not lock and saved then
		humanoid.WalkSpeed = saved.walk
		humanoid.JumpPower = saved.jump
		humanoid.JumpHeight = saved.jumpHeight
		saved = nil
	end
end

-- Flow -----------------------------------------------------------------------------

local function reset()
	Fishing.state = "idle"
	castSpot = nil
	clearBobber()
	lockMovement(false)
	setStatus(nil)
end

function Fishing.cast()
	if Fishing.state ~= "idle" or CatchScreen.isOpen() then
		return
	end
	local spotId = currentSpot
	if not spotId then
		Notices.error("Walk to a 🎣 fishing spot first.")
		return
	end
	Fishing.state = "casting"
	local ok = Remote.request("Cast", { spotId = spotId })
	if not ok then
		reset()
		return
	end
	Fishing.state = "waiting"
	castSpot = spotId
	spawnBobber(spotId)
	setStatus("Waiting for a bite...")
end

function Fishing.cancel()
	if Fishing.state == "waiting" then
		Remote.request("CancelCast")
		reset()
	end
end

local function onBite(token: number, params: Minigame.Params)
	if Fishing.state ~= "waiting" then
		return
	end
	Fishing.state = "reeling"
	lockMovement(true)
	setStatus("BITE!")
	task.wait(0.6)
	setStatus(nil)
	local success = Minigame.play(params)
	Remote.request("Reel", { token = token, success = success })
	reset()
end

local function onCatchResult(result: any)
	if result.lost then
		local rarity = Rarities.byId[result.rarity]
		local hint = if rarity and rarity.order >= 4 then " It felt " .. rarity.name .. "..." else ""
		Notices.toast("She got away!", "The line went slack." .. hint, Color3.fromRGB(255, 120, 120))
		return
	end
	task.spawn(CatchScreen.show, result)
end

function Fishing.start()
	Net.event("Bite").OnClientEvent:Connect(function(token, params)
		task.spawn(onBite, token, params)
	end)
	Net.event("CatchResult").OnClientEvent:Connect(onCatchResult)

	ContextActionService:BindAction("Cast", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			Fishing.cast()
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

	player.CharacterAdded:Connect(function()
		saved = nil
		if Fishing.state ~= "idle" then
			Fishing.cancel()
			reset()
		end
	end)

	-- Spot detection, and walking away cancels a cast.
	task.spawn(function()
		while true do
			task.wait(0.2)
			currentSpot = nearestSpot()
			if Fishing.state == "waiting" and castSpot and currentSpot ~= castSpot then
				Fishing.cancel()
				Notices.toast("Line reeled in", "You walked away from the spot.")
			end
		end
	end)
end

return Fishing
