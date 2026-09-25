--!strict
-- Rods, boats, bait, storage and passes.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = Shared.Config
local Equipment = require(Config.Equipment)
local Islands = require(Config.Islands)
local Monetization = require(Config.Monetization)
local Format = require(Shared.Format)

local Kit = require(script.Parent.Kit)
local Window = require(script.Parent.Window)
local State = require(script.Parent.Parent.State)
local Remote = require(script.Parent.Parent.Remote)

local ShopWindow: any = {}

local C = Kit.Colors
local player = Players.LocalPlayer

local handle = Window.create("Shop", "Tackle Shop", Vector2.new(820, 580))
local content = handle.content

local TABS = {
	{ id = "rods", name = "Rods" },
	{ id = "boats", name = "Boats" },
	{ id = "bait", name = "Bait" },
	{ id = "storage", name = "Storage" },
	{ id = "passes", name = "Passes" },
}
local tab = "rods"
local setTab = Window.tabs(content, TABS, function(id)
	tab = id
	ShopWindow.refresh()
end)
setTab(tab)

local list = Window.scroller(content, { Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 1, -44) })
Kit.list(8).Parent = list

local function rowFrame(order: number, height: number?): Frame
	return Window.row(list, order, height or 92)
end

local function text(parent: Instance, t: string, pos: UDim2, size: UDim2, textSize: number?, font: Font?, color: Color3?)
	return Kit.label({ Text = t, Position = pos, Size = size, TextSize = textSize or 14, FontFace = font or Kit.Body, TextColor3 = color or C.text, Parent = parent })
end

local function actionButton(parent: Instance, label: string, color: Color3, enabled: boolean, onClick: () -> ())
	local b = Kit.button(label, if enabled then color else C.panel3, {
		Size = UDim2.fromOffset(150, 36),
		TextColor3 = if enabled and color ~= C.panel3 then C.panel else C.text,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		TextSize = 16,
		AutoButtonColor = enabled,
		Parent = parent,
	})
	b.Activated:Connect(function()
		if enabled then
			onClick()
		end
	end)
	return b
end

local function statLine(pairs: { { string } }): string
	local parts = {}
	for _, p in pairs do
		table.insert(parts, Kit.color(p[1], C.muted) .. " " .. p[2])
	end
	return table.concat(parts, "   ")
end

local function renderRods()
	local data = State.data
	for i, rod in Equipment.rods do
		local owned = data.rods[rod.id] == true
		if rod.secret and not owned then
			local r = rowFrame(i, 60)
			text(r, "???", UDim2.fromOffset(14, 8), UDim2.new(1, -180, 0, 24), 20, Kit.Title, C.muted)
			text(r, "Everything about it is hidden.", UDim2.fromOffset(14, 32), UDim2.new(1, -180, 0, 20), 14, Kit.Body, C.muted)
			continue
		end
		local r = rowFrame(i)
		-- Colour swatch matching the rod model.
		Kit.new("Frame", {
			BackgroundColor3 = rod.color,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.fromOffset(8, 16),
			Parent = r,
		}, { Kit.corner(3), Kit.new("UIStroke", { Color = rod.accent, Thickness = 1.5 }) })
		text(r, rod.name, UDim2.fromOffset(30, 6), UDim2.new(1, -196, 0, 24), 20, Kit.Title)
		text(r, statLine({ { "Luck", tostring(rod.luck) }, { "Control", tostring(rod.control) }, { "Resilience", tostring(rod.resilience) }, { "Max", rod.maxKg .. "kg" }, { "Lure", "+" .. rod.speed .. "%" }, { "Cast", rod.castRange .. " studs" } }), UDim2.fromOffset(14, 32), UDim2.new(1, -180, 0, 18), 13)
		text(r, Kit.color(rod.passive.name .. ":", C.accent) .. " " .. rod.passive.desc, UDim2.fromOffset(14, 52), UDim2.new(1, -180, 0, 34), 13, Kit.Body, C.muted)
		if data.rod == rod.id then
			actionButton(r, "Equipped", C.panel3, false, function() end)
		elseif owned then
			actionButton(r, "Equip", C.accent, true, function()
				Remote.request("EquipRod", { id = rod.id })
			end)
		elseif rod.price then
			local price = rod.price :: number
			actionButton(r, Format.yen(price), C.good, data.yen >= price, function()
				Remote.request("BuyRod", { id = rod.id })
			end)
		end
	end
end

