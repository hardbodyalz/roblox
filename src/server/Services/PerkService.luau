--!strict
-- Gamepasses, timed boosts (developer products) and the Waifu Carrier's Collector bonus,
-- folded into the Perks table that Modifiers.compute expects.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Monetization = require(Shared.Config.Monetization)
local Modifiers = require(Shared.Modifiers)
local Clock = require(Shared.Clock)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)

local PerkService = {}

local owned: { [Player]: { [string]: boolean } } = {}

local function checkPasses(player: Player)
	local passes = {}
	for key, pass in Monetization.Gamepasses do
		if pass.id ~= 0 then
			local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
			passes[key] = ok and result == true
		else
			passes[key] = false
		end
	end
	owned[player] = passes
end

function PerkService.owns(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

function PerkService.passes(player: Player): { [string]: boolean }
	return owned[player] or {}
end

local function boostActive(player: Player, boost: string): boolean
	local data = DataService.get(player)
	return data ~= nil and (data.boosts[boost] or 0) > os.time()
end

function PerkService.perks(player: Player): Modifiers.Perks
	local data = DataService.get(player)
	return Modifiers.perksFrom(PerkService.passes(player), if data then data.boosts else {}, if data then data.collectorEnds else 0, os.time())
end

function PerkService.yenMult(player: Player): number
	local mult = 1
	if PerkService.owns(player, "DoubleYen") then
		mult *= 2
	end
	if boostActive(player, "Yen") then
		mult *= 2
	end
	if PerkService.owns(player, "VIP") then
		mult *= Monetization.VIP_YEN_BONUS
	end
	return mult
end

function PerkService.infiniteStorage(player: Player): boolean
	return PerkService.owns(player, "InfiniteStorage")
end

local function grantProduct(player: Player, productId: number): boolean
	local data = DataService.get(player)
	if not data then
		return false
	end
	for _, product in Monetization.Products do
		if product.id == productId then
			if product.boost == "ServerLuck" then
				local now = Clock.now()
				local current = math.max(now, ReplicatedStorage:GetAttribute("ServerLuckEnds") or 0)
				ReplicatedStorage:SetAttribute("ServerLuckEnds", current + product.seconds)
				Net.event("Announce"):FireAllClients({
					title = "10× SERVER LUCK",
					text = player.DisplayName .. " activated 10× Server Luck for everyone!",
					color = Color3.fromRGB(120, 255, 140),
				})
			else
				local current = math.max(os.time(), data.boosts[product.boost] or 0)
				data.boosts[product.boost] = current + product.seconds
				DataService.push(player, "boosts")
			end
			return true
		end
	end
	return false
end

function PerkService.start()
	Players.PlayerAdded:Connect(checkPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPasses, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Monetization.Gamepasses do
			if pass.id == passId then
				owned[player] = owned[player] or {}
				owned[player][key] = true
				DataService.patch(player, { passes = owned[player] })
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local data = player and DataService.get(player)
		if not player or not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if data.receipts[receipt.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		if grantProduct(player, receipt.ProductId) then
			data.receipts[receipt.PurchaseId] = true
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.setExtrasProvider(function(player)
		if not owned[player] then
			checkPasses(player)
		end
		return { passes = owned[player] }
	end)
end

return PerkService
