--!strict
-- A 3D Waifu built from parts, coloured from her config and re-tinted by mutation, with a few
-- accessories picked from her tags (ears, horns, halo and wings, witch hat, cape...). Like the
-- portrait, this is placeholder art: swap in a real rig by returning it from build().
--
-- The model's pivot is at her feet, facing -Z.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Appearance = require(Shared.Appearance)
local Format = require(Shared.Format)

local WaifuModel = {}

local HEIGHT = 6 -- studs at scale 1
local rgb = Color3.fromRGB

local function darker(c: Color3, amount: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), amount)
end

type Builder = (name: string, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?) -> Part

local function accessories(add: Builder, tags: { string }, hair: Color3, outfit: Color3)
	local function has(tag: string): boolean
		return table.find(tags, tag) ~= nil
	end
	local Block, Ball, Cyl = Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder
	local upright = CFrame.Angles(0, 0, math.rad(90)) -- cylinders stand on end

	if has("cat") or has("fox") then
		for _, side in { -1, 1 } do
			add("Ear", Block, Vector3.new(0.5, 0.5, 0.18), CFrame.new(side * 0.52, 5.45, 0.05) * CFrame.Angles(0, 0, math.rad(45)), hair)
			add("EarInner", Block, Vector3.new(0.28, 0.28, 0.2), CFrame.new(side * 0.52, 5.42, 0.02) * CFrame.Angles(0, 0, math.rad(45)), rgb(255, 190, 200))
		end
	end
	if has("fox") then
		add("Tail", Ball, Vector3.new(1, 1, 1), CFrame.new(0, 1.9, 0.9), hair)
		add("TailTip", Ball, Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 2.4, 1.3), rgb(255, 250, 245))
	end
	if has("demon") then
		for _, side in { -1, 1 } do
			add("Horn", Block, Vector3.new(0.18, 0.7, 0.18), CFrame.new(side * 0.45, 5.55, -0.2) * CFrame.Angles(0, 0, math.rad(-side * 22)), rgb(45, 20, 28))
		end
	end
	if has("celestial") then
		local halo = add("Halo", Cyl, Vector3.new(0.08, 1.3, 1.3), CFrame.new(0, 5.95, 0.1) * upright, rgb(255, 225, 120), Enum.Material.Neon)
		halo.Transparency = 0.15
		for _, side in { -1, 1 } do
			local wing = add("Wing", Block, Vector3.new(0.12, 1.8, 1.3), CFrame.new(side * 0.75, 3.6, 0.75) * CFrame.Angles(0, math.rad(side * 35), math.rad(-side * 20)), rgb(255, 255, 255), Enum.Material.SmoothPlastic)
			wing.Transparency = 0.1
		end
	end
	if has("witch") then
		add("HatBrim", Cyl, Vector3.new(0.1, 2.3, 2.3), CFrame.new(0, 5.35, 0.05) * upright, rgb(35, 25, 50))
		for i, r in { 1.1, 0.8, 0.5, 0.25 } do
			add("Hat", Cyl, Vector3.new(0.45, r, r), CFrame.new(0, 5.55 + i * 0.4, 0.05 + i * 0.05) * upright, rgb(35, 25, 50))
		end
	end
	if has("maid") then
		add("Headband", Block, Vector3.new(1.5, 0.18, 0.35), CFrame.new(0, 5.35, -0.15), rgb(250, 250, 250))
		add("Apron", Block, Vector3.new(0.9, 1.1, 0.1), CFrame.new(0, 2.4, -0.95), rgb(250, 250, 250))
	end
	if has("vampire") then
		add("Cape", Block, Vector3.new(1.7, 2.8, 0.12), CFrame.new(0, 2.5, 0.55) * CFrame.Angles(math.rad(-6), 0, 0), rgb(120, 10, 25))
	end
	if has("shrine") then
		add("Ribbon", Block, Vector3.new(0.7, 0.35, 0.2), CFrame.new(0, 4.9, 1.0), rgb(220, 40, 40))
	end
	if has("ice") then
		add("Snowflake", Block, Vector3.new(0.3, 0.3, 0.1), CFrame.new(0.55, 5.0, -0.55) * CFrame.Angles(0, 0, math.rad(45)), rgb(190, 235, 255), Enum.Material.Neon)
	end
	if has("school") then
		add("Bow", Block, Vector3.new(0.5, 0.25, 0.1), CFrame.new(0, 3.45, -0.4), darker(outfit, 0.3))
	end
end

