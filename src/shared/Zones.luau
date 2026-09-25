--!strict
-- Which waters a point belongs to. The client uses this for the HUD, the server to roll a catch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = script.Parent.Config
local Islands = require(Config.Islands)
local Balance = require(Config.Balance)
local Modifiers = require(script.Parent.Modifiers)

local Zones = {}

export type Zone = {
	island: Islands.Island?,
	spot: Islands.Spot?, -- hotspot, if the point is inside one
	deep: boolean, -- open water far from any shore
}

local function eventActive(): boolean
	return ReplicatedStorage:GetAttribute("EventActive") == true
end

function Zones.at(position: Vector3): Zone
	local active = eventActive()
	local island, gap = Islands.zoneAt(position, function(candidate)
		return not candidate.event or active
	end)
	if not island then
		return { deep = true }
	end
	return {
		island = island,
		spot = Islands.hotspotAt(island, position),
		deep = gap > Balance.DEEP_WATER_DISTANCE,
	}
end

function Zones.cast(zone: Zone, perfect: boolean): Modifiers.Cast
	return {
		island = if zone.island then zone.island.id else nil,
		spot = if zone.spot then zone.spot.id else nil,
		deep = zone.deep,
		perfect = perfect,
	}
end

-- "Lighthouse", "Open Sea · Oni Coast", "Sakura Shore waters"
function Zones.describe(zone: Zone): string
	if zone.spot then
		return zone.spot.name
	end
	local islandName = if zone.island then zone.island.name else "?"
	if zone.deep then
		return "Open Sea · " .. islandName
	end
	return islandName .. " waters"
end

return Zones
