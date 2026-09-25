--!strict
-- Records how far through the Harbourmaster's tutorial a player is. The client decides when
-- to advance; the server only accepts forward steps.

local DataService = require(script.Parent.DataService)

local TutorialService = {}

local LAST_STEP = 10

local handlers: { [string]: (Player, any) -> (boolean, any?) } = {}

function handlers.Tutorial(player: Player, payload: any)
	local data = DataService.get(player)
	local step = if type(payload) == "table" then payload.step else nil
	if data and type(step) == "number" and step > data.tutorial and step <= LAST_STEP then
		data.tutorial = math.floor(step)
		return true
	end
	return false
end

TutorialService.handlers = handlers

return TutorialService
