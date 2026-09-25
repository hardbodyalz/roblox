--!strict
-- Sailing between islands. Boats exist to reach better waters: the equipped boat's Speed gates
-- which islands you can reach and how long the crossing takes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Islands = require(Shared.Config.Islands)
local Equipment = require(Shared.Config.Equipment)
local Balance = require(Shared.Config.Balance)
local Clock = require(Shared.Clock)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local FishingService = require(script.Parent.FishingService)

local TravelService = {}

local travelling: { [Player]: boolean } = {}
local travelEvent = Net.event("Travel")

function TravelService.travelSeconds(boatId: string, fromIsland: string?, toIsland: string): number
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

function TravelService.teleport(player: Player, islandId: string)
	local island = Islands.byId[islandId]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local arrival = Islands.arrivalPosition(island)
	local look = Vector3.new(island.center.X, arrival.Y, island.center.Z)
	;(character :: Model):PivotTo(CFrame.lookAt(arrival + Vector3.new(0, 8, 0), look + Vector3.new(0, 8, 0)))
end

local handlers: { [string]: (Player, any) -> (boolean, any?) } = {}

function handlers.Travel(player: Player, payload: any)
	local data = DataService.get(player)
	local id = if type(payload) == "table" and type(payload.id) == "string" then payload.id else nil
	local island = if id then Islands.byId[id] else nil
	if not data or not island then
		return false, "Unknown destination."
	end
	if travelling[player] then
		return false, "Already sailing."
	end
	if island.event and not ReplicatedStorage:GetAttribute("EventActive") then
		return false, "This event has ended."
	end
	local boat = Equipment.boatsById[data.boat]
	if boat.speed < island.minBoatSpeed then
		return false, string.format("Needs a boat with %d+ Speed.", island.minBoatSpeed)
	end

	FishingService.cancel(player)
	travelling[player] = true
	local seconds = TravelService.travelSeconds(data.boat, data.island, island.id)
	travelEvent:FireClient(player, { seconds = seconds, to = island.name, boat = boat.name })
	task.delay(seconds, function()
		travelling[player] = nil
		if player.Parent then
			data.island = island.id
			TravelService.teleport(player, island.id)
		end
	end)
	return true, seconds
end

TravelService.handlers = handlers

return TravelService