-- Returns the model and her height in studs.
function WaifuModel.build(characterId: string, mutationId: string, kg: number): (Model, number)
	local character = Characters.byId[characterId]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[mutationId] or Mutations.byId.Normal
	local palette = Appearance.palette(characterId, mutationId)

	local model = Instance.new("Model")
	model.Name = character.name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	local parts: { BasePart } = {}
	local function add(name: string, shape: Enum.PartType, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?): Part
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		table.insert(parts, p)
		return p
	end
	local Block, Ball, Cyl = Enum.PartType.Block, Enum.PartType.Ball, Enum.PartType.Cylinder
	local upright = CFrame.Angles(0, 0, math.rad(90))

	local skin, hair, outfit, eyes = palette.skin, palette.hair, palette.outfit, palette.eyes

	-- Legs and shoes
	for _, side in { -1, 1 } do
		add("Leg", Block, Vector3.new(0.42, 1.9, 0.46), CFrame.new(side * 0.27, 1.0, 0), skin)
		add("Shoe", Block, Vector3.new(0.48, 0.3, 0.62), CFrame.new(side * 0.27, 0.15, -0.06), darker(outfit, 0.45))
	end
	-- Skirt, torso, sleeves, arms
	add("Skirt", Cyl, Vector3.new(0.95, 1.9, 1.9), CFrame.new(0, 2.05, 0) * upright, outfit)
	add("SkirtHem", Cyl, Vector3.new(0.12, 1.95, 1.95), CFrame.new(0, 1.62, 0) * upright, darker(outfit, 0.25))
	add("Torso", Block, Vector3.new(1.15, 1.3, 0.7), CFrame.new(0, 3.0, 0), outfit)
	for _, side in { -1, 1 } do
		local shoulder = CFrame.new(side * 0.78, 3.55, 0) * CFrame.Angles(0, 0, math.rad(side * 10))
		add("Sleeve", Block, Vector3.new(0.42, 0.6, 0.46), shoulder * CFrame.new(0, -0.2, 0), outfit)
		add("Arm", Block, Vector3.new(0.32, 1.5, 0.36), shoulder * CFrame.new(0, -0.75, 0), skin)
	end
	-- Head, face and hair
	add("Neck", Block, Vector3.new(0.3, 0.35, 0.3), CFrame.new(0, 3.75, 0), skin)
	add("Head", Ball, Vector3.new(1.7, 1.7, 1.7), CFrame.new(0, 4.55, 0), skin)
	add("Hair", Ball, Vector3.new(1.9, 1.9, 1.9), CFrame.new(0, 4.75, 0.12), hair)
	add("LongHair", Block, Vector3.new(1.5, 2.1, 0.4), CFrame.new(0, 3.75, 0.55), hair)
	for _, side in { -1, 1 } do
		add("Lock", Block, Vector3.new(0.3, 1.3, 0.35), CFrame.new(side * 0.78, 4.0, -0.25), hair)
		add("Eye", Ball, Vector3.new(0.34, 0.4, 0.34), CFrame.new(side * 0.3, 4.48, -0.76), eyes)
		add("Shine", Ball, Vector3.new(0.12, 0.12, 0.12), CFrame.new(side * 0.3 - 0.06, 4.56, -0.92), rgb(255, 255, 255), Enum.Material.Neon)
		add("Blush", Block, Vector3.new(0.22, 0.08, 0.05), CFrame.new(side * 0.5, 4.25, -0.72), rgb(255, 160, 170))
	end
	add("Mouth", Block, Vector3.new(0.2, 0.05, 0.05), CFrame.new(0, 4.12, -0.8), rgb(210, 90, 110))

	accessories(add, character.tags, hair, outfit)

	-- Rarity and mutation dressing
	if table.find(character.tags, "ghost") then
		for _, p in parts do
			p.Transparency = math.max(p.Transparency, 0.35)
		end
	end
	if mutation.id ~= "Normal" then
		local highlight = Instance.new("Highlight")
		highlight.FillColor = mutation.color
		highlight.FillTransparency = 0.8
		highlight.OutlineColor = mutation.color2
		highlight.OutlineTransparency = 0.2
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
		local aura = Instance.new("ParticleEmitter")
		aura.Name = "Aura"
		aura.Rate = 12 + mutation.order * 4
		aura.Lifetime = NumberRange.new(1, 2)
		aura.Speed = NumberRange.new(0.5, 2)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Size = NumberSequence.new(0.35, 0)
		aura.LightEmission = 1
		aura.Color = ColorSequence.new(mutation.color, mutation.color2)
		aura.Parent = model:FindFirstChild("Torso")
	end
	if rarity.order >= 5 then
		local light = Instance.new("PointLight")
		light.Color = rarity.color
		light.Range = 12
		light.Brightness = 2
		light.Parent = model:FindFirstChild("Torso")
	end

	-- Name tag
	local tag = Instance.new("BillboardGui")
	tag.Name = "Tag"
	tag.Size = UDim2.fromOffset(240, 54)
	tag.StudsOffset = Vector3.new(0, 1.2, 0)
	tag.LightInfluence = 0
	tag.MaxDistance = 120
	tag.Adornee = model:FindFirstChild("Head") :: BasePart
	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = rarity.color
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = character.name
	nameLabel.Parent = tag
	local subLabel = nameLabel:Clone()
	subLabel.Position = UDim2.fromScale(0, 0.6)
	subLabel.Size = UDim2.new(1, 0, 0.4, 0)
	subLabel.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
	subLabel.TextColor3 = if mutation.id == "Normal" then rgb(235, 235, 240) else mutation.color
	subLabel.Text = (if mutation.id == "Normal" then "" else mutation.name .. " · ") .. rarity.name .. " · " .. Format.kg(kg)
	subLabel.Parent = tag
	tag.Parent = model

	-- Heavier catches are a little bigger.
	local t = math.clamp((kg - character.kg[1]) / math.max(1, character.kg[2] - character.kg[1]), 0, 1)
	local scale = 0.85 + 0.35 * t
	model:ScaleTo(scale)

	return model, HEIGHT * scale
end

return WaifuModel
