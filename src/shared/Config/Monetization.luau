--!strict
-- Gamepass and developer product ids. 0 = not created yet (treated as not owned / not for sale).
-- Fill these in from the Creator Dashboard once the experience is published.

export type Pass = { id: number, name: string }
export type Product = { id: number, name: string, boost: string, seconds: number }

local Gamepasses: { [string]: Pass } = {
	DoubleLuck = { id = 0, name = "2× Luck" },
	DoubleMutation = { id = 0, name = "2× Mutation" },
	DoubleYen = { id = 0, name = "2× Yen" },
	FastReel = { id = 0, name = "Fast Reel" },
	InfiniteStorage = { id = 0, name = "Infinite Storage" },
	VIP = { id = 0, name = "VIP" },
}

-- Timed boosts sold as developer products. seconds stack if bought again.
local Products: { [string]: Product } = {
	Luck15 = { id = 0, name = "15 min 2× Luck", boost = "Luck", seconds = 15 * 60 },
	Mutation30 = { id = 0, name = "30 min 2× Mutation", boost = "Mutation", seconds = 30 * 60 },
	Yen60 = { id = 0, name = "60 min 2× Yen", boost = "Yen", seconds = 60 * 60 },
	ServerLuck = { id = 0, name = "10× Server Luck", boost = "ServerLuck", seconds = 15 * 60 },
}

return {
	Gamepasses = Gamepasses,
	Products = Products,

	VIP_YEN_BONUS = 1.1,
	FAST_REEL_MULT = 1.25,
	SERVER_LUCK_MULT = 10,
}
