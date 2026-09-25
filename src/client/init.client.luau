--!strict
-- Client entry point.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage.Shared
local Islands = require(Shared.Config.Islands)
local Zones = require(Shared.Zones)

local State = require(script.State)
local Remote = require(script.Remote)
local LocalCharacter = require(script.LocalCharacter)
local Fishing = require(script.Fishing)
local Atmosphere = require(script.Visuals.Atmosphere)
local UI = script.UI
local Notices = require(UI.Notices)
local Hud = require(UI.Hud)
local Tutorial = require(UI.Tutorial)
require(UI.SailWindow)
require(UI.InventoryWindow)
require(UI.CollectionWindow)
require(UI.ShopWindow)
require(UI.AchievementsWindow)

-- The HUD has its own rod slot.
pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

Remote.setErrorHandler(Notices.error)
Notices.start()
Atmosphere.start()
Fishing.start()
Hud.bindFishing(Fishing)
Hud.start()

State.wait()
Tutorial.start()

-- Zone titles: arriving at an island, or heading out into open water.
local lastZone: string? = nil
while true do
	task.wait(1)
	local root = LocalCharacter.root()
	if root then
		local islandId = LocalCharacter.island()
		local zone = Zones.at(root.Position)
		local key = if islandId then islandId elseif zone.deep then "deep" else lastZone
		if key ~= lastZone then
			if lastZone ~= nil then
				if key == "deep" then
					Notices.zone("Open Sea", "Deep water. Secrets surface more often out here.", Color3.fromRGB(150, 210, 255))
				elseif key and Islands.byId[key] then
					local island = Islands.byId[key]
					Notices.zone(island.name, island.blurb)
				end
			end
			lastZone = key
		end
	end
end
