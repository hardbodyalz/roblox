--!strict
-- Always-on HUD:
--   top centre     weather, time and live events
--   left           menu rail
--   bottom centre  rod hotbar slot, where you are, your Luck, and what to do next
--   bottom right   Yen and storage (plus a hold-to-cast button on touch screens)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Equipment = require(Config.Equipment)
local Islands = require(Config.Islands)
local Weather = require(Config.Weather)
local Clock = require(Shared.Clock)
local Format = require(Shared.Format)
local Modifiers = require(Shared.Modifiers)
local Storage = require(Shared.Storage)
local Zones = require(Shared.Zones)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local State = require(script.Parent.Parent.State)
local LocalCharacter = require(script.Parent.Parent.LocalCharacter)

local Hud = {}

local player = Players.LocalPlayer
local C = Kit.Colors
local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local WEATHER_ICON = {
	Sunny = "☀️", Rain = "🌧️", GoldenHour = "🌅", DiamondStorm = "💎", EtherealFog = "🌫️",
	CelestialStorm = "⚡", BloodMoon = "🌕", HuecoVoid = "🕳️", Mystery = "❔",
}

local gui = Kit.new("ScreenGui", {
	Name = "Hud",
	ResetOnSpawn = false,
	DisplayOrder = 1,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Bottom right: Yen and storage ----------------------------------------------------

local wallet = Kit.new("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -16),
	Size = UDim2.fromOffset(260, 60),
	BackgroundTransparency = 1,
	Parent = gui,
})
local yenLabel = Kit.hudLabel({ Text = "¥0", FontFace = Kit.Title, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(1, 0, 0, 36), Parent = wallet })
local storageLabel = Kit.hudLabel({ Text = "", TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 18), Parent = wallet })

-- Top centre: weather, time and events ----------------------------------------------

local envPill = Kit.panel({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(0, 32),
	AutomaticSize = Enum.AutomaticSize.X,
	Parent = gui,
}, { Kit.new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
;(envPill:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius = UDim.new(1, 0)
local envLabel = Kit.label({
	FontFace = Kit.Bold,
	TextSize = 15,
	TextWrapped = false,
	AutomaticSize = Enum.AutomaticSize.X,
	Size = UDim2.fromScale(0, 1),
	Parent = envPill,
})

-- Left: menu rail -----------------------------------------------------------------

local rail = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 12, 0.5, 0),
	Size = UDim2.fromOffset(56, 320),
	BackgroundTransparency = 1,
	Parent = gui,
}, { Kit.list(8) })
local MENU = {
	{ id = "Inventory", icon = "🎒", label = "Catches" },
	{ id = "Collection", icon = "📖", label = "Book" },
	{ id = "Shop", icon = "🛒", label = "Shop" },
	{ id = "Sail", icon = "⛵", label = "Sail" },
	{ id = "Achievements", icon = "🏆", label = "Goals" },
}
for i, m in MENU do
	local b = Kit.new("TextButton", {
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(56, 56),
		LayoutOrder = i,
		Parent = rail,
	}, { Kit.corner(8), Kit.stroke() })
	Kit.label({ Text = m.icon, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 30), Parent = b })
	Kit.label({ Text = m.label, FontFace = Kit.Bold, TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, 14), Parent = b })
	b.Activated:Connect(function()
		Window.open(m.id)
	end)
end

-- Bottom centre: status lines and the rod slot ---------------------------------------

local bottom = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -12),
	Size = UDim2.fromOffset(520, 150),
	BackgroundTransparency = 1,
	Parent = gui,
})
local zoneLabel = Kit.hudLabel({ FontFace = Kit.Title, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 22), Parent = bottom })
local statsLabel = Kit.hudLabel({ FontFace = Kit.Bold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 18), Parent = bottom })
local hintLabel = Kit.hudLabel({ FontFace = Kit.Bold, TextSize = 15, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 20), Parent = bottom })

local slot = Kit.new("TextButton", {
	Text = "",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 1),
	Size = UDim2.fromOffset(72, 72),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	AutoButtonColor = true,
	Parent = bottom,
}, { Kit.corner(8) })
local slotStroke = Kit.stroke()
slotStroke.Parent = slot
Kit.label({ Text = "1", FontFace = Kit.Bold, TextSize = 12, TextColor3 = C.muted, Position = UDim2.fromOffset(6, 3), Size = UDim2.fromOffset(12, 14), Parent = slot })
Kit.label({ Text = "🎣", TextSize = 26, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 8), Size = UDim2.new(1, 0, 0, 32), Parent = slot })
local slotName = Kit.label({ FontFace = Kit.Bold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 4, 1, -28), Size = UDim2.new(1, -8, 0, 26), Parent = slot })
slot.Activated:Connect(LocalCharacter.toggleRod)

-- Touch: hold-to-cast button.
local castButton = Kit.button("CAST", C.panel, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -96),
	Size = UDim2.fromOffset(96, 96),
	FontFace = Kit.Title,
	TextSize = 22,
	BackgroundTransparency = 0.2,
	Visible = false,
	Parent = gui,
})
;(castButton:FindFirstChildOfClass("UICorner") :: UICorner).CornerRadius = UDim.new(1, 0)

local status: string? = nil
local fishing: any = nil

