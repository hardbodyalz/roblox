--!strict
-- The single Request RemoteFunction: rate-limits each player and dispatches to service handlers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

export type Handler = (Player, any) -> (boolean, any?)

local Router = {}

local BURST = 20
local REFILL_PER_SECOND = 10

local handlers: { [string]: Handler } = {}
local budget: { [Player]: { tokens: number, last: number } } = {}

function Router.register(from: { [string]: Handler })
	for action, fn in from do
		assert(handlers[action] == nil, "duplicate handler " .. action)
		handlers[action] = fn
	end
end

local function allow(player: Player): boolean
	local now = os.clock()
	local b = budget[player]
	if not b then
		b = { tokens = BURST, last = now }
		budget[player] = b
	end
	b.tokens = math.min(BURST, b.tokens + (now - b.last) * REFILL_PER_SECOND)
	b.last = now
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

function Router.start()
	Net.func("Request").OnServerInvoke = function(player: Player, action: any, payload: any)
		if type(action) ~= "string" or not handlers[action] then
			return false, "Unknown action."
		end
		if not allow(player) then
			return false, "Slow down!"
		end
		local ok, success, result = pcall(handlers[action], player, payload)
		if not ok then
			warn("[Request]", action, "failed:", success)
			return false, "Something went wrong."
		end
		return success, result
	end
	Players.PlayerRemoving:Connect(function(player)
		budget[player] = nil
	end)
end

return Router
