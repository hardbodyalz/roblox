--!strict
-- Procedurally builds the ocean and every island from Islands.luau, so the map always matches
-- the hotspots in config. This is placeholder art: swap any island for a hand-built model later by
-- keeping spot positions the same (Islands.spotPosition) and tagging pond water with the "Water"
-- attribute so casts can land in it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Islands = require(ReplicatedStorage.Shared.Config.Islands)

local Builder = {}

type Island = Islands.Island

local rgb = Color3.fromRGB
local GROUND_Y = 3 -- top of island ground at sea level islands

type Palette = {
	sand: Color3,
	ground: Color3,
	groundMaterial: Enum.Material,
	trunk: Color3,
	leaves: { Color3 },
	accent: Color3,
	wall: Color3,
	roof: Color3,
	stone: Color3,
	pond: Color3,
	marker: Color3,
}

local PALETTES: { [string]: Palette } = {
	sakura = {
		sand = rgb(240, 222, 175), ground = rgb(116, 170, 88), groundMaterial = Enum.Material.Grass,
		trunk = rgb(95, 60, 45), leaves = { rgb(255, 183, 210), rgb(255, 160, 195), rgb(255, 205, 225) },
		accent = rgb(210, 45, 40), wall = rgb(235, 225, 205), roof = rgb(70, 75, 95), stone = rgb(150, 150, 145),
		pond = rgb(90, 170, 210), marker = rgb(255, 150, 200),
	},
	oni = {
		sand = rgb(45, 40, 45), ground = rgb(75, 38, 35), groundMaterial = Enum.Material.Ground,
		trunk = rgb(30, 25, 25), leaves = { rgb(170, 30, 30), rgb(120, 20, 25), rgb(200, 70, 40) },
		accent = rgb(200, 25, 25), wall = rgb(60, 45, 45), roof = rgb(25, 20, 22), stone = rgb(70, 65, 68),
		pond = rgb(220, 80, 40), marker = rgb(255, 80, 60),
	},
	moonlit = {
		sand = rgb(110, 110, 120), ground = rgb(45, 60, 55), groundMaterial = Enum.Material.Grass,
		trunk = rgb(40, 35, 40), leaves = { rgb(40, 55, 60), rgb(55, 45, 75), rgb(35, 45, 50) },
		accent = rgb(120, 90, 180), wall = rgb(75, 70, 85), roof = rgb(35, 30, 50), stone = rgb(110, 110, 120),
		pond = rgb(60, 80, 140), marker = rgb(160, 140, 255),
	},
	celestial = {
		sand = rgb(245, 245, 250), ground = rgb(235, 238, 245), groundMaterial = Enum.Material.Marble,
		trunk = rgb(230, 210, 150), leaves = { rgb(255, 250, 230), rgb(255, 235, 170), rgb(240, 245, 255) },
		accent = rgb(255, 205, 80), wall = rgb(250, 248, 240), roof = rgb(255, 210, 90), stone = rgb(235, 235, 240),
		pond = rgb(150, 220, 255), marker = rgb(255, 225, 120),
	},
	academy = {
		sand = rgb(220, 210, 190), ground = rgb(95, 145, 85), groundMaterial = Enum.Material.Grass,
		trunk = rgb(90, 60, 45), leaves = { rgb(80, 130, 70), rgb(255, 183, 210), rgb(95, 150, 80) },
		accent = rgb(140, 20, 35), wall = rgb(225, 215, 200), roof = rgb(120, 25, 35), stone = rgb(160, 155, 150),
		pond = rgb(80, 160, 220), marker = rgb(255, 90, 110),
	},
}

local function part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

