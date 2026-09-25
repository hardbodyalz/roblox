--!strict
-- Your catches: sort, lock, sell one, Sell Duplicates, Sell All.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Characters = require(Config.Characters)
local Rarities = require(Config.Rarities)
local Mutations = require(Config.Mutations)
local Format = require(Shared.Format)
local Storage = require(Shared.Storage)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local Portrait = require(script.Parent.Portrait)
local State = require(script.Parent.Parent.State)
local Remote = require(script.Parent.Parent.Remote)

local InventoryWindow: any = {}

local C = Kit.Colors
local PAGE_SIZE = 40

local handle = Window.create("Inventory", "Catches", Vector2.new(820, 560))
local content = handle.content

local SORTS = {
	{ id = "value", name = "Value" },
	{ id = "rarity", name = "Rarity" },
	{ id = "mutation", name = "Mutation" },
	{ id = "weight", name = "Weight" },
	{ id = "newest", name = "Newest" },
}
local sortBy = "value"
local page = 1

local toolbar = Kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = content })
local setSort = Window.tabs(toolbar, SORTS, function(id)
	sortBy = id
	page = 1
	InventoryWindow.refresh()
end)
setSort(sortBy)
toolbar:FindFirstChildOfClass("ScrollingFrame").Size = UDim2.new(1, -330, 1, 0)

local sellDupes = Kit.button("Sell Duplicates", C.gold, { TextColor3 = C.panel, Size = UDim2.fromOffset(150, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -160, 0, 0), TextSize = 16, Parent = toolbar })
local sellAll = Kit.button("Sell All", C.bad, { Size = UDim2.fromOffset(150, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), TextSize = 16, Parent = toolbar })

local footer = Kit.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 34), Parent = content })
local countLabel = Kit.label({ Size = UDim2.new(0.5, 0, 1, 0), TextSize = 16, TextColor3 = C.muted, Parent = footer })
local prev = Kit.button("◀", C.panel3, { Size = UDim2.fromOffset(40, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -110, 0, 2), Parent = footer })
local pageLabel = Kit.label({ Size = UDim2.fromOffset(60, 34), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -48, 0, 0), TextXAlignment = Enum.TextXAlignment.Center, Parent = footer })
local nextB = Kit.button("▶", C.panel3, { Size = UDim2.fromOffset(40, 30), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Parent = footer })

