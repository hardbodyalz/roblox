--!strict
-- Crossing time between islands. Shared so the Sail window shows the same number the server uses.

local Config = script.Parent.Config
local Equipment = require(Config.Equipment)
local Islands = require(Config.Islands)
local Balance = require(Config.Balance)
local Clock = require(script.Parent.Clock)

local Travel = {}

function Travel.seconds(boatId: string, fromIsland: string?, toIsland: string): number
	local boat = Equipment.boatsById[boatId] or Equipment.boatsById.old_minnow
	local speed = boat.speed
	local p = boat.passive.id
	if p == "cherry_current" and (fromIsland == "sakura_shore" or toIsland == "sakura_shore") then
		speed *= 1.1
	elseif p == "swift_current" then
		speed *= 1.15
	elseif p == "lunar_sail" and Clock.isNight() then
		speed *= 1.2
	elseif p == "blood_current" and Clock.weather() == "BloodMoon" then
		speed *= 1.3
	end
	return Balance.TRAVEL_BASE / speed + 1
end

function Travel.canReach(boatId: string, islandId: string): boolean
	local boat = Equipment.boatsById[boatId] or Equipment.boatsById.old_minnow
	local island = Islands.byId[islandId]
	return island ~= nil and boat.speed >= island.minBoatSpeed
end

return Travel
