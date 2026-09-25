--!strict
-- Always-on HUD: Yen, storage, weather + events, menu buttons, spot, loadout, CAST.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Equipment = require(Config.Equipment)
local Islands = require(Config.Islands)
local Weather = require(Config.Weather)
local Clock = require(Shared.Clock)
local Format = require(Shared.Format)
local Modifiers = require(Shared.Modifiers)
local Storage = require(Shared.Storage)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local State = require(script.Parent.Parent.State)

local Hud = {}

local player = Players.LocalPlayer
local C = Kit.Colors

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

-- Top-left: money and storage
local wallet = Kit.new("Frame", {
	Position = UDim2.fromOffset(16, 16),
	Size = UDim2.fromOffset(230, 70),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.15,
	Parent = gui,
}, { Kit.corner(12), Kit.stroke(C.gold, 2, 0.4), Kit.padding(10) })
local yenLabel = Kit.label({ Text = "¥0", Font = Kit.Font, TextSize = 26, TextColor3 = C.gold, Size = UDim2.new(1, 0, 0, 28), Parent = wallet })
local storageLabel = Kit.label({ Text = "", TextSize = 14, TextColor3 = C.muted, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 18), Parent = wallet })

-- Top-centre: weather and events
local weatherBox = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.fromOffset(360, 56),
	BackgroundColor3 = C.panel,
	BackgroundTransparency = 0.2,
	Parent = gui,
}, { Kit.corner(12) })
local weatherStroke = Kit.stroke(C.gold, 2, 0.3)
weatherStroke.Parent = weatherBox
local weatherLabel = Kit.label({ Font = Kit.Font, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 4), Size = UDim2.new(1, -16, 0, 24), Parent = weatherBox })
local eventLabel = Kit.label({ TextSize = 13, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 30), Size = UDim2.new(1, -16, 0, 20), Parent = weatherBox })

-- Left: menu buttons
local menu = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 16, 0.5, 0),
	Size = UDim2.fromOffset(64, 340),
	BackgroundTransparency = 1,
	Parent = gui,
}, { Kit.list(8) })
local MENU = {
	{ id = "Inventory", icon = "🎒", color = C.accent },
	{ id = "Collection", icon = "📖", color = C.accent2 },
	{ id = "Shop", icon = "🛒", color = C.good },
	{ id = "Sail", icon = "⛵", color = Color3.fromRGB(80, 170, 255) },
	{ id = "Achievements", icon = "🏆", color = C.gold },
}
for i, m in MENU do
	local b = Kit.button(m.icon, m.color, { Size = UDim2.fromOffset(60, 60), TextSize = 30, LayoutOrder = i, Parent = menu })
	Kit.label({ Text = m.id, TextSize = 11, Font = Kit.Bold, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.new(1, 0, 0, 12), TextStrokeTransparency = 0.3, Parent = b })
	b.Activated:Connect(function()
		Window.open(m.id)
	end)
end

-- Bottom-centre: spot, loadout, cast
local bottom = Kit.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -16),
	Size = UDim2.fromOffset(420, 120),
	BackgroundTransparency = 1,
	Parent = gui,
})
local spotLabel = Kit.label({ Font = Kit.Font, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 22), TextStrokeTransparency = 0.4, Parent = bottom })
local loadoutLabel = Kit.label({ TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 18), TextStrokeTransparency = 0.4, Parent = bottom })
local castButton = Kit.button("CAST  [E]", C.accent, {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0),
	Size = UDim2.fromOffset(220, 64),
	TextSize = 28,
	Parent = bottom,
})

local status: string? = nil
local fishing: any = nil

function Hud.bindFishing(fishingModule: any)
	fishing = fishingModule
	castButton.Activated:Connect(function()
		fishing.cast()
	end)
	fishing.onStatus(function(text)
		status = text
	end)
end

local function currentIsland(): string?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local island = root and Islands.islandAt(root.Position)
	return island and island.id
end
Hud.currentIsland = currentIsland

