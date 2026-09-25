--!strict
-- Local visuals for time of day, weather and island mood. Lighting is driven entirely on the
-- client from Clock (shared time) + the replicated Weather attribute, and eased every frame.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Islands = require(Shared.Config.Islands)
local Clock = require(Shared.Clock)
local Water = require(Shared.Water)

local LocalCharacter = require(script.Parent.Parent.LocalCharacter)

local Atmosphere = {}

local rgb = Color3.fromRGB

type Look = {
	clock: number?, -- override time of day
	tint: Color3,
	saturation: number,
	contrast: number,
	brightness: number,
	density: number, -- Atmosphere.Density
	haze: number,
	atmoColor: Color3,
	water: Color3,
	ambient: Color3,
	moonSize: number,
}

local BASE: Look = {
	tint = Color3.new(1, 1, 1), saturation = 0.1, contrast = 0.05, brightness = 0,
	density = 0.3, haze = 0.5, atmoColor = rgb(199, 215, 235), water = rgb(40, 130, 160),
	ambient = rgb(70, 70, 90), moonSize = 11,
}

local WEATHER_LOOK: { [string]: { [string]: any } } = {
	Sunny = {},
	Rain = { tint = rgb(200, 210, 230), saturation = -0.2, density = 0.45, haze = 2, atmoColor = rgb(150, 160, 175), water = rgb(35, 80, 100) },
	GoldenHour = { clock = 17.6, tint = rgb(255, 225, 180), saturation = 0.25, atmoColor = rgb(255, 190, 120), water = rgb(120, 110, 80) },
	DiamondStorm = { tint = rgb(210, 240, 255), saturation = 0.1, density = 0.4, haze = 1.5, atmoColor = rgb(180, 230, 255), water = rgb(60, 170, 210) },
	EtherealFog = { tint = rgb(235, 225, 255), saturation = -0.2, density = 0.75, haze = 6, atmoColor = rgb(220, 210, 240), water = rgb(140, 150, 175) },
	CelestialStorm = { tint = rgb(255, 245, 210), saturation = 0.15, contrast = 0.15, density = 0.45, haze = 2, atmoColor = rgb(255, 235, 180), water = rgb(200, 190, 120) },
	BloodMoon = { clock = 0, tint = rgb(255, 150, 150), saturation = 0.1, contrast = 0.15, density = 0.4, haze = 1.5, atmoColor = rgb(120, 20, 25), water = rgb(110, 10, 15), ambient = rgb(110, 30, 30), moonSize = 45 },
	HuecoVoid = { clock = 21, tint = rgb(200, 150, 255), saturation = -0.3, contrast = 0.3, density = 0.5, haze = 2, atmoColor = rgb(60, 20, 90), water = rgb(8, 0, 18), ambient = rgb(70, 30, 110) },
	Mystery = { tint = rgb(255, 255, 255), saturation = -1, contrast = 0.4, density = 0.5, haze = 3, atmoColor = rgb(40, 40, 40), water = rgb(20, 20, 20) },
}

local function lookFor(weatherId: string, islandId: string?): Look
	local look = table.clone(BASE)
	for k, v in (WEATHER_LOOK[weatherId] or {}) :: { [string]: any } do
		(look :: any)[k] = v
	end
	local island = islandId and Islands.byId[islandId]
	if island and island.permanentNight and look.clock == nil then
		look.clock = 0
		look.tint = look.tint:Lerp(rgb(170, 180, 255), 0.4)
		look.ambient = rgb(60, 70, 110)
		look.moonSize = math.max(look.moonSize, 30)
	end
	if islandId == "oni_coast" and Clock.demonTide() then
		look.tint = look.tint:Lerp(rgb(255, 140, 130), 0.6)
		look.water = rgb(100, 15, 15)
		look.atmoColor = rgb(140, 40, 40)
	end
	return look
end

-- Instances ---------------------------------------------------------------------

local function ensure(className: string, name: string, parent: Instance): any
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = parent
	return inst
end

local cc: ColorCorrectionEffect = ensure("ColorCorrectionEffect", "WeatherGrade", Lighting)
local atmo: Atmosphere = ensure("Atmosphere", "Atmosphere", Lighting)
local sky: Sky = ensure("Sky", "Sky", Lighting)
local bloom: BloomEffect = ensure("BloomEffect", "Bloom", Lighting)
bloom.Intensity = 0.6
bloom.Size = 30
bloom.Threshold = 1.2
local flash: ColorCorrectionEffect = ensure("ColorCorrectionEffect", "Flash", Lighting)

-- Particles follow the camera.
local emitterPart = Instance.new("Part")
emitterPart.Name = "WeatherEmitter"
emitterPart.Anchored = true
emitterPart.CanCollide = false
emitterPart.CanQuery = false
emitterPart.CanTouch = false
emitterPart.Transparency = 1
emitterPart.Size = Vector3.new(120, 1, 120)
emitterPart.Parent = Water.fxFolder()

