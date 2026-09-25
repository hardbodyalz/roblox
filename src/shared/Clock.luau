--!strict
-- Server-synchronised time of day, moon phase and Demon Tide. Derived purely from
-- workspace:GetServerTimeNow(), so server and every client agree without replication.
-- Weather is random, so it's replicated separately as ReplicatedStorage attributes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Weather = require(script.Parent.Config.Weather)
local Islands = require(script.Parent.Config.Islands)

local Clock = {}

function Clock.now(): number
	return workspace:GetServerTimeNow()
end

-- In-game hour, 0..24. Starts each cycle at 08:00.
function Clock.hour(t: number?): number
	local now = t or Clock.now()
	return (now / Weather.DAY_LENGTH * 24 + 8) % 24
end

function Clock.isNight(t: number?): boolean
	local h = Clock.hour(t)
	return h < 6 or h >= 18.5
end

-- One phase per in-game day.
function Clock.moonPhase(t: number?): string
	local now = t or Clock.now()
	local day = math.floor(now / Weather.DAY_LENGTH)
	return Islands.MOON_PHASES[day % #Islands.MOON_PHASES + 1]
end

function Clock.demonTide(t: number?): (boolean, number)
	local now = t or Clock.now()
	local into = now % Weather.DEMON_TIDE_PERIOD
	if into < Weather.DEMON_TIDE_LENGTH then
		return true, Weather.DEMON_TIDE_LENGTH - into
	end
	return false, Weather.DEMON_TIDE_PERIOD - into
end

function Clock.weather(): (string, number)
	return ReplicatedStorage:GetAttribute("Weather") or "Sunny", ReplicatedStorage:GetAttribute("WeatherEnds") or 0
end

function Clock.serverLuck(): boolean
	return (ReplicatedStorage:GetAttribute("ServerLuckEnds") or 0) > Clock.now()
end

function Clock.env()
	local weather = Clock.weather()
	return {
		weather = weather,
		isNight = Clock.isNight(),
		moonPhase = Clock.moonPhase(),
		demonTide = (Clock.demonTide()),
		serverLuck = Clock.serverLuck(),
	}
end

return Clock