local function renderBoats()
	local data = State.data
	for i, boat in Equipment.boats do
		local owned = data.boats[boat.id] == true
		local r = rowFrame(i)
		local reach = {}
		for _, island in Islands.list do
			if island.minBoatSpeed > 0 and boat.speed >= island.minBoatSpeed then
				table.insert(reach, island.name)
			end
		end
		text(r, boat.name, UDim2.fromOffset(14, 6), UDim2.new(1, -180, 0, 24), 20, Kit.Title)
		text(r, statLine({ { "Speed", tostring(boat.speed) }, { "Handling", tostring(boat.handling) }, { "Capacity", "+" .. boat.capacity }, { "Luck", "+" .. boat.luck } }), UDim2.fromOffset(14, 32), UDim2.new(1, -180, 0, 18))
		text(r, Kit.color(boat.passive.name .. ":", C.accent) .. " " .. boat.passive.desc .. (if #reach > 0 then "  " .. Kit.color("Reaches: " .. table.concat(reach, ", "), C.good) else ""), UDim2.fromOffset(14, 52), UDim2.new(1, -180, 0, 34), 13, Kit.Body, C.muted)
		if data.boat == boat.id then
			actionButton(r, "Equipped", C.panel3, false, function() end)
		elseif owned then
			actionButton(r, "Equip", C.accent, true, function()
				Remote.request("EquipBoat", { id = boat.id })
			end)
		elseif boat.price then
			local price = boat.price :: number
			actionButton(r, Format.yen(price), C.good, data.yen >= price, function()
				Remote.request("BuyBoat", { id = boat.id })
			end)
		end
	end
end

local function renderBait()
	local data = State.data
	for i, bait in Equipment.baits do
		local count = data.bait[bait.id] or 0
		local r = rowFrame(i, 80)
		local ownedText = if bait.id == "normal" then "∞" else tostring(count)
		text(r, bait.name .. Kit.color("   x" .. ownedText, C.muted), UDim2.fromOffset(14, 8), UDim2.new(1, -340, 0, 24), 20, Kit.Title)
		text(r, bait.desc, UDim2.fromOffset(14, 36), UDim2.new(1, -340, 0, 36), 14, Kit.Body, C.muted)
		local equipped = data.baitEquipped == bait.id
		local equip = Kit.button(if equipped then "Equipped" else "Equip", if equipped then C.panel3 else C.accent, {
			TextColor3 = if equipped then C.text else C.panel,
			Size = UDim2.fromOffset(120, 40),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -174, 0.5, 0),
			TextSize = 16,
			Parent = r,
		})
		equip.Activated:Connect(function()
			if not equipped then
				Remote.request("EquipBait", { id = bait.id })
			end
		end)
		if bait.pack > 0 then
			actionButton(r, "x" .. bait.pack .. " " .. Format.yen(bait.price), C.good, data.yen >= bait.price, function()
				Remote.request("BuyBait", { id = bait.id })
			end)
		end
	end
end

local function renderStorage()
	local data = State.data
	for i, tier in Equipment.storage do
		local r = rowFrame(i, 56)
		text(r, tier.slots .. " slots", UDim2.fromOffset(14, 14), UDim2.new(1, -180, 0, 28), 20, Kit.Title)
		if i <= data.storageTier then
			actionButton(r, if i == data.storageTier then "Current" else "Owned", C.panel3, false, function() end)
		elseif i == data.storageTier + 1 then
			actionButton(r, Format.yen(tier.price), C.good, data.yen >= tier.price, function()
				Remote.request("BuyStorage")
			end)
		else
			actionButton(r, Format.yen(tier.price), C.panel3, false, function() end)
		end
	end
	local note = rowFrame(#Equipment.storage + 1, 40)
	text(note, "Your equipped boat's Capacity adds extra slots on top of this.", UDim2.fromOffset(14, 10), UDim2.new(1, -20, 0, 20), 14, Kit.Body, C.muted)
end

local function renderPasses()
	local owned = State.passes()
	local order = 0
	for key, pass in Monetization.Gamepasses do
		order += 1
		local r = rowFrame(order, 56)
		text(r, pass.name, UDim2.fromOffset(14, 14), UDim2.new(1, -180, 0, 28), 20, Kit.Title)
		if owned[key] then
			actionButton(r, "Owned", C.panel3, false, function() end)
		elseif pass.id == 0 then
			actionButton(r, "Coming soon", C.panel3, false, function() end)
		else
			actionButton(r, "Buy", C.gold, true, function()
				MarketplaceService:PromptGamePassPurchase(player, pass.id)
			end)
		end
	end
	for _, product in Monetization.Products do
		order += 1
		local r = rowFrame(order, 56)
		text(r, product.name, UDim2.fromOffset(14, 14), UDim2.new(1, -180, 0, 28), 20, Kit.Title)
		if product.id == 0 then
			actionButton(r, "Coming soon", C.panel3, false, function() end)
		else
			actionButton(r, "Buy", C.gold, true, function()
				MarketplaceService:PromptProductPurchase(player, product.id)
			end)
		end
	end
end

function ShopWindow.refresh()
	if not handle.frame.Visible or not State.data then
		return
	end
	Window.clear(list)
	if tab == "rods" then
		renderRods()
	elseif tab == "boats" then
		renderBoats()
	elseif tab == "bait" then
		renderBait()
	elseif tab == "storage" then
		renderStorage()
	else
		renderPasses()
	end
end

handle.onOpen = ShopWindow.refresh
State.onChange(function(changed)
	if changed.yen or changed.rods or changed.rod or changed.boats or changed.boat or changed.bait or changed.baitEquipped or changed.storageTier or changed.passes or changed["*"] then
		ShopWindow.refresh()
	end
end)

return ShopWindow
