--!strict
-- Collection Book: find every Waifu, then every mutation of every Waifu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Collection = require(Shared.Collection)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local Portrait = require(script.Parent.Portrait)
local State = require(script.Parent.Parent.State)

local CollectionWindow: any = {}

local C = Kit.Colors

local handle = Window.create("Collection", "📖 Collection Book", Vector2.new(860, 580))
local content = handle.content

local pageId = "sakura_shore"
local selected: string? = nil

local pages = Collection.pages()
local setTab = Window.tabs(content, pages, function(id)
	pageId = id
	selected = nil
	CollectionWindow.refresh()
end)
setTab(pageId)

local progressLabel = Kit.label({ Position = UDim2.fromOffset(0, 44), Size = UDim2.new(0.6, 0, 0, 24), TextSize = 17, Font = Kit.Bold, Parent = content })

local grid = Window.scroller(content, { Position = UDim2.fromOffset(0, 74), Size = UDim2.new(0.6, -8, 1, -74) })
Kit.new("UIGridLayout", { CellSize = UDim2.fromOffset(118, 150), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })

local detail = Kit.new("Frame", {
	BackgroundColor3 = C.panel2,
	Position = UDim2.new(0.6, 0, 0, 44),
	Size = UDim2.new(0.4, 0, 1, -44),
	Parent = content,
}, { Kit.corner(12), Kit.padding(12) })

local function renderDetail()
	Window.clear(detail)
	if not selected then
		Kit.label({ Text = "Select a Waifu to see her mutations.", TextColor3 = C.muted, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = detail })
		return
	end
	local character = Characters.byId[selected]
	local rarity = Rarities.byId[character.rarity]
	local found = State.data.collection[selected]
	local list = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = detail }, { Kit.list(4) })

	local holder = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(110, 110), LayoutOrder = 1, Parent = list })
	Portrait.create(selected, nil, found == nil).Parent = holder
	Kit.label({ Text = if found then string.upper(character.name) else "???", Font = Kit.Font, TextSize = 22, TextColor3 = rarity.color, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 2, Parent = list })
	Kit.label({ Text = "Rarity: " .. Kit.color(rarity.name, rarity.color) .. "   Discovered: " .. (if found then Kit.color("✓", C.good) else "???"), TextSize = 14, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 3, Parent = list })
	if found then
		Kit.label({ Text = table.concat(character.look, " · ") .. "\n<i>" .. character.personality .. "</i>", TextSize = 13, TextColor3 = C.muted, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 4, Parent = list })
	end
	Kit.label({ Text = "Mutations", Font = Kit.Font, TextSize = 18, Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 5, Parent = list })
	for i, mutation in Mutations.list do
		local has = found ~= nil and found[mutation.id] == true
		Kit.label({
			Text = (if has then Kit.color(mutation.name, mutation.color) .. "  " .. Kit.color("✓", C.good) else Kit.color(mutation.name, C.muted) .. "  ???"),
			TextSize = 15,
			Font = Kit.Bold,
			Size = UDim2.new(1, 0, 0, 18),
			LayoutOrder = 5 + i,
			Parent = list,
		})
	end
end

local function card(characterId: string, order: number)
	local character = Characters.byId[characterId]
	local rarity = Rarities.byId[character.rarity]
	local found = State.data.collection[characterId]
	local button = Kit.new("TextButton", {
		Text = "",
		BackgroundColor3 = if characterId == selected then C.panel3 else C.panel2,
		AutoButtonColor = true,
		LayoutOrder = order,
		Parent = grid,
	}, { Kit.corner(10), Kit.stroke(if found then rarity.color else C.panel3, 2, 0.2) })
	local holder = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(19, 6), Size = UDim2.fromOffset(80, 80), Parent = button })
	Portrait.create(characterId, nil, found == nil).Parent = holder
	Kit.label({
		Text = if found then character.name else (if character.hidden then "???" else character.name .. " ???"),
		Font = Kit.Font,
		TextSize = 14,
		TextColor3 = if found then rarity.color else C.muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(4, 90),
		Size = UDim2.new(1, -8, 0, 32),
		Parent = button,
	})
	-- Mutation pips
	local pips = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(9, 128), Size = UDim2.new(1, -18, 0, 12), Parent = button }, { Kit.list(4, true, Enum.HorizontalAlignment.Center) })
	for i, mutation in Mutations.list do
		local has = found ~= nil and found[mutation.id] == true
		Kit.new("Frame", {
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = if has then mutation.color else C.panel3,
			LayoutOrder = i,
			Parent = pips,
		}, { Kit.corner(3) })
	end
	button.Activated:Connect(function()
		selected = characterId
		CollectionWindow.refresh()
	end)
end

function CollectionWindow.refresh()
	if not handle.frame.Visible or not State.data then
		return
	end
	Window.clear(grid)
	local order = 0
	for _, id in Collection.roster(pageId) do
		local character = Characters.byId[id]
		if not character.hidden or State.data.collection[id] then
			order += 1
			card(id, order)
		end
	end
	local found, total = Collection.progress(State.data.collection, pageId)
	local mutationsFound = 0
	for _, id in Collection.roster(pageId) do
		local entry = State.data.collection[id]
		if entry then
			for _ in entry do
				mutationsFound += 1
			end
		end
	end
	progressLabel.Text = string.format("%d / %d discovered   ·   %d mutations found", found, total, mutationsFound)
	renderDetail()
end

handle.onOpen = CollectionWindow.refresh
State.onChange(function(changed)
	if changed.collection or changed["*"] then
		CollectionWindow.refresh()
	end
end)

return CollectionWindow
