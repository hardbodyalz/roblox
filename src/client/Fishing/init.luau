--!strict
-- Client side of fishing. With your rod out: hold to charge a cast, release to throw the bobber
-- where you're looking. It has to land in water (sea or pond), anywhere in the world. Click
-- again while waiting to reel in. On a bite: shake, then reel. A landed Waifu surfaces from
-- the water where your bobber was and leaps over to you.
--
-- States: idle -> charging -> casting -> waiting -> shaking -> reeling -> landing -> idle

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Rarities = require(Config.Rarities)
local Equipment = require(Config.Equipment)
local Balance = require(Config.Balance)
local Net = require(Shared.Net)
local Water = require(Shared.Water)

local client = script.Parent
local State = require(client.State)
local Remote = require(client.Remote)
local LocalCharacter = require(client.LocalCharacter)
local ReelBar = require(client.UI.ReelBar)
local Shake = require(client.UI.Shake)
local CatchCard = require(client.UI.CatchCard)
local Notices = require(client.UI.Notices)
local Kit = require(client.UI.Kit)
local Emerge = require(client.Visuals.Emerge)
local Bobber = require(script.Bobber)
local ChargeMeter = require(script.ChargeMeter)
local Others = require(script.Others)

local Fishing = {}

local player = Players.LocalPlayer

local state = "idle"
local bobber: Bobber.Bobber? = nil
local lineRange = 0
local statusListeners: { (string?) -> () } = {}

local function setStatus(text: string?)
	for _, fn in statusListeners do
		task.spawn(fn, text)
	end
end

function Fishing.onStatus(fn: (string?) -> ())
	table.insert(statusListeners, fn)
end

function Fishing.getState(): string
	return state
end

-- Rod swing ------------------------------------------------------------------------
-- Purely cosmetic: tilts the held rod back while charging and flicks it forward on release.

local function tilt(tool: Tool, degrees: number)
	local base = tool:GetAttribute("BaseGrip")
	if typeof(base) ~= "CFrame" then
		base = tool.Grip
		tool:SetAttribute("BaseGrip", base)
	end
	tool.Grip = (base :: CFrame) * CFrame.Angles(math.rad(-degrees), 0, 0)
end

local windup: RBXScriptConnection? = nil
local function startWindup(tool: Tool)
	local t = 0
	windup = RunService.RenderStepped:Connect(function(dt)
		t += dt
		tilt(tool, math.min(1, t * 3) * 40)
	end)
end

local function flick(tool: Tool)
	if windup then
		windup:Disconnect()
		windup = nil
	end
	task.spawn(function()
		tilt(tool, -25)
		task.wait(0.12)
		tilt(tool, -10)
		task.wait(0.15)
		tilt(tool, 0)
	end)
end

-- Movement lock while fighting a catch ------------------------------------------------

local saved: { walk: number, jump: number, jumpHeight: number }? = nil
local function lockMovement(lock: boolean)
	local humanoid = LocalCharacter.humanoid()
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

-- Flow -------------------------------------------------------------------------------

local function reset()
	state = "idle"
	if bobber then
		bobber:reelIn()
		bobber = nil
	end
	if windup then
		windup:Disconnect()
		windup = nil
		local tool = LocalCharacter.heldRod()
		if tool then
			tilt(tool, 0)
		end
	end
	ChargeMeter.stop()
	lockMovement(false)
	setStatus(nil)
end

local function aimDirection(root: BasePart): Vector3
	local camera = workspace.CurrentCamera
	local look = if camera then camera.CFrame.LookVector else root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	end
	return flat.Unit
end

local function cast(power: number)
	local root = LocalCharacter.root()
	local tool = LocalCharacter.heldRod()
	local data = State.data
	if not root or not tool or not data then
		reset()
		return
	end
	state = "casting"
	local rod = Equipment.rodsById[data.rod] or Equipment.rodsById.old_rod

	-- Turn to face the cast and throw.
	local direction = aimDirection(root)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + direction)
	flick(tool)

	local distance = Balance.CAST_MIN_RANGE + (rod.castRange - Balance.CAST_MIN_RANGE) * power
	local aim = root.Position + direction * distance
	local surface = Water.surfaceBelow(aim.X, aim.Z, root.Position.Y + 30, 160)
	if not surface then
		Notices.error("That's land! Cast into the water.")
		reset()
		return
	end

	local perfect = power >= Balance.PERFECT_CAST
	if perfect then
		Notices.float("PERFECT CAST!")
	end
	local b = Bobber.new(LocalCharacter.rodTip(), surface)
	bobber = b
	lineRange = rod.castRange + Balance.LINE_SNAP_MARGIN

	local ok = Remote.request("Cast", { target = surface, perfect = perfect })
	if bobber ~= b then
		return -- reset while waiting on the server
	end
	if not ok then
		reset()
		return
	end
	state = "waiting"
	setStatus("Waiting for a bite...")