-- Vertical cylinder whose top face sits at topY.
local function disk(parent: Instance, center: Vector3, radius: number, height: number, topY: number, color: Color3, material: Enum.Material?): Part
	return part(parent, {
		Name = "Disk",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, radius * 2, radius * 2),
		CFrame = CFrame.new(center.X, topY - height / 2, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function ball(parent: Instance, position: Vector3, size: number, color: Color3, material: Enum.Material?): Part
	return part(parent, {
		Name = "Ball",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(size, size, size),
		Position = position,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function block(parent: Instance, cf: CFrame, size: Vector3, color: Color3, material: Enum.Material?): Part
	return part(parent, {
		Name = "Block",
		Size = size,
		CFrame = cf,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function label(parent: BasePart, text: string, color: Color3, offset: number, maxDistance: number?)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 50)
	gui.StudsOffset = Vector3.new(0, offset, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = maxDistance or 160
	gui.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.FontFace = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Heavy)
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Text = text
	t.Parent = gui
	gui.Parent = parent
end

-- Props ---------------------------------------------------------------------------

local function tree(parent: Instance, base: Vector3, pal: Palette, rng: Random, scale: number?)
	local s = (scale or 1) * rng:NextNumber(0.8, 1.3)
	local height = 14 * s
	block(parent, CFrame.new(base + Vector3.new(0, height / 2, 0)), Vector3.new(2, height, 2) * Vector3.new(s, 1, s), pal.trunk, Enum.Material.Wood)
	for _ = 1, 3 do
		local offset = Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-1, 3), rng:NextNumber(-3, 3)) * s
		ball(parent, base + Vector3.new(0, height, 0) + offset, rng:NextNumber(8, 12) * s, pal.leaves[rng:NextInteger(1, #pal.leaves)], Enum.Material.Grass)
	end
end

local function torii(parent: Instance, base: Vector3, facing: number, color: Color3, scale: number?)
	local s = scale or 1
	local cf = CFrame.new(base) * CFrame.Angles(0, facing, 0)
	for _, x in { -6 * s, 6 * s } do
		block(parent, cf * CFrame.new(x, 8 * s, 0), Vector3.new(1.4, 16, 1.4) * s, color)
	end
	block(parent, cf * CFrame.new(0, 16.5 * s, 0), Vector3.new(17, 1.4, 2) * s, color)
	block(parent, cf * CFrame.new(0, 13.5 * s, 0), Vector3.new(14, 1, 1.2) * s, color)
	block(parent, cf * CFrame.new(0, 17.6 * s, 0), Vector3.new(19, 0.8, 2.4) * s, rgb(30, 25, 25))
end

local function house(parent: Instance, base: Vector3, facing: number, pal: Palette, rng: Random, tall: boolean?)
	local w, d = rng:NextNumber(12, 18), rng:NextNumber(12, 16)
	local h = if tall then rng:NextNumber(16, 24) else rng:NextNumber(9, 12)
	local cf = CFrame.new(base) * CFrame.Angles(0, facing, 0)
	block(parent, cf * CFrame.new(0, h / 2, 0), Vector3.new(w, h, d), pal.wall, Enum.Material.WoodPlanks)
	-- Two wedges make a gabled roof.
	for _, side in { -1, 1 } do
		local wedge = part(parent, {
			Name = "Roof",
			Shape = Enum.PartType.Block,
			Size = Vector3.new(w + 2, 5, d / 2 + 1),
			Color = pal.roof,
		})
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Wedge
		mesh.Parent = wedge
		wedge.CFrame = cf * CFrame.new(0, h + 2.5, side * (d / 4 + 0.5)) * CFrame.Angles(0, if side > 0 then 0 else math.pi, 0)
	end
	block(parent, cf * CFrame.new(0, 3.5, -d / 2 - 0.1), Vector3.new(3, 7, 0.4), pal.trunk, Enum.Material.Wood)
end

local function lantern(parent: Instance, base: Vector3, color: Color3)
	block(parent, CFrame.new(base + Vector3.new(0, 3, 0)), Vector3.new(0.6, 6, 0.6), rgb(40, 35, 35))
	local glow = block(parent, CFrame.new(base + Vector3.new(0, 6.6, 0)), Vector3.new(1.6, 1.8, 1.6), color, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 1.2
	light.Parent = glow
end

local function dock(parent: Instance, island: Island, spot: Islands.Spot, pal: Palette)
	local a = math.rad(spot.angle)
	local dir = Vector3.new(math.cos(a), 0, math.sin(a))
	local startDist = island.radius - 12
	local endDist = spot.dist + 10
	local length = endDist - startDist
	local mid = island.center + dir * ((startDist + endDist) / 2)
	local cf = CFrame.lookAt(Vector3.new(mid.X, GROUND_Y - 0.5, mid.Z), Vector3.new(mid.X, GROUND_Y - 0.5, mid.Z) + dir)
	block(parent, cf, Vector3.new(10, 1, length), rgb(130, 95, 65), Enum.Material.WoodPlanks)
	-- Wider platform at the end where players fish.
	local tip = island.center + dir * spot.dist
	block(parent, CFrame.lookAt(Vector3.new(tip.X, GROUND_Y - 0.5, tip.Z), Vector3.new(tip.X, GROUND_Y - 0.5, tip.Z) + dir), Vector3.new(26, 1, 22), rgb(130, 95, 65), Enum.Material.WoodPlanks)
	for i = 0, math.floor(length / 12) do
		local p = island.center + dir * (startDist + i * 12)
		for _, side in { -1, 1 } do
			local right = dir:Cross(Vector3.yAxis) * side * 4.5
			block(parent, CFrame.new(p + right + Vector3.new(0, -6, 0)), Vector3.new(1.2, 18, 1.2), rgb(90, 65, 45), Enum.Material.Wood)
		end
	end
	for _, side in { -1, 1 } do
		lantern(parent, tip + dir:Cross(Vector3.yAxis) * side * 11 + Vector3.new(0, GROUND_Y, 0), pal.marker)
	end
end

local function pond(parent: Instance, center: Vector3, topY: number, pal: Palette)
	disk(parent, center, 17, 1.2, topY + 0.6, pal.stone, Enum.Material.Slate)
	local water = disk(parent, center, 15, 0.4, topY + 0.8, pal.pond, Enum.Material.Glass)
	water.Name = "PondWater"
	water.Transparency = 0.25
	water.Reflectance = 0.2
	water.CanCollide = false
	water:SetAttribute("Water", true)
end

-- A ring of buoys marks the patch of sea a pier's hotspot covers.
local function buoyRing(parent: Instance, center: Vector3, radius: number, pal: Palette)
	local count = 12
	for i = 1, count do
		local a = i / count * math.pi * 2
		local p = center + Vector3.new(math.cos(a) * radius, 0.3, math.sin(a) * radius)
		local buoy = ball(parent, p, 1.4, if i % 2 == 0 then rgb(245, 245, 245) else pal.marker)
		buoy.Name = "Buoy"
		buoy.CanCollide = false
		buoy.CanQuery = false -- casts pass through to the water
	end
end

local function spotMarker(parent: Instance, position: Vector3, radius: number, spot: Islands.Spot, pal: Palette)
	-- Invisible pad on the water: carries the label and emits a soft shimmer across the hotspot.
	local pad = part(parent, {
		Name = "Hotspot_" .. spot.id,
		Size = Vector3.new(radius * 1.6, 0.2, radius * 1.6),
		Position = position + Vector3.new(0, 0.4, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	pad:SetAttribute("SpotId", spot.id)
	label(pad, "🎣 " .. spot.name .. "\n" .. spot.blurb, pal.marker, 7, 160)
	local shimmer = Instance.new("ParticleEmitter")
	shimmer.Rate = 10
	shimmer.Lifetime = NumberRange.new(1.5, 2.5)
	shimmer.Speed = NumberRange.new(0.5, 1.5)
	shimmer.EmissionDirection = Enum.NormalId.Top
	shimmer.Size = NumberSequence.new(0.5, 0)
	shimmer.Color = ColorSequence.new(pal.marker)
	shimmer.LightEmission = 1
	shimmer.Parent = pad
end

-- Island landmarks ---------------------------------------------------------------

local function lighthouse(parent: Instance, base: Vector3)
	for i = 0, 5 do
		local color = if i % 2 == 0 then rgb(240, 240, 240) else rgb(210, 50, 50)
		disk(parent, base, 7 - i * 0.5, 8, base.Y + (i + 1) * 8, color)
	end
	local lamp = ball(parent, base + Vector3.new(0, 52, 0), 6, rgb(255, 245, 180), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 60
	light.Brightness = 2
	light.Color = rgb(255, 240, 190)
	light.Parent = lamp
end

local function volcano(parent: Instance, base: Vector3, pal: Palette)
	for i = 0, 6 do
		disk(parent, base, 40 - i * 5, 8, base.Y + (i + 1) * 8, pal.sand, Enum.Material.Basalt)
	end
	local lava = disk(parent, base, 8, 1, base.Y + 57, rgb(255, 110, 30), Enum.Material.Neon)
	local fire = Instance.new("Fire")
	fire.Size = 25
	fire.Heat = 20
	fire.Color = rgb(255, 90, 30)
	fire.SecondaryColor = rgb(255, 200, 60)
	fire.Parent = lava
end

local function castle(parent: Instance, base: Vector3, pal: Palette)
	block(parent, CFrame.new(base + Vector3.new(0, 14, 0)), Vector3.new(40, 28, 30), pal.wall, Enum.Material.Cobblestone)
	for _, corner in { Vector3.new(-20, 0, -15), Vector3.new(20, 0, -15), Vector3.new(-20, 0, 15), Vector3.new(20, 0, 15) } do
		local p = base + corner
		disk(parent, p, 6, 42, p.Y + 42, pal.wall, Enum.Material.Cobblestone)
		disk(parent, p, 7, 3, p.Y + 45, pal.roof, Enum.Material.Slate)
		local window = block(parent, CFrame.new(p + Vector3.new(0, 36, -6.1)), Vector3.new(2, 3, 0.4), rgb(255, 210, 120), Enum.Material.Neon)
		window.Name = "Window"
	end
end

local function temple(parent: Instance, base: Vector3, pal: Palette)
	disk(parent, base, 26, 3, base.Y + 3, pal.stone, Enum.Material.Marble)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		local p = base + Vector3.new(math.cos(a) * 20, 0, math.sin(a) * 20)
		disk(parent, p, 1.8, 22, base.Y + 25, pal.wall, Enum.Material.Marble)
	end
	disk(parent, base, 24, 2, base.Y + 27, pal.accent, Enum.Material.Foil)
	local halo = ball(parent, base + Vector3.new(0, 40, 0), 10, pal.accent, Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 50
	light.Color = pal.accent
	light.Parent = halo
end

local function school(parent: Instance, base: Vector3, pal: Palette)
	block(parent, CFrame.new(base + Vector3.new(0, 16, 0)), Vector3.new(70, 32, 22), pal.wall, Enum.Material.Concrete)
	block(parent, CFrame.new(base + Vector3.new(0, 32.5, 0)), Vector3.new(72, 1.5, 24), pal.roof)
	block(parent, CFrame.new(base + Vector3.new(0, 30, -11.2)), Vector3.new(10, 10, 0.5), rgb(250, 240, 220))
	local clock = block(parent, CFrame.new(base + Vector3.new(0, 30, -11.6)), Vector3.new(6, 6, 0.4), rgb(40, 30, 30))
	clock.Name = "Clock"
	for floor = 0, 2 do
		for col = -3, 3 do
			local w = block(parent, CFrame.new(base + Vector3.new(col * 9, 6 + floor * 9, -11.2)), Vector3.new(5, 4, 0.4), rgb(150, 200, 230), Enum.Material.Glass)
			w.Transparency = 0.2
		end
	end
	label(clock, "DEMON ACADEMY", pal.accent, 6, 250)
end

local function sakuraTree(parent: Instance, base: Vector3, pal: Palette, rng: Random)
	tree(parent, base, pal, rng, 2.4)
	local petals = Instance.new("ParticleEmitter")
	petals.Rate = 8
	petals.Lifetime = NumberRange.new(5, 8)
	petals.Speed = NumberRange.new(1, 3)
	petals.Acceleration = Vector3.new(1, -1.5, 0.5)
	petals.Size = NumberSequence.new(0.5)
	petals.Color = ColorSequence.new(pal.leaves[1])
	petals.Rotation = NumberRange.new(0, 360)
	petals.RotSpeed = NumberRange.new(-90, 90)
	local emitter = part(parent, { Name = "Petals", Size = Vector3.new(30, 1, 30), Position = base + Vector3.new(0, 38, 0), Transparency = 1, CanCollide = false, CanQuery = false })
	petals.Parent = emitter
end

-- Island -------------------------------------------------------------------------

local function inClearZone(island: Island, position: Vector3): boolean
	local offset = position - island.center
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude < 34 then
		return false -- landmark
	end
	local angle = math.deg(math.atan2(flat.Z, flat.X)) % 360
	for _, spot in island.spots do
		local sp = Islands.spotPosition(island, spot)
		if spot.kind == "pond" and (Vector3.new(sp.X, 0, sp.Z) - Vector3.new(position.X, 0, position.Z)).Magnitude < 28 then
			return false
		end
		if spot.kind == "dock" then
			local diff = math.abs((angle - spot.angle + 180) % 360 - 180)
			if diff < 12 then
				return false
			end
		end
	end
	return true
end

local function buildIsland(island: Island, parent: Instance)
	local pal = PALETTES[island.theme]
	local rng = Random.new(island.order * 1000)
	local model = Instance.new("Model")
	model.Name = island.name
	local c = island.center
	local topY = c.Y + GROUND_Y
	local floating = island.theme == "celestial"

	if floating then
		disk(model, c, island.radius, 16, topY, pal.ground, pal.groundMaterial)
		for _ = 1, 26 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(0, island.radius)
			local cloud = ball(model, c + Vector3.new(math.cos(a) * r, rng:NextNumber(-40, -12), math.sin(a) * r), rng:NextNumber(25, 55), rgb(255, 255, 255), Enum.Material.SmoothPlastic)
			cloud.Transparency = 0.25
			cloud.CanCollide = false
			cloud.CanQuery = false
		end
	else
		disk(model, c, island.radius, 30, topY - 1.5, pal.sand, Enum.Material.Sand)
		disk(model, c, island.radius - 18, 3, topY, pal.ground, pal.groundMaterial)
		local hills = 0
		for _ = 1, 60 do
			local a = rng:NextNumber(0, math.pi * 2)
			local r = rng:NextNumber(50, island.radius - 45)
			local pos = Vector3.new(c.X + math.cos(a) * r, topY - 14, c.Z + math.sin(a) * r)
			if hills < 5 and inClearZone(island, pos) then
				hills += 1
				local hill = ball(model, pos, rng:NextNumber(30, 42), pal.ground, pal.groundMaterial)
				hill.Name = "Hill"
			end
		end
	end

	-- Landmark at the centre.
	local centre = Vector3.new(c.X, topY, c.Z)
	if island.theme == "sakura" then
		sakuraTree(model, centre, pal, rng)
		local shrinePos = Islands.spotPosition(island, island.spots[2])
		torii(model, Vector3.new(shrinePos.X, topY, shrinePos.Z) + (c - shrinePos).Unit * 24, math.rad(-island.spots[2].angle + 90), pal.accent)
		local lhSpot = island.spots[3]
		local la = math.rad(lhSpot.angle + 14)
		lighthouse(model, Vector3.new(c.X + math.cos(la) * (island.radius - 26), topY, c.Z + math.sin(la) * (island.radius - 26)))
	elseif island.theme == "oni" then
		volcano(model, centre, pal)
	elseif island.theme == "moonlit" then
		castle(model, centre, pal)
	elseif island.theme == "celestial" then
		temple(model, centre, pal)
	elseif island.theme == "academy" then
		school(model, centre, pal)
	end

	-- Scatter houses, trees, torii and lanterns.
	local placed = 0
	for _ = 1, 400 do
		if placed >= 34 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(38, island.radius - 26)
		local pos = Vector3.new(c.X + math.cos(a) * r, topY, c.Z + math.sin(a) * r)
		if inClearZone(island, pos) then
			placed += 1
			local theme: string = island.theme
			local roll = rng:NextNumber()
			local facing = -a + math.pi / 2
			local canHouse = roll < 0.28 and theme ~= "celestial"
			if canHouse then
				house(model, pos, facing, pal, rng, theme == "moonlit" or theme == "academy")
			elseif roll < 0.8 then
				tree(model, pos, pal, rng)
			elseif roll < 0.9 and (theme == "sakura" or theme == "oni") then
				torii(model, pos, facing, pal.accent, 0.7)
			elseif theme == "moonlit" then
				-- gravestones
				for i = 1, 4 do
					block(model, CFrame.new(pos + Vector3.new(i * 4 - 10, 2, 0)) * CFrame.Angles(0, 0, math.rad(rng:NextNumber(-8, 8))), Vector3.new(2.5, 4, 0.8), pal.stone, Enum.Material.Slate)
				end
			else
				lantern(model, pos, pal.marker)
			end
		end
	end

	for _, spot in island.spots do
		local sp = Islands.spotPosition(island, spot)
		local hotspot = Islands.hotspotCenter(island, spot)
		local radius = Islands.hotspotRadius(spot)
		if spot.kind == "dock" then
			dock(model, island, spot, pal)
			buoyRing(model, Vector3.new(hotspot.X, c.Y, hotspot.Z), radius, pal)
			spotMarker(model, Vector3.new(hotspot.X, c.Y, hotspot.Z), radius, spot, pal)
		else
			pond(model, Vector3.new(sp.X, 0, sp.Z), topY, pal)
			spotMarker(model, Vector3.new(sp.X, topY + 0.8, sp.Z), radius, spot, pal)
		end
	end

	-- Island name sign at the arrival point.
	local arrival = Islands.arrivalPosition(island)
	local sign = block(model, CFrame.new(arrival + Vector3.new(0, GROUND_Y + 10, 0)), Vector3.new(1, 1, 1), pal.accent)
	sign.Transparency = 1
	sign.CanCollide = false
	label(sign, island.name, pal.marker, 0, 250)

	model.Parent = parent
	return model
end

local function buildNpc(parent: Instance, position: Vector3, facing: Vector3, name: string)
	local model = Instance.new("Model")
	model.Name = name
	local cf = CFrame.lookAt(position, Vector3.new(facing.X, position.Y, facing.Z))
	block(model, cf * CFrame.new(0, 1.5, 0), Vector3.new(2, 3, 1), rgb(60, 70, 110))
	block(model, cf * CFrame.new(0, 4.5, 0), Vector3.new(3, 3, 1.5), rgb(230, 230, 240))
	local head = ball(model, (cf * CFrame.new(0, 7, 0)).Position, 2.4, rgb(255, 220, 190))
	block(model, cf * CFrame.new(0, 8.3, 0), Vector3.new(3, 0.6, 3), rgb(40, 40, 60))
	label(head, name, rgb(255, 255, 255), 3, 80)
	model.Parent = parent
end

function Builder.build()
	local world = Instance.new("Folder")
	world.Name = "World"

	-- Ocean: terrain water from y = -30 to 0 with a sand floor beneath.
	local terrain = workspace.Terrain
	local oceanCenter = CFrame.new(0, -15, -250)
	local oceanSize = Vector3.new(2400, 30, 2600)
	terrain:FillBlock(oceanCenter, oceanSize, Enum.Material.Water)
	terrain:FillBlock(oceanCenter * CFrame.new(0, -19, 0), Vector3.new(oceanSize.X, 8, oceanSize.Z), Enum.Material.Sand)

	for _, island in Islands.list do
		buildIsland(island, world)
	end

	-- Spawn on Sakura Shore, next to the Harbourmaster.
	local sakura = Islands.byId.sakura_shore
	local arrival = Islands.arrivalPosition(sakura)
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = arrival + Vector3.new(0, GROUND_Y + 0.5, 0)
	spawn.Color = rgb(255, 183, 210)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = world
	buildNpc(world, arrival + Vector3.new(-10, GROUND_Y + 1, 8), sakura.center, "Harbourmaster Kaito")

	world.Parent = workspace
end

return Builder