local function refreshWallet()
	local data = State.data
	if not data then
		return
	end
	yenLabel.Text = Format.yen(data.yen)
	local count = State.inventoryCount()
	local capacity = Storage.capacity(data.storageTier, data.boat, State.passes().InfiniteStorage == true)
	storageLabel.Text = string.format("🎒 %d / %s catches", count, if capacity == math.huge then "∞" else tostring(capacity))
	storageLabel.TextColor3 = if count >= capacity then C.bad else C.muted
end

local function tick()
	local data = State.data
	-- Weather
	local weatherId, ends = Clock.weather()
	local weather = Weather.byId[weatherId] or Weather.byId.Sunny
	weatherLabel.Text = string.format("%s %s  %s", WEATHER_ICON[weather.id] or "", weather.name, Kit.color(Format.clock(ends - Clock.now()), C.muted))
	weatherLabel.TextColor3 = weather.color
	weatherStroke.Color = weather.color

	local events = { weather.blurb }
	local islandId = currentIsland()
	local island = islandId and Islands.byId[islandId]
	local night = Clock.isNight() or (island ~= nil and island.permanentNight == true)
	table.insert(events, (if night then "🌙 " .. Clock.moonPhase() .. " Moon" else string.format("🕐 %02d:00", math.floor(Clock.hour()))))
	local tide, tideLeft = Clock.demonTide()
	if tide then
		table.insert(events, Kit.color("🔥 Demon Tide " .. Format.clock(tideLeft), C.bad))
	end
	if Clock.serverLuck() then
		table.insert(events, Kit.color("🍀 10× Server Luck", C.good))
	end
	if data then
		for boost, until_ in data.boosts do
			if until_ > os.time() then
				table.insert(events, Kit.color("2× " .. boost .. " " .. Format.clock(until_ - os.time()), C.good))
			end
		end
	end
	eventLabel.Text = table.concat(events, "  ·  ")

	-- Spot + loadout
	if not data or not fishing then
		return
	end
	local spotId = fishing.currentSpot()
	local spot = spotId and Islands.spotsById[spotId]
	if status then
		spotLabel.Text = status
		spotLabel.TextColor3 = if status == "BITE!" then C.bad else C.text
	elseif spot then
		spotLabel.Text = "🎣 " .. spot.name .. Kit.color("  " .. spot.blurb, C.muted)
		spotLabel.TextColor3 = C.text
	else
		spotLabel.Text = if island then island.name .. Kit.color("  ·  find a 🎣 spot", C.muted) else "Open sea"
		spotLabel.TextColor3 = C.text
	end

	local rod = Equipment.rodsById[data.rod]
	local bait = Equipment.baitsById[data.baitEquipped]
	local passes = State.passes()
	local perks = {
		doubleLuck = passes.DoubleLuck == true,
		doubleMutation = passes.DoubleMutation == true,
		fastReel = passes.FastReel == true,
		luckBoost = (data.boosts.Luck or 0) > os.time(),
		mutationBoost = (data.boosts.Mutation or 0) > os.time(),
		collectorBoost = data.collectorEnds > os.time(),
	}
	local mods = Modifiers.compute(data.rod, data.boat, data.baitEquipped, spotId or "", Clock.env(), perks)
	local baitCount = if bait.id == "normal" then "" else " x" .. (data.bait[bait.id] or 0)
	loadoutLabel.Text = string.format(
		"%s  ·  %s%s  ·  %s  ·  %s",
		rod.name,
		bait.name,
		baitCount,
		Kit.color("Luck " .. math.floor(mods.luck), C.good),
		Kit.color("Mutation ×" .. string.format("%.2g", mods.mutationMult), C.accent2)
	)

	local busy = fishing.state ~= "idle"
	castButton.Text = if busy then "..." else "CAST  [E]"
	castButton.BackgroundColor3 = if busy or not spot then C.panel3 else C.accent
end

function Hud.start()
	State.onChange(function(changed)
		if changed["*"] or changed.yen or changed.inventory or changed.storageTier or changed.boat or changed.passes then
			refreshWallet()
		end
	end)
	task.spawn(function()
		while true do
			tick()
			task.wait(0.25)
		end
	end)
end

return Hud