local function emitter(props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	e.EmissionDirection = Enum.NormalId.Bottom
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = emitterPart
	return e
end

local EMITTERS: { [string]: ParticleEmitter } = {
	Rain = emitter({
		Rate = 400, Lifetime = NumberRange.new(1, 1.4), Speed = NumberRange.new(70, 90),
		Size = NumberSequence.new(0.12), Squash = NumberSequence.new(-3), Transparency = NumberSequence.new(0.3),
		Color = ColorSequence.new(rgb(190, 210, 240)), Orientation = Enum.ParticleOrientation.VelocityParallel,
	}),
	DiamondStorm = emitter({
		Rate = 120, Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(8, 15), SpreadAngle = Vector2.new(30, 30),
		Size = NumberSequence.new(0.35), LightEmission = 1, Color = ColorSequence.new(rgb(150, 240, 255), rgb(255, 255, 255)),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-180, 180),
	}),
	CelestialStorm = emitter({
		Rate = 60, Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(40, 40),
		Size = NumberSequence.new(0.3), LightEmission = 1, Color = ColorSequence.new(rgb(255, 230, 140)),
	}),
	HuecoVoid = emitter({
		Rate = 50, Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(-3, 3), SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new(0.8, 0), LightEmission = 0.6, Color = ColorSequence.new(rgb(170, 60, 255), rgb(20, 0, 40)),
		Acceleration = Vector3.new(0, 4, 0),
	}),
	EtherealFog = emitter({
		Rate = 25, Lifetime = NumberRange.new(6, 9), Speed = NumberRange.new(1, 2), SpreadAngle = Vector2.new(180, 180),
		Size = NumberSequence.new(0.4), LightEmission = 1, Transparency = NumberSequence.new(0.4),
		Color = ColorSequence.new(rgb(230, 210, 255)),
	}),
}

-- Hueco Void: floating debris and reality cracks around the player.
local voidProps: { BasePart } = {}
local function setVoidProps(active: boolean, around: Vector3?)
	if active and #voidProps == 0 and around then
		local rng = Random.new()
		for i = 1, 24 do
			local p = Instance.new("Part")
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CastShadow = false
			if i % 3 == 0 then
				p.Size = Vector3.new(0.3, rng:NextNumber(8, 20), 0.3)
				p.Material = Enum.Material.Neon
				p.Color = rgb(190, 90, 255)
			else
				local s = rng:NextNumber(2, 6)
				p.Size = Vector3.new(s, s, s)
				p.Material = Enum.Material.Basalt
				p.Color = rgb(25, 15, 35)
			end
			p.CFrame = CFrame.new(around + Vector3.new(rng:NextNumber(-70, 70), rng:NextNumber(10, 45), rng:NextNumber(-70, 70)))
				* CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6))
			p:SetAttribute("Spin", rng:NextNumber(-0.6, 0.6))
			p.Parent = Water.fxFolder()
			table.insert(voidProps, p)
		end
	elseif not active and #voidProps > 0 then
		for _, p in voidProps do
			p:Destroy()
		end
		table.clear(voidProps)
	end
end

-- Easing -------------------------------------------------------------------------

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Shortest path around the 24h clock.
local function lerpClock(a: number, b: number, t: number): number
	local diff = (b - a + 12) % 24 - 12
	return (a + diff * t) % 24
end

local lightningTimer = 0
local glitchTimer = 0

function Atmosphere.start()
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5
	local terrain = workspace.Terrain
	terrain.WaterWaveSize = 0.15
	terrain.WaterTransparency = 0.6
	terrain.WaterReflectance = 0.4

	local rng = Random.new()
	local islandId: string? = nil
	local islandCheck = 0

	RunService.RenderStepped:Connect(function(dt)
		islandCheck -= dt
		if islandCheck <= 0 then
			islandCheck = 0.5
			islandId = LocalCharacter.island()
		end
		local weatherId = Clock.weather()
		local look = lookFor(weatherId, islandId)
		local t = math.min(1, dt * 1.5)

		Lighting.ClockTime = lerpClock(Lighting.ClockTime, look.clock or Clock.hour(), t)
		cc.TintColor = cc.TintColor:Lerp(look.tint, t)
		cc.Saturation = lerpNumber(cc.Saturation, look.saturation, t)
		cc.Contrast = lerpNumber(cc.Contrast, look.contrast, t)
		cc.Brightness = lerpNumber(cc.Brightness, look.brightness, t)
		atmo.Density = lerpNumber(atmo.Density, look.density, t)
		atmo.Haze = lerpNumber(atmo.Haze, look.haze, t)
		atmo.Color = atmo.Color:Lerp(look.atmoColor, t)
		atmo.Decay = atmo.Color
		terrain.WaterColor = terrain.WaterColor:Lerp(look.water, t)
		Lighting.Ambient = Lighting.Ambient:Lerp(look.ambient, t)
		Lighting.OutdoorAmbient = Lighting.Ambient
		sky.MoonAngularSize = lerpNumber(sky.MoonAngularSize, look.moonSize, t)

		local camera = workspace.CurrentCamera
		if camera then
			emitterPart.Position = camera.CFrame.Position + Vector3.new(0, 40, 0)
		end
		for id, e in EMITTERS do
			e.Enabled = id == weatherId
		end

		-- Celestial Storm lightning flashes.
		flash.Brightness = lerpNumber(flash.Brightness, 0, math.min(1, dt * 6))
		if weatherId == "CelestialStorm" then
			lightningTimer -= dt
			if lightningTimer <= 0 then
				lightningTimer = rng:NextNumber(2, 7)
				flash.Brightness = 0.6
				flash.TintColor = rgb(255, 245, 210)
			end
		end

		-- ???: the world flickers.
		if weatherId == "Mystery" then
			glitchTimer -= dt
			if glitchTimer <= 0 then
				glitchTimer = rng:NextNumber(0.5, 4)
				flash.Brightness = rng:NextNumber(-0.5, 0.5)
				flash.TintColor = Color3.new(rng:NextNumber(), rng:NextNumber(), rng:NextNumber())
			end
		end

		local root = LocalCharacter.root()
		setVoidProps(weatherId == "HuecoVoid", root and root.Position)
		for _, p in voidProps do
			p.CFrame *= CFrame.Angles(0, (p:GetAttribute("Spin") :: number) * dt, 0)
		end
	end)
end

return Atmosphere
