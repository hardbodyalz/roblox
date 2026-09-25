--!strict
-- NEW CATCH card with Keep / Sell / Lock. Normal catches pop straight up; rare ones get a
-- blackout and a line-by-line reveal; Corrupted ones glitch their name in.

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

local CatchScreen = {}

local player = Players.LocalPlayer
local C = Kit.Colors

local gui = Kit.new("ScreenGui", {
	Name = "CatchScreen",
	ResetOnSpawn = false,
	DisplayOrder = 30,
	IgnoreGuiInset = true,
	Enabled = false,
	Parent = player:WaitForChild("PlayerGui"),
})

local blackout = Kit.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	Parent = gui,
})

local open = false

local function row(parent: Instance, order: number, text: string, size: number?, font: Enum.Font?): TextLabel
	return Kit.label({
		Text = text,
		TextSize = size or 18,
		Font = font or Kit.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, (size or 18) + 6),
		LayoutOrder = order,
		Parent = parent,
	})
end

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

-- result: { uid, item, newCharacter, newMutation, storageFull }
function CatchScreen.show(result: any)
	while open do
		task.wait()
	end
	open = true
	local item = result.item
	local character = Characters.byId[item.c]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[item.m]
	local spot = Islands.spotsById[item.s]
	local island = Islands.islandOfSpot[item.s]
	local weather = Weather.byId[item.x]
	local dramatic = rarity.order >= Balance.DRAMATIC_RARITY_ORDER or mutation.order >= Balance.DRAMATIC_MUTATION_ORDER
	local corrupted = rarity.id == "Corrupted" or rarity.id == "Mystery"

	gui.Enabled = true

	local card = Kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 560),
		BackgroundColor3 = C.panel,
		Parent = gui,
	}, {
		Kit.corner(16),
		Kit.padding(16),
		Kit.new("UIScale", { Scale = 0.6 }),
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(400, 560) }),
	})
	local cardStroke = Kit.stroke(rarity.color, 4)
	cardStroke.Parent = card
	if mutation.id ~= "Normal" then
		Kit.gradient(mutation.color, mutation.color2, true).Parent = cardStroke
	end

	local body = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -50), Parent = card }, { Kit.list(2, false, Enum.HorizontalAlignment.Center) })

	local header = if result.newCharacter then "NEW WAIFU DISCOVERED!" elseif result.newMutation then "NEW MUTATION!" else "NEW CATCH"
	local headerLabel = row(body, 1, header, 22, Kit.Font)
	headerLabel.TextColor3 = if result.newCharacter or result.newMutation then C.gold else C.muted

	local portraitHolder = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(190, 190), LayoutOrder = 2, Parent = body })
	local portrait = Portrait.create(item.c, item.m, false)
	portrait.Parent = portraitHolder

	local nameLabel = row(body, 3, string.upper(character.name), 30, Kit.Font)
	nameLabel.TextColor3 = rarity.color
	local rarityLabel = row(body, 4, rarity.name, 22, Kit.Font)
	rarityLabel.TextColor3 = rarity.color
	local mutationLabel = row(body, 5, mutation.name, 22, Kit.Font)
	if mutation.id ~= "Normal" then
		mutationLabel.TextColor3 = Color3.new(1, 1, 1)
		Kit.gradient(mutation.color, mutation.color2, true).Parent = mutationLabel
	else
		mutationLabel.TextColor3 = C.muted
	end
	local weightLabel = row(body, 6, Format.kg(item.w), 20)
	local valueLabel = row(body, 7, Format.yen(item.v) .. (if item.f then Kit.color("  Beginner's Fortune!", C.gold) else ""), 22, Kit.Font)
	valueLabel.TextColor3 = C.gold
	local whereText = (if spot then spot.name else "?") .. (if island then " · " .. island.name else "")
	local whereLabel = row(body, 8, whereText, 15, Kit.Body)
	whereLabel.TextColor3 = C.muted
	local weatherLabel = row(body, 9, if weather and weather.id ~= "Sunny" then "Caught during " .. string.upper(weather.name) else "", 15, Kit.Bold)
	weatherLabel.TextColor3 = if weather then weather.color else C.muted
	local lookLabel = row(body, 10, table.concat(character.look, " · "), 13, Kit.Body)
	lookLabel.TextColor3 = C.muted
	lookLabel.Size = UDim2.new(1, 0, 0, 36)
	if result.storageFull then
		local full = row(body, 11, "Storage full! Sell to keep fishing.", 14, Kit.Bold)
		full.TextColor3 = C.bad
	end

	local buttons = Kit.new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.new(1, 0, 0, 42),
		Parent = card,
	}, { Kit.list(10, true, Enum.HorizontalAlignment.Center) })
	local keep = Kit.button("KEEP", C.good, { Size = UDim2.fromOffset(108, 42), Parent = buttons })
	local sell = Kit.button("SELL", C.gold, { Size = UDim2.fromOffset(108, 42), Parent = buttons })
	local lock = Kit.button("🔒 LOCK", C.accent2, { Size = UDim2.fromOffset(108, 42), Parent = buttons })

	local scale = card:FindFirstChildOfClass("UIScale") :: UIScale

	if dramatic then
		-- Screen goes black, then the card reveals line by line.
		card.Visible = false
		Kit.tween(blackout, 0.5, { BackgroundTransparency = 0 })
		if corrupted then
			task.spawn(screenGlitch, 1.2)
		end
		task.wait(1.4)
		local reveal = { rarityLabel, nameLabel, mutationLabel, weightLabel, valueLabel, weatherLabel }
		for _, l in body:GetChildren() do
			if l:IsA("TextLabel") then
				l.TextTransparency = 1
			end
		end
		portraitHolder.Visible = false
		buttons.Visible = false
		card.Visible = true
		scale.Scale = 1
		Kit.tween(blackout, 0.6, { BackgroundTransparency = 0.35 })
		headerLabel.TextTransparency = 0
		for _, l in reveal do
			if l == nameLabel then
				portraitHolder.Visible = true
			end
			l.TextTransparency = 0
			if l == nameLabel and corrupted then
				glitchName(nameLabel, string.upper(character.name), character.unknownName or "???")
			end
			task.wait(0.55)
		end
		for _, l in body:GetChildren() do
			if l:IsA("TextLabel") then
				l.TextTransparency = 0
			end
		end
		buttons.Visible = true
	else
		Kit.tween(blackout, 0.25, { BackgroundTransparency = 0.6 })
		Kit.tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	end

	local done = false
	local function close()
		if done then
			return
		end
		done = true
		Kit.tween(scale, 0.2, { Scale = 0.6 })
		Kit.tween(blackout, 0.2, { BackgroundTransparency = 1 }).Completed:Wait()
		card:Destroy()
		gui.Enabled = false
		open = false
	end

	keep.Activated:Connect(close)
	sell.Activated:Connect(function()
		local ok = Remote.request("Sell", { uids = { result.uid } })
		if ok then
			close()
		end
	end)
	lock.Activated:Connect(function()
		Remote.request("ToggleLock", { uid = result.uid, locked = true })
		close()
	end)

	-- Ordinary catches dismiss themselves (kept) so fishing stays quick.
	if not dramatic and not result.newCharacter and not result.newMutation then
		task.delay(6, close)
	end
end

function CatchScreen.isOpen(): boolean
	return open
end

return CatchScreen