function Hud.bindFishing(fishingModule: any)
	fishing = fishingModule
	fishing.onStatus(function(text)
		status = text
	end)
	castButton.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			fishing.beginCharge()
		end
	end)
	castButton.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			fishing.release()
		end
	end)
end

local function refreshWallet()
	local data = State.data
	if not data then
		return
	end
	yenLabel.Text = Format.yen(data.yen)
	local count = State.inventoryCount()
	local capacity = Storage.capacity(data.storageTier, data.boat, State.passes().InfiniteStorage == true)
	storageLabel.Text = string.format("🎒 %d / %s", count, if capacity == math.huge then "∞" else tostring(capacity))
	storageLabel.TextColor3 = if count >= capacity then C.bad else C.text
end

local function envText(): string
	local data = State.data
	local weatherId, ends = Clock.weather()
	local weather = Weather.byId[weatherId] or Weather.byId.Sunny
	local parts = {
		Kit.color(string.format("%s %s %s", WEATHER_ICON[weather.id] or "", weather.name, Format.clock(ends - Clock.now())), weather.color),
	}
	local islandId = LocalCharacter.island()
	local island = islandId and Islands.byId[islandId]
	local night = Clock.isNight() or (island ~= nil and island.permanentNight == true)
	table.insert(parts, if night then "🌙 " .. Clock.moonPhase() .. " Moon" else string.format("%02d:00", math.floor(Clock.hour())))
	local tide, tideLeft = Clock.demonTide()
	if tide then
		table.insert(parts, Kit.color("🔥 Demon Tide " .. Format.clock(tideLeft), C.bad))
	end
	if Clock.serverLuck() then
		table.insert(parts, Kit.color("🍀 10× Server Luck", C.good))
	end
	if data then
		for boost, until_ in data.boosts do
			if until_ > os.time() then
				table.insert(parts, Kit.color("2× " .. boost .. " " .. Format.clock(until_ - os.time()), C.good))
			end
		end
	end
	return table.concat(parts, Kit.color("   ·   ", C.muted))
end

-- The hotspot you're standing near, if your rod can reach it.
local function nearbyHotspot(position: Vector3, reach: number): Islands.Spot?
	local island = Islands.islandAt(position)
	if not island then
		return nil
	end
	for _, spot in island.spots do
		local center = Islands.hotspotCenter(island, spot)
		local flat = Vector3.new(position.X - center.X, 0, position.Z - center.Z).Magnitude
		if flat <= reach + Islands.hotspotRadius(spot) and math.abs(position.Y - center.Y) < 30 then
			return spot
		end
	end
	return nil
end

local function tick()
	envLabel.Text = envText()
	local data = State.data
	local root = LocalCharacter.root()
	if not data or not fishing or not root then
		return
	end

	local rod = Equipment.rodsById[data.rod] or Equipment.rodsById.old_rod
	local bait = Equipment.baitsById[data.baitEquipped] or Equipment.baitsById.normal
	local zone = Zones.at(root.Position)
	local hotspot = nearbyHotspot(root.Position, rod.castRange)

	zoneLabel.Text = if hotspot then "🎣 " .. hotspot.name .. Kit.color("  " .. hotspot.blurb, C.gold) else Zones.describe(zone)

	local perks = Modifiers.perksFrom(State.passes(), data.boosts, data.collectorEnds, os.time())
	local loadout = { rod = data.rod, boat = data.boat, bait = data.baitEquipped }
	local mods = Modifiers.compute(loadout, Zones.cast(zone, false), Clock.env(), perks)
	local baitCount = if bait.id == "normal" then "" else " ×" .. (data.bait[bait.id] or 0)
	statsLabel.Text = string.format(
		"%s   %s   %s",
		Kit.color("Luck " .. math.floor(mods.luck), C.good),
		Kit.color("Mutation ×" .. string.format("%.2g", mods.mutationMult), C.pink),
		Kit.color(bait.name .. baitCount, C.muted)
	)

	local held = LocalCharacter.heldRod() ~= nil
	local state = fishing.getState()
	if status then
		hintLabel.Text = status .. (if state == "waiting" then Kit.color("   (click to reel in)", C.muted) else "")
		hintLabel.TextColor3 = C.text
	elseif not held then
		hintLabel.Text = if touch then "Tap 🎣 to take out your rod" else "Press 1 to take out your rod"
		hintLabel.TextColor3 = C.muted
	elseif state == "idle" then
		hintLabel.Text = if touch then "Hold CAST, release in the gold for a Perfect Cast" else "Hold Click to cast · release in the gold for a Perfect Cast"
		hintLabel.TextColor3 = C.muted
	else
		hintLabel.Text = ""
	end

	slotName.Text = rod.name
	slotStroke.Transparency = if held then 0.1 else 0.85
	slotStroke.Thickness = if held then 2 else 1
	castButton.Visible = touch and held
	castButton.Text = if state == "waiting" then "REEL" else "CAST"
end

function Hud.start()
	State.onChange(function(changed)
		if changed["*"] or changed.yen or changed.inventory or changed.storageTier or changed.boat or changed.passes then
			refreshWallet()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and (input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.ButtonY) then
			LocalCharacter.toggleRod()
		end
	end)
	task.spawn(function()
		while true do
			tick()
			task.wait(0.2)
		end
	end)
end

return Hud
