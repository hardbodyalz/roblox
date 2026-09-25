--!strict
-- Builds a rod as a Tool from its config colours: cork grip, reel, tapered blank, line guides
-- and a "Tip" attachment the fishing line hangs from. Better rods glow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Equipment = require(ReplicatedStorage.Shared.Config.Equipment)

local RodModel = {}

local CORK = Color3.fromRGB(176, 132, 88)
local LENGTH = 8.2 -- handle centre to tip, along -Z
local GLOW_LUCK = 70 -- rods with at least this much Luck get a glowing tip

local function piece(tool: Tool, handle: BasePart, name: string, offset: CFrame, size: Vector3, color: Color3, shape: Enum.PartType?, material: Enum.Material?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape or Enum.PartType.Block
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = tool
	return p
end

function RodModel.build(rod: Equipment.Rod): Tool
	local tool = Instance.new("Tool")
	tool.Name = rod.name
	tool.ToolTip = rod.name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("Rod", rod.id)
	-- The tool's -Z points out of the hand; tilt it up so the rod is held at an angle.
	tool.Grip = (CFrame.Angles(math.rad(35), 0, 0) * CFrame.new(0, 0, -0.35)):Inverse()

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.34, 0.34, 1.7)
	handle.Color = CORK
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	-- Butt cap and reel
	piece(tool, handle, "Cap", CFrame.new(0, 0, 0.9), Vector3.new(0.42, 0.42, 0.42), rod.accent, Enum.PartType.Ball)
	piece(tool, handle, "Reel", CFrame.new(0, -0.42, 0.15), Vector3.new(0.45, 0.72, 0.72), rod.accent, Enum.PartType.Cylinder, Enum.Material.Metal)
	piece(tool, handle, "ReelFoot", CFrame.new(0, -0.2, 0.15), Vector3.new(0.12, 0.25, 0.3), rod.accent, nil, Enum.Material.Metal)
	piece(tool, handle, "ReelKnob", CFrame.new(0.3, -0.55, 0.15), Vector3.new(0.18, 0.18, 0.18), rod.color, Enum.PartType.Ball)

	-- Blank, tapering toward the tip
	local sections = {
		{ from = 0.85, to = 3.6, thick = 0.22 },
		{ from = 3.6, to = 6.3, thick = 0.15 },
		{ from = 6.3, to = LENGTH, thick = 0.09 },
	}
	for i, s in sections do
		local len = s.to - s.from
		piece(tool, handle, "Blank" .. i, CFrame.new(0, 0, -(s.from + len / 2)), Vector3.new(s.thick, s.thick, len), rod.color, nil, Enum.Material.SmoothPlastic)
		-- Accent wrap where sections join
		piece(tool, handle, "Wrap" .. i, CFrame.new(0, 0, -s.from), Vector3.new(s.thick + 0.08, s.thick + 0.08, 0.18), rod.accent)
	end
	for _, z in { 2.2, 4.2, 5.8, 7.3 } do
		piece(tool, handle, "Guide", CFrame.new(0, 0.13, -z), Vector3.new(0.14, 0.14, 0.14), rod.accent, Enum.PartType.Ball, Enum.Material.Metal)
	end

	local tip = Instance.new("Attachment")
	tip.Name = "Tip"
	tip.Position = Vector3.new(0, 0, -LENGTH)
	tip.Parent = handle

	if rod.luck >= GLOW_LUCK then
		local light = Instance.new("PointLight")
		light.Color = rod.accent
		light.Range = 6
		light.Brightness = 1.5
		light.Parent = tip
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Rate = 8
		sparkle.Lifetime = NumberRange.new(0.6, 1.2)
		sparkle.Speed = NumberRange.new(0.5, 1.5)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new(0.25, 0)
		sparkle.LightEmission = 1
		sparkle.Color = ColorSequence.new(rod.accent)
		sparkle.Parent = tip
	end

	return tool
end

return RodModel