local grid = Window.scroller(content, { Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 1, -90) })
Kit.new("UIGridLayout", {
	CellSize = UDim2.fromOffset(148, 196),
	CellPadding = UDim2.fromOffset(8, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = grid,
})

local function sorted(): { { uid: string, item: any } }
	local list = {}
	for uid, item in State.data.inventory do
		table.insert(list, { uid = uid, item = item })
	end
	local function rarityOrder(e)
		return Rarities.byId[Characters.byId[e.item.c].rarity].order
	end
	local function mutationOrder(e)
		return Mutations.byId[e.item.m].order
	end
	table.sort(list, function(a, b)
		if sortBy == "rarity" and rarityOrder(a) ~= rarityOrder(b) then
			return rarityOrder(a) > rarityOrder(b)
		elseif sortBy == "mutation" and mutationOrder(a) ~= mutationOrder(b) then
			return mutationOrder(a) > mutationOrder(b)
		elseif sortBy == "weight" and a.item.w ~= b.item.w then
			return a.item.w > b.item.w
		elseif sortBy == "newest" and a.item.t ~= b.item.t then
			return a.item.t > b.item.t
		end
		if a.item.v ~= b.item.v then
			return a.item.v > b.item.v
		end
		return tonumber(a.uid) :: number > tonumber(b.uid) :: number
	end)
	return list
end

local function card(uid: string, item: any, order: number)
	local character = Characters.byId[item.c]
	local rarity = Rarities.byId[character.rarity]
	local mutation = Mutations.byId[item.m]
	local frame = Kit.new("Frame", {
		BackgroundColor3 = C.panel2,
		BackgroundTransparency = 0.1,
		LayoutOrder = order,
		Parent = grid,
	}, { Kit.corner(6), Kit.stroke(rarity.color, 1.5, 0.3) })
	local holder = Kit.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(34, 6), Size = UDim2.fromOffset(80, 80), Parent = frame })
	Portrait.create(item.c, item.m).Parent = holder
	Kit.label({ Text = character.name, FontFace = Kit.Title, TextSize = 15, TextColor3 = rarity.color, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(4, 88), Size = UDim2.new(1, -8, 0, 18), TextScaled = true, Parent = frame })
	local mutationText = if mutation.id == "Normal" then Kit.color(rarity.name, C.muted) else Kit.color(mutation.name, mutation.color) .. " " .. Kit.color(rarity.name, C.muted)
	Kit.label({ Text = mutationText, TextSize = 13, FontFace = Kit.Bold, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(4, 108), Size = UDim2.new(1, -8, 0, 16), Parent = frame })
	Kit.label({ Text = Format.kg(item.w) .. " · " .. Kit.color(Format.yen(item.v), C.gold), TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(4, 126), Size = UDim2.new(1, -8, 0, 16), Parent = frame })

	local lock = Kit.button(if item.l then "🔒" else "🔓", if item.l then C.accent else C.panel3, { Size = UDim2.fromOffset(40, 32), Position = UDim2.fromOffset(8, 154), TextSize = 16, Parent = frame })
	local sell = Kit.button(if item.l then "Locked" else "Sell", if item.l then C.panel3 else C.gold, { TextColor3 = if item.l then C.text else C.panel, Size = UDim2.fromOffset(84, 32), Position = UDim2.fromOffset(56, 154), TextSize = 15, Parent = frame })
	lock.Activated:Connect(function()
		Remote.request("ToggleLock", { uid = uid })
	end)
	sell.Activated:Connect(function()
		if not item.l then
			Remote.request("Sell", { uids = { uid } })
		end
	end)
end

function InventoryWindow.refresh()
	if not handle.frame.Visible or not State.data then
		return
	end
	Window.clear(grid)
	local list = sorted()
	local pages = math.max(1, math.ceil(#list / PAGE_SIZE))
	page = math.clamp(page, 1, pages)
	for i = (page - 1) * PAGE_SIZE + 1, math.min(#list, page * PAGE_SIZE) do
		card(list[i].uid, list[i].item, i)
	end
	local capacity = Storage.capacity(State.data.storageTier, State.data.boat, State.passes().InfiniteStorage == true)
	countLabel.Text = string.format("%d / %s stored", #list, if capacity == math.huge then "∞" else tostring(capacity))
	pageLabel.Text = page .. "/" .. pages
end

prev.Activated:Connect(function()
	page -= 1
	InventoryWindow.refresh()
end)
nextB.Activated:Connect(function()
	page += 1
	InventoryWindow.refresh()
end)

sellDupes.Activated:Connect(function()
	Remote.request("SellDuplicates")
end)

-- Sell All needs a second click to confirm.
local confirmUntil = 0
sellAll.Activated:Connect(function()
	if os.clock() < confirmUntil then
		confirmUntil = 0
		sellAll.Text = "Sell All"
		Remote.request("SellAll")
	else
		confirmUntil = os.clock() + 3
		sellAll.Text = "Confirm?"
		task.delay(3, function()
			sellAll.Text = "Sell All"
		end)
	end
end)

handle.onOpen = InventoryWindow.refresh

local pending = false
State.onChange(function(changed)
	if changed.inventory or changed["*"] or changed.storageTier or changed.boat then
		-- Coalesce bursts (e.g. Sell All) into one redraw.
		if not pending then
			pending = true
			task.defer(function()
				pending = false
				InventoryWindow.refresh()
			end)
		end
	end
end)

return InventoryWindow
