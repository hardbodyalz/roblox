--!strict
-- Server entry point: builds the world, wires request handlers and starts every service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Router = require(script.Router)
local Builder = require(script.World.Builder)

local Services = script.Services
local DataService = require(Services.DataService)
local PerkService = require(Services.PerkService)
local EnvironmentService = require(Services.EnvironmentService)
local FishingService = require(Services.FishingService)
local InventoryService = require(Services.InventoryService)
local ShopService = require(Services.ShopService)
local TravelService = require(Services.TravelService)
local TutorialService = require(Services.TutorialService)
local AchievementService = require(Services.AchievementService)
local RodService = require(Services.RodService)
local AdminService = require(Services.AdminService)
local Leaderstats = require(Services.Leaderstats)

-- Limited-time event islands. Flip to false when Demon Academy ends: its Waifus stay tradeable
-- and in inventories, they just can't be fished any more.
ReplicatedStorage:SetAttribute("EventActive", true)

Builder.build()

Router.register(FishingService.handlers)
Router.register(InventoryService.handlers)
Router.register(ShopService.handlers)
Router.register(TravelService.handlers)
Router.register(TutorialService.handlers)

DataService.onLoaded(function(player, data)
	Leaderstats.create(player, data.yen, data.catches)
	AchievementService.check(player)
end)

Router.start()
PerkService.start()
RodService.start()
TravelService.start()
AdminService.start()
EnvironmentService.start()
FishingService.start()
DataService.start()
