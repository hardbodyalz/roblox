--!strict
-- Tuning knobs that don't belong to a single item.

return {
	STARTING_YEN = 500,

	-- Base seconds before a bite, before rod speed and passives.
	BITE_DELAY = { 3, 8 },

	-- Casting. Hold to charge; the meter swings 0 -> 1 -> 0 at CHARGE_SPEED per second.
	-- Distance = lerp(CAST_MIN_RANGE, rod.castRange, power).
	CHARGE_SPEED = 1.1,
	CAST_MIN_RANGE = 6,
	-- Power at or above this is a Perfect Cast: more Luck and a faster bite.
	PERFECT_CAST = 0.92,
	PERFECT_LUCK_MULT = 1.2,
	PERFECT_BITE_SPEED = 0.25,
	-- The server accepts casts this many studs past the rod's range (latency / movement).
	CAST_RANGE_MARGIN = 12,
	-- Walking this far past your rod's range from the bobber reels the line in.
	LINE_SNAP_MARGIN = 20,

	-- Shake phase between the bite and the reel: click the SHAKE prompts.
	-- Count per rarity difficulty; each 40 rod Control removes one (minimum 1).
	Shakes = {
		Charming = 2, Alluring = 3, Enchanting = 3, Bewitching = 4,
		Divine = 5, Eternal = 6, Corrupted = 6, Mystery = 7,
	},
	SHAKE_CONTROL_STEP = 40,
	SHAKE_TIMEOUT = 8, -- seconds for the whole shake phase before she slips away

	-- Open water: far from any shore the ocean is deep. Secrets surface more often there.
	DEEP_WATER_DISTANCE = 220, -- studs past an island's shoreline
	DEEP_WATER_LUCK = 10,
	DEEP_WATER_SECRET_MULT = 3,

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
