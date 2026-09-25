--!strict
-- Character rarity tiers. These describe how rare the *Waifu* is, never her mutation.
--
-- luckGain: how strongly Luck pushes this tier's encounter weight up.
--   weight' = weight * (1 + luck / 100 * luckGain)
--   Rarer tiers gain more, but Corrupted / ??? deliberately resist Luck so they stay genuinely rare.
-- baseValue: Yen before the character, weight and mutation multipliers.
-- difficulty: key into Balance.Minigame.

export type Rarity = {
	id: string,
	name: string,
	order: number,
	color: Color3,
	baseValue: number,
	luckGain: number,
	difficulty: string,
	announce: string?,
}

local list: { Rarity } = {
	{ id = "Charming", name = "Charming", order = 1, color = Color3.fromRGB(190, 200, 210), baseValue = 40, luckGain = 0, difficulty = "Charming" },
	{ id = "Alluring", name = "Alluring", order = 2, color = Color3.fromRGB(110, 220, 130), baseValue = 110, luckGain = 0.2, difficulty = "Alluring" },
	{ id = "Enchanting", name = "Enchanting", order = 3, color = Color3.fromRGB(80, 170, 255), baseValue = 300, luckGain = 0.4, difficulty = "Enchanting" },
	{ id = "Bewitching", name = "Bewitching", order = 4, color = Color3.fromRGB(190, 100, 255), baseValue = 1200, luckGain = 0.6, difficulty = "Bewitching", announce = "RARE WAIFU CAUGHT" },
	{ id = "Divine", name = "Divine", order = 5, color = Color3.fromRGB(255, 215, 90), baseValue = 6000, luckGain = 0.8, difficulty = "Divine", announce = "DIVINE WAIFU CAUGHT" },
	{ id = "Eternal", name = "Eternal", order = 6, color = Color3.fromRGB(255, 70, 90), baseValue = 40000, luckGain = 1.0, difficulty = "Eternal", announce = "ETERNAL WAIFU CAUGHT" },
	{ id = "Corrupted", name = "Corrupted", order = 7, color = Color3.fromRGB(120, 0, 30), baseValue = 120000, luckGain = 0.6, difficulty = "Corrupted", announce = "CORRUPTED DISCOVERY" },
	{ id = "Mystery", name = "???", order = 8, color = Color3.fromRGB(255, 255, 255), baseValue = 500000, luckGain = 0.3, difficulty = "Mystery", announce = "???" },
}

local byId: { [string]: Rarity } = {}
for _, r in list do
	byId[r.id] = r
end

return {
	list = list,
	byId = byId,
}
