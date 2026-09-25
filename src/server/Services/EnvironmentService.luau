--!strict
-- Server-wide weather cycle and event announcements (weather, Demon Tide).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Weather = require(Shared.Config.Weather)
local Clock = require(Shared.Clock)
local Net = require(Shared.Net)

local EnvironmentService = {}

local rng = Random.new()
local announce = Net.event("Announce")
local forced: string? = nil

local function pickNext(current: string): string
	local total = 0
	for _, w in Weather.list do
		if w.id ~= current then
			total += w.weight
		end
	end
	local r = rng:NextNumber() * total
	for _, w in Weather.list do
		if w.id ~= current then
			r -= w.weight
			if r <= 0 then
				return w.id
			end
		end
	end
	return "Sunny"
end

local function setWeather(id: string)
	local weather = Weather.byId[id]
	local duration = rng:NextInteger(weather.duration[1], weather.duration[2])
	ReplicatedStorage:SetAttribute("Weather", id)
	ReplicatedStorage:SetAttribute("WeatherEnds", Clock.now() + duration)
	if weather.major then
		announce:FireAllClients({
			title = string.upper(weather.name) .. " HAS BEGUN",
			text = weather.blurb,
			color = weather.color,
			big = true,
		})
	end
end

function EnvironmentService.force(id: string)
	if Weather.byId[id] then
		forced = id
	end
end

function EnvironmentService.start()
	setWeather("Sunny")

	task.spawn(function()
		local wasTide = Clock.demonTide()
		while true do
			task.wait(1)
			local current, ends = Clock.weather()
			if forced then
				setWeather(forced)
				forced = nil
			elseif Clock.now() >= ends then
				-- Alternate: events always return to Sunny before the next roll so they feel special.
				setWeather(if current == "Sunny" then pickNext("Sunny") else "Sunny")
			end

			local tide = Clock.demonTide()
			if tide and not wasTide then
				announce:FireAllClients({
					title = "DEMON TIDE HAS RISEN",
					text = "Oni Coast's waters turn red. Demon Waifus and mutations are boosted for 10 minutes.",
					color = Color3.fromRGB(230, 40, 50),
					big = true,
				})
			end
			wasTide = tide
		end
	end)
end

return EnvironmentService
