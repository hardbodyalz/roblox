--!strict
-- The catch card with Keep / Sell / Lock. Ordinary catches slide in on the right and keep
-- themselves after a few seconds, so you can carry on fishing. Rare ones black out the screen
-- and reveal line by line; Corrupted ones glitch their name in.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Islands = require(Config.Islands)
local Weather = require(Config.Weather)
local Balance = require(Config.Balance)
local Format = require(Shared.Format)

local Kit = require(script.Parent.Kit)
local Portrait = require(script.Parent.Portrait)
local Remote = require(script.Parent.Parent.Remote)

local CatchCard = {}

local player = Players.LocalPlayer
local C = Kit.Colors

local AUTO_KEEP_SECONDS = 6

local gui = Kit.new("ScreenGui", {
	Name = "CatchCard",
	ResetOnSpawn = false,
	DisplayOrder = 30,
	IgnoreGuiInset = true,
	Parent = player:WaitForChild("PlayerGui"),
})

local blackout = Kit.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = gui,
})

local busy = false
local blocking = false

local function glitchName(labelInstance: TextLabel, finalText: string, from: string)
	local chars = { "▓", "█", "░", "?", "#", "@", "∆" }
	local rng = Random.new()
	for i = 1, 18 do
		local s = ""
		for _ = 1, #from + math.floor(i / 3) do
			s ..= chars[rng:NextInteger(1, #chars)]
		end
		labelInstance.Text = if i % 4 == 0 then from else s
		task.wait(0.06)
	end
	labelInstance.Text = finalText
end

local function screenGlitch(seconds: number)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Parent = Lighting
	local rng = Random.new()
	local t = 0
	while t < seconds do
		cc.Saturation = rng:NextNumber(-1, 1)
		cc.Contrast = rng:NextNumber(-0.5, 1)
		cc.TintColor = Color3.new(rng:NextNumber(0.6, 1), rng:NextNumber(0, 1), rng:NextNumber(0.6, 1))
		local w = rng:NextNumber(0.03, 0.12)
		task.wait(w)
		t += w
	end
	cc:Destroy()
end

local function whereText(item: any): string
	local island = Islands.byId[item.i or ""] or Islands.islandOfSpot[item.s or ""]
	local spot = item.s and Islands.spotsById[item.s]
	if spot and island then
		return spot.name .. " · " .. island.name
	end
	return if island then island.name else "?"
end

type Card = {
	frame: Frame,
	lines: { [string]: TextLabel },
	portrait: Frame,
	buttons: Frame,
	keep: TextButton,
	sell: TextButton,
	lock: TextButton,
}

local function buildCard(result: any, dramatic: boolean): Card
	local item = result.item
	local character = Characters.byId[item.c]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[item.m]
	local weather = Weather.byId[item.x]
	local width = if dramatic then 360 else 280

	local frame = Kit.panel({
		AnchorPoint = if dramatic then Vector2.new(0.5, 0.5) else Vector2.new(1, 0.5),
		Position = if dramatic then UDim2.fromScale(0.5, 0.5) else UDim2.new(1, width + 40, 0.5, 0),
		Size = UDim2.fromOffset(width, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.08,
		Parent = gui,
	}, { Kit.padding(14), Kit.list(4, false, Enum.HorizontalAlignment.Center) })
	local stroke = frame:FindFirstChildOfClass("UIStroke") :: UIStroke
	stroke.Color = rarity.color
	stroke.Thickness = if dramatic then 3 else 2
	stroke.Transparency = 0
	if mutation.id ~= "Normal" then
		stroke.Color = Color3.new(1, 1, 1)
		Kit.gradient(mutation.color, mutation.color2, true).Parent = stroke
	end

	local lines: { [string]: TextLabel } = {}
	local order = 0
	local function line(key: string, text: string, size: number, font: Font, color: Color3?): TextLabel
		order += 1
		local l = Kit.label({
			Text = text,
			TextSize = size,
			FontFace = font,
			TextColor3 = color or C.text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = order,
			Parent = frame,
		})
		lines[key] = l
		return l
	end

	local header = if result.newCharacter then "NEW WAIFU DISCOVERED!" elseif result.newMutation then "NEW MUTATION!" else "CAUGHT"
	line("header", header, 14, Kit.Bold, if result.newCharacter then C.pink elseif result.newMutation then C.gold else C.muted)

	order += 1
	local size = if dramatic then 170 else 120
	local portrait = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), LayoutOrder = order, Parent = frame })
	Portrait.create(item.c, item.m, false).Parent = portrait

	line("name", string.upper(character.name), if dramatic then 28 else 22, Kit.Title, rarity.color)
	line("rarity", rarity.name, 17, Kit.Bold, rarity.color)
	local mutationLabel = line("mutation", mutation.name, 17, Kit.Bold, if mutation.id == "Normal" then C.muted else Color3.new(1, 1, 1))
	if mutation.id ~= "Normal" then
		Kit.gradient(mutation.color, mutation.color2, true).Parent = mutationLabel
	end
	line("weight", Format.kg(item.w), 16, Kit.Bold)
	line("value", Format.yen(item.v) .. (if item.f then Kit.color("  Beginner's Fortune!", C.gold) else ""), 20, Kit.Title, C.gold)
	line("where", whereText(item), 13, Kit.Body, C.muted)
	if weather and weather.id ~= "Sunny" then
		line("weather", "Caught during " .. string.upper(weather.name), 13, Kit.Bold, weather.color)
	end
	if dramatic then
		line("look", table.concat(character.look, " · "), 13, Kit.Body, C.muted)
	end
	if result.storageFull then
		line("full", "Storage full! Sell to keep fishing.", 13, Kit.Bold, C.bad)
	end

	order += 1
	local buttons = Kit.new("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 36),
		LayoutOrder = order,
		Parent = frame,
	}, { Kit.list(8, true, Enum.HorizontalAlignment.Center) })
	local bw = (width - 28 - 16) / 3
	local keep = Kit.button("Keep", C.panel3, { Size = UDim2.fromOffset(bw, 34), Parent = buttons })
	local sell = Kit.button("Sell", C.gold, { Size = UDim2.fromOffset(bw, 34), TextColor3 = C.panel, Parent = buttons })
	local lock = Kit.button("Lock", C.accent, { Size = UDim2.fromOffset(bw, 34), TextColor3 = C.panel, Parent = buttons })

	return { frame = frame, lines = lines, portrait = portrait, buttons = buttons, keep = keep, sell = sell, lock = lock }
