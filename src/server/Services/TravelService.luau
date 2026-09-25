--!strict
-- Sailing between islands. Boats exist to reach better waters: the equipped boat's Speed gates
-- which islands you can reach and how long the crossing takes. You respawn where you last sailed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Islands = require(Shared.Config.Islands)
local Equipment = require(Shared.Config.Equipment)
local Travel = require(Shared.Travel)
local Net = require(Shared.Net)
local DataService = require(script.Parent.DataService)
local FishingService = require(script.Parent.FishingService)

local TravelService = {}

local travelling: { [Player]: boolean } = {}
local travelEvent = Net.event("Travel")

local function eventOver(island: Islands.Island): boolean
	return island.event == true and not ReplicatedStorage:GetAttribute("EventActive")
end

function TravelService.teleport(player: Player, islandId: string)
	local island = Islands.byId[islandId]
	local character = player.Character
	if not island or not character or not character:FindFirstChild("HumanoidRootPart") then
		return
	end
	local arrival = Islands.arrivalPosition(island) + Vector3.new(0, 8, 0)
	local look = Vector3.new(island.center.X, arrival.Y, island.center.Z)
	character:PivotTo(CFrame.lookAt(arrival, look))
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
	if eventOver(island) then
		return false, "This event has ended."
	end
	if not Travel.canReach(data.boat, island.id) then
		return false, string.format("Needs a boat with %d+ Speed.", island.minBoatSpeed)
	end

	FishingService.cancel(player)
	travelling[player] = true
	local seconds = Travel.seconds(data.boat, data.island, island.id)
	travelEvent:FireClient(player, { seconds = seconds, to = island.name, boat = Equipment.boatsById[data.boat].name })
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

function TravelService.start()
	-- Respawn on the island you were last on (if you can still reach it).
	DataService.onLoaded(function(player, data)
		local function onCharacter(character: Model)
			local island = Islands.byId[data.island]
			if island and island.id ~= "sakura_shore" and not eventOver(island) then
				character:WaitForChild("HumanoidRootPart", 5)
				task.wait()
				TravelService.teleport(player, island.id)
			end
		end
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end)
end

return TravelService
