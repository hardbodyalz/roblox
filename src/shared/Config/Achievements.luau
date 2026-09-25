--!strict
-- Permanent milestones. Not quests: nothing to accept, no rewards to claim.
-- Checks run on the server (AchievementService) against the player's profile.

export type Achievement = { id: string, name: string, desc: string }

local list: { Achievement } = {
	{ id = "first_catch", name = "First Catch", desc = "Catch your first Waifu." },
	{ id = "catches_100", name = "100 Catches", desc = "Catch 100 Waifus." },
	{ id = "catches_1000", name = "1,000 Catches", desc = "Catch 1,000 Waifus." },
	{ id = "mutation_hunter", name = "Mutation Hunter", desc = "Discover 10 different mutated Waifus." },
	{ id = "ethereal_fisher", name = "Ethereal Fisher", desc = "Catch an Ethereal Waifu." },
	{ id = "celestial_fisher", name = "Celestial Fisher", desc = "Catch a Celestial Waifu." },
	{ id = "void_walker", name = "Void Walker", desc = "Catch a Void Waifu." },
	{ id = "impossible", name = "Impossible", desc = "Discover the ??? mutation." },
	{ id = "collector", name = "Collector", desc = "Discover every Waifu on an island." },
	{ id = "millionaire", name = "Millionaire", desc = "Earn ¥1,000,000." },
}

local byId: { [string]: Achievement } = {}
for _, a in list do
	byId[a.id] = a
end

return { list = list, byId = byId }