end

-- Black out, then reveal the card line by line.
local function reveal(card: Card, result: any)
	local item = result.item
	local character = Characters.byId[item.c]
	local rarity = Rarities.byId[character.rarity]
	local corrupted = rarity.id == "Corrupted" or rarity.id == "Mystery"

	card.frame.Visible = false
	blackout.Visible = true
	Kit.tween(blackout, 0.5, { BackgroundTransparency = 0 })
	if corrupted then
		task.spawn(screenGlitch, 1.2)
	end
	task.wait(1.4)
	for _, l in card.lines do
		l.TextTransparency = 1
	end
	card.portrait.Visible = false
	card.buttons.Visible = false
	card.frame.Visible = true
	Kit.tween(blackout, 0.6, { BackgroundTransparency = 0.35 })
	card.lines.header.TextTransparency = 0
	for _, key in { "rarity", "name", "mutation", "weight", "value", "weather" } do
		local l = card.lines[key]
		if l then
			if key == "name" then
				card.portrait.Visible = true
			end
			l.TextTransparency = 0
			if key == "name" and corrupted then
				glitchName(l, string.upper(character.name), character.unknownName or "???")
			end
			task.wait(0.55)
		end
	end
	for _, l in card.lines do
		l.TextTransparency = 0
	end
	card.buttons.Visible = true
end

-- result: { uid, item, newCharacter, newMutation, storageFull }
-- Yields until the card is closed (kept, sold or locked), then calls onClosed.
function CatchCard.show(result: any, onClosed: (() -> ())?)
	while busy do
		task.wait()
	end
	busy = true
	local item = result.item
	local rarity = Rarities.byId[Characters.byId[item.c].rarity]
	local mutation = Mutations.byId[item.m]
	local dramatic = rarity.order >= Balance.DRAMATIC_RARITY_ORDER or mutation.order >= Balance.DRAMATIC_MUTATION_ORDER
	blocking = dramatic

	local card = buildCard(result, dramatic)
	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		if dramatic then
			Kit.tween(blackout, 0.25, { BackgroundTransparency = 1 })
			Kit.tween(card.frame, 0.25, { Position = UDim2.fromScale(0.5, 0.56) }).Completed:Wait()
			blackout.Visible = false
		else
			Kit.tween(card.frame, 0.25, { Position = UDim2.new(1, card.frame.AbsoluteSize.X + 40, 0.5, 0) }).Completed:Wait()
		end
		card.frame:Destroy()
		blocking = false
		busy = false
		if onClosed then
			task.spawn(onClosed)
		end
	end

	card.keep.Activated:Connect(close)
	card.sell.Activated:Connect(function()
		if Remote.request("Sell", { uids = { result.uid } }) then
			close()
		end
	end)
	card.lock.Activated:Connect(function()
		Remote.request("ToggleLock", { uid = result.uid, locked = true })
		close()
	end)

	if dramatic then
		reveal(card, result)
	else
		Kit.tween(card.frame, 0.35, { Position = UDim2.new(1, -24, 0.5, 0) }, Enum.EasingStyle.Back)
		-- Ordinary catches keep themselves so fishing stays quick.
		if not result.newCharacter and not result.newMutation then
			task.delay(AUTO_KEEP_SECONDS, close)
		end
	end
	while not closed do
		task.wait()
	end
end

-- True while a cinematic reveal is up; casting waits for it.
function CatchCard.isBlocking(): boolean
	return blocking
end

return CatchCard
