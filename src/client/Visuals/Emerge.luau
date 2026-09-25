--!strict
-- A caught Waifu surfaces: splash and ripple, a light pillar for rare ones, she rises out of the
-- water spinning and dripping, then leaps over to stand beside whoever caught her. She stays until
-- dismissed, then vanishes in sparkles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Water = require(Shared.Water)

local WaifuModel = require(script.Parent.WaifuModel)

local Emerge = {}

export type Handle = {
	model: Model,
	dismissed: boolean,
}

local RISE_SECONDS = 1.3
local HOVER_SECONDS = 0.35
local LEAP_SECONDS = 0.7

local function ease(t: number): number
	-- Out-back: overshoots slightly, like breaking the surface.
	local c1 = 1.4
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end

local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end

-- Runs step(alpha) every frame for `seconds`, yielding until done.
local function animate(seconds: number, step: (number) -> ())
	local elapsed = 0
	while elapsed < seconds do
		elapsed += RunService.RenderStepped:Wait()
		step(math.min(1, elapsed / seconds))
	end
end

local function fxPart(position: Vector3, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size or Vector3.new(1, 1, 1)
	p.Position = position
	p.Parent = Water.fxFolder()
	return p
end

function Emerge.splash(at: Vector3, color: Color3?, amount: number?)
	local holder = fxPart(at)
	local splash = Instance.new("ParticleEmitter")
	splash.Rate = 0
	splash.Lifetime = NumberRange.new(0.6, 1.1)
	splash.Speed = NumberRange.new(12, 22)
	splash.SpreadAngle = Vector2.new(35, 35)
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Acceleration = Vector3.new(0, -45, 0)
	splash.Size = NumberSequence.new(0.5, 0.15)
	splash.Transparency = NumberSequence.new(0.1, 1)
	splash.Color = ColorSequence.new(color or Color3.fromRGB(220, 240, 255))
	splash.Parent = holder
	splash:Emit(amount or 40)

	-- Expanding ripple on the surface.
	local ring = fxPart(at + Vector3.new(0, 0.05, 0), Vector3.new(0.1, 2, 2))
	ring.Shape = Enum.PartType.Cylinder
	ring.CFrame = CFrame.new(ring.Position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(235, 245, 255)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.4
	task.spawn(function()
		animate(0.8, function(a)
			local d = 2 + a * 14
			ring.Size = Vector3.new(0.1, d, d)
			ring.Transparency = 0.4 + a * 0.6
		end)
		ring:Destroy()
	end)
	task.delay(1.5, function()
		holder:Destroy()
	end)
end

local function pillar(at: Vector3, color: Color3)
	local beam = fxPart(at + Vector3.new(0, 40, 0), Vector3.new(80, 3, 3))
	beam.Shape = Enum.PartType.Cylinder
	beam.CFrame = CFrame.new(beam.Position) * CFrame.Angles(0, 0, math.rad(90))
	beam.Color = color
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.2
	task.spawn(function()
		animate(1.8, function(a)
			local w = 3 + a * 3
			beam.Size = Vector3.new(80, w, w)
			beam.Transparency = 0.2 + a * 0.8
		end)
		beam:Destroy()
	end)
end

local function groundBelow(position: Vector3): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = Water.ignoreList()
	params.IgnoreWater = false
	local result = workspace:Raycast(position + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), params)
	return result and result.Position
end

-- Surfaces a catch at `at` (the bobber). If `owner` is given she leaps to stand beside them.
-- Yields until she has landed.
function Emerge.surface(info: { c: string, m: string, w: number }, at: Vector3, owner: BasePart?): Handle
	local character = Characters.byId[info.c]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[info.m] or Mutations.byId.Normal
	local model, height = WaifuModel.build(info.c, info.m, info.w)
	local handle: Handle = { model = model, dismissed = false }

	-- Face whoever caught her.
	local facing = if owner then Vector3.new(owner.Position.X, at.Y, owner.Position.Z) else at + Vector3.new(0, 0, -1)
	if (facing - at).Magnitude < 0.1 then
		facing = at + Vector3.new(0, 0, -1)
	end
	local look = CFrame.lookAt(at, facing)
	model:PivotTo(look * CFrame.new(0, -height - 0.5, 0))
	model.Parent = Water.fxFolder()

	if rarity.order >= 4 or mutation.order >= 5 then
		pillar(at, if mutation.order >= 5 then mutation.color else rarity.color)
	end
	Emerge.splash(at, nil, 30 + rarity.order * 8)

	local drips = Instance.new("ParticleEmitter")
	drips.Rate = 30
	drips.Lifetime = NumberRange.new(0.4, 0.8)
	drips.Speed = NumberRange.new(0, 1)
	drips.Acceleration = Vector3.new(0, -30, 0)
	drips.Size = NumberSequence.new(0.2)
	drips.Transparency = NumberSequence.new(0.2, 1)
	drips.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	drips.Parent = model:FindFirstChild("Torso") or model.PrimaryPart
	task.delay(RISE_SECONDS + 1.5, function()
		drips.Enabled = false
	end)

	-- Rise, spinning once.
	local risen = look * CFrame.new(0, 1.2, 0)
	animate(RISE_SECONDS, function(a)
		local y = -height - 0.5 + (height + 1.7) * ease(a)
		model:PivotTo(look * CFrame.new(0, y, 0) * CFrame.Angles(0, (1 - smooth(a)) * math.pi * 2, 0))
	end)
	Emerge.splash(at, nil, 15)
	animate(HOVER_SECONDS, function(a)
		model:PivotTo(risen * CFrame.new(0, math.sin(a * math.pi) * 0.3, 0))
	end)

	-- Leap to stand beside the angler.
	local rest = risen
	if owner and owner.Parent then
		local side = owner.CFrame.RightVector * 3.5 + owner.CFrame.LookVector * 1.5
		local spot = owner.Position + side
		local ground = groundBelow(spot)
		local feet = if ground then ground else Vector3.new(spot.X, at.Y, spot.Z)
		local faceOwner = Vector3.new(owner.Position.X, feet.Y, owner.Position.Z)
		local target = CFrame.lookAt(feet, if (faceOwner - feet).Magnitude > 0.1 then faceOwner else feet + owner.CFrame.LookVector)
		local from = risen
		local arc = math.max(4, (target.Position - from.Position).Magnitude * 0.25)
		animate(LEAP_SECONDS, function(a)
			local s = smooth(a)
			local cf = from:Lerp(target, s)
			model:PivotTo(cf + Vector3.new(0, math.sin(a * math.pi) * arc, 0))
		end)
		rest = target
		Emerge.splash(at, nil, 10)
	end

	-- Idle: gentle bob and sway until dismissed.
	task.spawn(function()
		local t = 0
		while not handle.dismissed and model.Parent do
			t += RunService.RenderStepped:Wait()
			model:PivotTo(rest * CFrame.new(0, math.abs(math.sin(t * 2)) * 0.15, 0) * CFrame.Angles(0, math.sin(t * 0.8) * 0.12, 0))
		end
	end)
	return handle
end

-- She vanishes in a burst of sparkles.
function Emerge.dismiss(handle: Handle)
	if handle.dismissed then
		return
	end
	handle.dismissed = true
	local model = handle.model
	if not model.Parent then
		return
	end
	local center = model:GetPivot().Position + Vector3.new(0, 3, 0)
	local holder = fxPart(center)
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Rate = 0
	sparkle.Lifetime = NumberRange.new(0.6, 1.2)
	sparkle.Speed = NumberRange.new(4, 9)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Size = NumberSequence.new(0.45, 0)
	sparkle.LightEmission = 1
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 200, 230), Color3.fromRGB(255, 255, 255))
	sparkle.Parent = holder
	sparkle:Emit(45)
	task.delay(1.5, function()
		holder:Destroy()
	end)

	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then
			table.insert(parts, { part = d, from = d.Transparency })
		elseif d:IsA("BillboardGui") or d:IsA("Highlight") then
			d:Destroy()
		end
	end
	local start = model:GetPivot()
	animate(0.45, function(a)
		model:PivotTo(start + Vector3.new(0, a * 1.5, 0))
		for _, entry in parts do
			entry.part.Transparency = entry.from + (1 - entry.from) * a
		end
	end)
	model:Destroy()
end

return Emerge
