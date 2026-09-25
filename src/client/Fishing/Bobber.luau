--!strict
-- A bobber on a line from a rod tip. Flies out in an arc, bobs on the water, plunges on a bite,
-- pulls taut while reeling. Used for the local player's line and everyone else's.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Water = require(ReplicatedStorage.Shared.Water)
local Emerge = require(script.Parent.Parent.Visuals.Emerge)

local Bobber = {}
Bobber.__index = Bobber

export type Bobber = typeof(setmetatable(
	{} :: {
		model: Model,
		target: Vector3,
		state: string, -- "flying" | "floating" | "bite" | "taut" | "gone"
		tip: Attachment?,
		lineStart: Attachment,
		lineEnd: Attachment,
		beam: Beam,
		mark: BillboardGui?,
		conn: RBXScriptConnection?,
	},
	Bobber
))

-- Beam control points follow each attachment's X axis; point both down so the slack sags.
local DOWN = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))

local function piece(model: Model, name: string, shape: Enum.PartType, size: Vector3, color: Color3, offset: Vector3): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = shape
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.CFrame = CFrame.new(offset)
	p.Parent = model
	return p
end

local function build(): Model
	local model = Instance.new("Model")
	model.Name = "Bobber"
	local red = Color3.fromRGB(235, 60, 70)
	model.PrimaryPart = piece(model, "Body", Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(245, 245, 245), Vector3.zero)
	piece(model, "Cap", Enum.PartType.Ball, Vector3.new(0.7, 0.7, 0.7), red, Vector3.new(0, 0.22, 0))
	piece(model, "Stick", Enum.PartType.Block, Vector3.new(0.12, 0.4, 0.12), red, Vector3.new(0, 0.62, 0))
	return model
end

function Bobber.new(tip: Attachment?, target: Vector3): Bobber
	local model = build()
	local lineStart = Instance.new("Attachment")
	lineStart.Name = "LineStart"
	lineStart.Parent = workspace.Terrain
	local lineEnd = Instance.new("Attachment")
	lineEnd.Name = "LineEnd"
	lineEnd.Parent = workspace.Terrain

	local beam = Instance.new("Beam")
	beam.Attachment0 = lineStart
	beam.Attachment1 = lineEnd
	beam.Width0 = 0.05
	beam.Width1 = 0.05
	beam.FaceCamera = true
	beam.Segments = 16
	beam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
	beam.Transparency = NumberSequence.new(0.15)
	beam.LightInfluence = 0.5
	beam.Parent = workspace.Terrain

	local from = if tip then tip.WorldPosition else target + Vector3.new(0, 6, 0)
	model:PivotTo(CFrame.new(from))
	model.Parent = Water.fxFolder()

	local self = setmetatable({
		model = model,
		target = target,
		state = "flying",
		tip = tip,
		lineStart = lineStart,
		lineEnd = lineEnd,
		beam = beam,
		mark = nil,
		conn = nil,
	}, Bobber)

	local distance = (target - from).Magnitude
	local flight = 0.35 + distance / 90
	local arc = 3 + distance * 0.22
	local t0 = os.clock()
	local landedAt = 0
	self.conn = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		local position: Vector3
		local slack = 0
		if self.state == "flying" then
			local a = math.min(1, (now - t0) / flight)
			position = from:Lerp(target, a) + Vector3.new(0, math.sin(a * math.pi) * arc, 0)
			if a >= 1 then
				self.state = "floating"
				landedAt = now
				Emerge.splash(target, nil, 12)
			end
			slack = 0.5
		elseif self.state == "floating" then
			local t = now - landedAt
			position = target + Vector3.new(0, math.sin(t * 2.5) * 0.1 - 0.1, 0)
			slack = math.min(8, distance * 0.15)
		elseif self.state == "bite" then
			local t = now - landedAt
			position = target + Vector3.new(math.sin(t * 31) * 0.12, -0.6 + math.sin(t * 17) * 0.25, math.cos(t * 23) * 0.12)
			slack = 1
		else -- taut
			local t = now - landedAt
			position = target + Vector3.new(math.sin(t * 40) * 0.2, -0.45 + math.sin(t * 25) * 0.15, math.cos(t * 33) * 0.2)
			slack = 0
		end
		model:PivotTo(CFrame.new(position))

		local tipNow = self.tip
		if tipNow and tipNow.Parent then
			lineStart.WorldCFrame = CFrame.new(tipNow.WorldPosition) * DOWN
			beam.Enabled = true
		else
			beam.Enabled = false
		end
		lineEnd.WorldCFrame = CFrame.new(position + Vector3.new(0, 0.7, 0)) * DOWN
		beam.CurveSize0 = slack
		beam.CurveSize1 = -slack
	end)
	return self
end

function Bobber.position(self: Bobber): Vector3
	return self.target
end

function Bobber.bite(self: Bobber)
	if self.state == "gone" then
		return
	end
	self.state = "bite"
	Emerge.splash(self.target, nil, 18)
	local mark = Instance.new("BillboardGui")
	mark.Size = UDim2.fromOffset(60, 60)
	mark.StudsOffset = Vector3.new(0, 3, 0)
	mark.AlwaysOnTop = true
	mark.LightInfluence = 0
	mark.Adornee = self.model.PrimaryPart
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	text.TextScaled = true
	text.Text = "!"
	text.TextColor3 = Color3.fromRGB(255, 220, 80)
	text.TextStrokeTransparency = 0
	text.Parent = mark
	mark.Parent = self.model
	self.mark = mark
end

function Bobber.taut(self: Bobber)
	if self.state == "gone" then
		return
	end
	self.state = "taut"
	if self.mark then
		self.mark:Destroy()
		self.mark = nil
	end
end

-- A little splash on every shake.
function Bobber.shake(self: Bobber)
	Emerge.splash(self.target, nil, 6)
end

function Bobber.destroy(self: Bobber)
	self.state = "gone"
	if self.conn then
		self.conn:Disconnect()
		self.conn = nil
	end
	self.model:Destroy()
	self.beam:Destroy()
	self.lineStart:Destroy()
	self.lineEnd:Destroy()
end

-- Reels the bobber back to the rod tip, then removes it.
function Bobber.reelIn(self: Bobber)
	if self.state == "gone" then
		return
	end
	if self.conn then
		self.conn:Disconnect()
		self.conn = nil
	end
	self.state = "gone"
	local from = self.model:GetPivot().Position
	local tip = self.tip
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.min(1, (os.clock() - t0) / 0.3)
		local to = if tip and tip.Parent then tip.WorldPosition else from
		local p = from:Lerp(to, a) + Vector3.new(0, math.sin(a * math.pi) * 2, 0)
		self.model:PivotTo(CFrame.new(p))
		if tip and tip.Parent then
			self.lineStart.WorldCFrame = CFrame.new(tip.WorldPosition) * DOWN
		end
		self.lineEnd.WorldCFrame = CFrame.new(p) * DOWN
		self.beam.CurveSize0 = 0
		self.beam.CurveSize1 = 0
		if a >= 1 then
			conn:Disconnect()
			self:destroy()
		end
	end)
end

return Bobber
