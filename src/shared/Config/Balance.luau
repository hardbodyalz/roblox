--!strict
-- Tuning knobs that don't belong to a single item.

return {
	STARTING_YEN = 500,

	-- Base seconds before a bite, before rod speed and passives.
	BITE_DELAY = { 3, 8 },

	-- Weight roll: min + (max - min) * r ^ WEIGHT_SKEW. Higher = heavy catches rarer.
	WEIGHT_SKEW = 2.4,

	-- Value: weight factor = (kg / midpoint kg) ^ WEIGHT_VALUE_EXP
	WEIGHT_VALUE_EXP = 0.9,

	-- Beginner's Fortune: chance and bonus on Charming/Alluring catches.
	BEGINNERS_FORTUNE_CHANCE = 0.1,
	BEGINNERS_FORTUNE_BONUS = 1.5,

	-- Travel time in seconds = TRAVEL_BASE / boat speed + 1
	TRAVEL_BASE = 150,

	-- Minigame per character rarity.
	--   fishSpeed: how fast the target moves (track widths / second)
	--   erratic:   0..1, how often and how sharply it changes direction
	--   gain/loss: progress % per second while inside / outside the catch bar
	--   glitch:    Corrupted-style visual interference
	Minigame = {
		Charming = { fishSpeed = 0.35, erratic = 0.25, gain = 32, loss = 16 },
		Alluring = { fishSpeed = 0.45, erratic = 0.35, gain = 27, loss = 18 },
		Enchanting = { fishSpeed = 0.55, erratic = 0.45, gain = 23, loss = 20 },
		Bewitching = { fishSpeed = 0.7, erratic = 0.6, gain = 19, loss = 22 },
		Divine = { fishSpeed = 0.85, erratic = 0.72, gain = 16, loss = 24 },
		Eternal = { fishSpeed = 1.0, erratic = 0.85, gain = 13, loss = 26 },
		Corrupted = { fishSpeed = 0.95, erratic = 0.95, gain = 13, loss = 26, glitch = true },
		Mystery = { fishSpeed = 1.1, erratic = 1.0, gain = 11, loss = 28, glitch = true },
	},
	MINIGAME_START_PROGRESS = 30,
	-- Catch bar width (fraction of track) = BAR_BASE + control / BAR_CONTROL_DIV
	BAR_BASE = 0.16,
	BAR_CONTROL_DIV = 350,
	-- Resilience reduces progress loss: loss * (1 - resilience / RESILIENCE_DIV)
	RESILIENCE_DIV = 250,
	-- Catches heavier than the rod's max weight reel slower: gain * max(maxKg / kg, OVERWEIGHT_FLOOR)
	OVERWEIGHT_FLOOR = 0.4,
	-- The server rejects a landed catch faster than this fraction of the theoretical minimum time.
	MIN_REEL_FRACTION = 0.8,
	MAX_REEL_SECONDS = 120,

	-- Catches that trigger a dramatic catch screen / server announcement.
	DRAMATIC_RARITY_ORDER = 5, -- Divine+
	DRAMATIC_MUTATION_ORDER = 5, -- Ethereal+
	ANNOUNCE_RARITY_ORDER = 4, -- Bewitching+
	ANNOUNCE_MUTATION_ORDER = 6, -- Celestial+
}