end

function Fishing.beginCharge()
	if state == "waiting" then
		Fishing.reelIn()
		return
	end
	if state ~= "idle" or CatchCard.isBlocking() then
		return
	end
	local tool = LocalCharacter.heldRod()
	local character = player.Character
	local head = character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")) :: BasePart?
	if not tool or not head then
		return
	end
	state = "charging"
	ChargeMeter.start(head, player:WaitForChild("PlayerGui"))
	startWindup(tool)
end

function Fishing.release()
	if state ~= "charging" then
		return
	end
	local power = ChargeMeter.stop()
	task.spawn(cast, power)
end

function Fishing.reelIn()
	if state ~= "waiting" then
		return
	end
	task.spawn(Remote.request, "CancelCast")
	reset()
end

local function finish(token: number, success: boolean, b: Bobber.Bobber)
	local ok, result = Remote.request("Reel", { token = token, success = success })
	if bobber ~= b then
		return
	end
	if not ok or type(result) ~= "table" then
		reset()
		return
	end
	if result.lost then
		local rarity = Rarities.byId[result.rarity]
		local hint = if rarity and rarity.order >= 4 then " It felt " .. rarity.name .. "..." else ""
		Notices.toast("She got away!", "The line went slack." .. hint, Kit.Colors.bad)
		Emerge.splash(b:position(), nil, 25)
		reset()
		return
	end

	-- She surfaces where the bobber was, then leaps over beside you.
	state = "landing"
	setStatus(nil)
	local at = b:position()
	b:destroy()
	bobber = nil
	local item = result.item
	local handle = Emerge.surface({ c = item.c, m = item.m, w = item.w }, at, LocalCharacter.root())
	lockMovement(false)
	state = "idle"
	task.spawn(CatchCard.show, result, function()
		Emerge.dismiss(handle)
	end)
end

local function onBite(token: number, params: ReelBar.Params)
	local b = bobber
	if state ~= "waiting" or not b then
		return
	end
	state = "shaking"
	lockMovement(true)
	b:bite()
	setStatus(nil)
	local shook = Shake.play(params.shakes, Balance.SHAKE_TIMEOUT, function()
		b:shake()
	end)
	if bobber ~= b then
		return
	end
	local success = false
	if shook then
		state = "reeling"
		b:taut()
		success = ReelBar.play(params)
	end
	if bobber == b then
		finish(token, success, b)
	end
end

-- Input --------------------------------------------------------------------------------

local function isCastInput(input: InputObject): boolean
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 or input.KeyCode == Enum.KeyCode.E
end

function Fishing.start()
	Net.event("Bite").OnClientEvent:Connect(function(token, params)
		task.spawn(onBite, token, params)
	end)
	Others.start()

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and isCastInput(input) then
			Fishing.beginCharge()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isCastInput(input) then
			Fishing.release()
		end
	end)

	player.CharacterAdded:Connect(function()
		saved = nil
		if state == "waiting" or state == "casting" then
			task.spawn(Remote.request, "CancelCast")
		end
		reset()
	end)

	-- Walking too far from the bobber, or putting the rod away, reels the line in.
	task.spawn(function()
		while true do
			task.wait(0.2)
			if state == "charging" and not LocalCharacter.heldRod() then
				reset()
			elseif state == "waiting" and bobber then
				local root = LocalCharacter.root()
				local at = bobber:position()
				if not LocalCharacter.heldRod() then
					Fishing.reelIn()
				elseif root and Vector3.new(root.Position.X - at.X, 0, root.Position.Z - at.Z).Magnitude > lineRange then
					Fishing.reelIn()
					Notices.toast("Line reeled in", "You walked too far from your bobber.")
				end
			end
		end
	end)
end

return Fishing
