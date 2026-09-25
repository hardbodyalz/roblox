--!strict
-- Client entry point.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Islands = require(ReplicatedStorage.Shared.Config.Islands)

local State = require(script.State)
local Remote = require(script.Remote)
local Fishing = require(script.Fishing)
local Atmosphere = require(script.Atmosphere)
local UI = script.UI
local Notices = require(UI.Notices)
local Hud = require(UI.Hud)
local Tutorial = require(UI.Tutorial)
local SailWindow = require(UI.SailWindow)
require(UI.InventoryWindow)
require(UI.CollectionWindow)
require(UI.ShopWindow)
require(UI.AchievementsWindow)

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

Remote.setErrorHandler(Notices.error)
Notices.start()
Atmosphere.start()
Fishing.start()
Hud.bindFishing(Fishing)
Hud.start()
SailWindow.setIslandGetter(Hud.currentIsland)

State.wait()
Tutorial.start()

-- Island arrival toasts.
local lastIsland: string? = nil
while true do
	task.wait(1)
	local id = Hud.currentIsland()
	if id and id ~= lastIsland then
		local island = Islands.byId[id]
		if lastIsland ~= nil then
			Notices.announce({ title = string.upper(island.name), text = island.blurb, color = Color3.fromRGB(255, 200, 230), quiet = true })
		end
		lastIsland = id
	end
end
