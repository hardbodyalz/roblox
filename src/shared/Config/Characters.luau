--!strict
-- Every catch is a character. This is the full launch roster.
--
-- Where a Waifu can be fished (and how often) lives in Islands.luau, not here.
-- kg: weight range. Rolls are skewed toward the light end, so heavy catches are the flex.
-- tags: used by bait, rod and boat passives ("demon", "shrine", "fox", "celestial", ...).
-- hidden: secret characters are not listed in the Collection Book until discovered.
-- unknownName: shown on the catch screen before the real name is revealed.
-- mutationBias: optional per-mutation weighting multipliers for this character.

export type Character = {
	id: string,
	name: string,
	rarity: string,
	kg: { number },
	tags: { string },
	hair: Color3,
	eyes: Color3,
	outfit: Color3,
	look: { string },
	personality: string,
	effect: string,
	hidden: boolean?,
	unknownName: string?,
	valueMult: number?,
	mutationBias: { [string]: number }?,
}

local rgb = Color3.fromRGB

local list: { Character } = {
	-- SAKURA SHORE -------------------------------------------------------------
	{
		id = "miko_airi", name = "Miko Airi", rarity = "Charming", kg = { 4, 30 }, tags = { "shrine" },
		hair = rgb(25, 20, 25), eyes = rgb(140, 90, 50), outfit = rgb(235, 60, 60),
		look = { "Long black hair with a small red ribbon", "White-and-red shrine maiden outfit", "Tiny bell tied around her waist" },
		personality = "Polite, slightly shy", effect = "Small cherry blossoms drift around her",
	},
	{
		id = "nana_kato", name = "Nana Kato", rarity = "Charming", kg = { 4, 28 }, tags = { "school" },
		hair = rgb(150, 90, 50), eyes = rgb(120, 80, 40), outfit = rgb(60, 90, 200),
		look = { "Short chestnut bob", "Blue sailor-style school uniform", "Yellow backpack" },
		personality = "Energetic and friendly", effect = "Little water splashes",
	},
	{
		id = "mimi", name = "Mimi", rarity = "Charming", kg = { 3, 26 }, tags = { "cat" },
		hair = rgb(255, 150, 200), eyes = rgb(255, 110, 170), outfit = rgb(245, 235, 210),
		look = { "Fluffy pink twin tails", "Oversized cream hoodie + shorts", "Cat-ear hood" },
		personality = "Lazy, playful", effect = "Pink bubbles",
	},
	{
		id = "maid_rina", name = "Maid Rina", rarity = "Charming", kg = { 4, 28 }, tags = { "maid" },
		hair = rgb(90, 50, 130), eyes = rgb(160, 110, 230), outfit = rgb(30, 30, 35),
		look = { "Dark purple, shoulder-length hair", "Traditional black-and-white maid dress", "White headband" },
		personality = "Extremely serious about \"proper service\"", effect = "Tiny tea cups briefly appear",
	},
	{
		id = "yuki_hanazawa", name = "Yuki Hanazawa", rarity = "Alluring", kg = { 6, 38 }, tags = { "ice" },
		hair = rgb(215, 220, 230), eyes = rgb(170, 210, 255), outfit = rgb(80, 130, 220),
		look = { "Long silver hair", "White winter cardigan over a blue dress", "Snowflake hair clip" },
		personality = "Quiet and reserved", effect = "Snowflakes",
	},
	{
		id = "hana", name = "Hana", rarity = "Alluring", kg = { 6, 36 }, tags = { "flower" },
		hair = rgb(255, 180, 160), eyes = rgb(90, 190, 110), outfit = rgb(255, 210, 120),
		look = { "Wavy peach-pink hair", "Floral summer dress", "Flower crown" },
		personality = "Cheerful", effect = "Flowers bloom around her",
	},
	{
		id = "kira_amane", name = "Kira Amane", rarity = "Alluring", kg = { 6, 38 }, tags = { "school" },
		hair = rgb(20, 20, 25), eyes = rgb(220, 40, 50), outfit = rgb(25, 25, 30),
		look = { "Black hair with a white streak", "Black jacket, white shirt, dark skirt", "Star-shaped earring" },
		personality = "Confident and sarcastic", effect = "Small black-and-white stars",
	},
	{
		id = "saki", name = "Saki", rarity = "Enchanting", kg = { 10, 55 }, tags = { "ocean" },
		hair = rgb(60, 210, 200), eyes = rgb(90, 230, 230), outfit = rgb(220, 245, 250),
		look = { "Extremely long turquoise hair", "Modern Japanese summer outfit with flowing sleeves", "Shell necklace" },
		personality = "Calm and mysterious", effect = "Floating water ribbons",
		mutationBias = { Diamond = 1.3 },
	},
	{
		id = "reina", name = "Reina", rarity = "Enchanting", kg = { 10, 55 }, tags = { "shrine" },
		hair = rgb(150, 20, 30), eyes = rgb(240, 170, 50), outfit = rgb(180, 30, 30),
		look = { "Dark red high ponytail", "Red-and-black shrine guardian uniform", "Ornamental hairpin" },
		personality = "Serious and protective", effect = "Red leaves swirl around her",
	},
	{
		id = "kitsune_yae", name = "Kitsune Yae", rarity = "Bewitching", kg = { 18, 85 }, tags = { "fox", "shrine" },
		hair = rgb(250, 240, 235), eyes = rgb(255, 200, 60), outfit = rgb(255, 150, 60),
		look = { "Long white hair fading into orange", "Elegant white/orange kimono", "Fox ears + nine giant tails" },
		personality = "Mischievous", effect = "Blue foxfire",
	},
	{
		id = "demon_princess_rei", name = "Demon Princess Rei", rarity = "Divine", kg = { 30, 130 }, tags = { "demon" },
		hair = rgb(200, 20, 40), eyes = rgb(255, 210, 60), outfit = rgb(40, 10, 15),
		look = { "Long crimson hair", "Ornate black-and-red ceremonial dress", "Small curved horns + floating red ribbons" },
		personality = "Regal and intimidating", effect = "Crimson flames",
	},
	{
		id = "crimson_heiress", name = "Crimson Heiress", rarity = "Eternal", kg = { 45, 190 }, tags = { "demon" },
		hair = rgb(210, 10, 35), eyes = rgb(255, 40, 40), outfit = rgb(15, 10, 12),
		look = { "Extremely long crimson hair", "Elegant black dress with deep crimson accents", "Small black horns, ornate gold hairpiece", "Floats slightly above the ground" },
		personality = "Calm, arrogant, composed", effect = "Red particles + black roses",
	},
	{
		id = "the_forgotten", name = "The Forgotten", rarity = "Corrupted", kg = { 60, 260 }, tags = { "shrine", "corrupted" },
		hair = rgb(10, 10, 12), eyes = rgb(0, 0, 0), outfit = rgb(120, 20, 30),
		look = { "Extremely long black hair, sections appear glitched", "One normal eye, one completely black eye", "Distorted Sakura Shore shrine maiden outfit", "Broken shrine bells" },
		personality = "Doesn't speak", effect = "The screen briefly glitches",
		hidden = true, unknownName = "???",
	},

	-- ONI COAST ----------------------------------------------------------------
	{
		id = "oni_apprentice", name = "Oni Apprentice", rarity = "Charming", kg = { 5, 32 }, tags = { "demon" },
		hair = rgb(20, 20, 25), eyes = rgb(220, 60, 50), outfit = rgb(160, 30, 30),
		look = { "Short black hair", "Small red horns", "Red-and-black training kimono", "Wooden practice club" },
		personality = "Embarrassed", effect = "Small flame particles",
	},
	{
		id = "fox_maiden", name = "Fox Maiden", rarity = "Alluring", kg = { 7, 40 }, tags = { "fox", "shrine" },
		hair = rgb(255, 140, 40), eyes = rgb(90, 200, 90), outfit = rgb(245, 240, 230),
		look = { "Orange hair", "Fox ears + one large fluffy tail", "White shrine outfit with orange details" },
		personality = "Playful", effect = "Floating foxfire",
	},
	{
		id = "demon_maid", name = "Demon Maid", rarity = "Alluring", kg = { 7, 40 }, tags = { "demon", "maid" },
		hair = rgb(120, 60, 180), eyes = rgb(230, 40, 50), outfit = rgb(40, 10, 15),
		look = { "Purple twin tails", "Small black horns", "Black-and-red maid outfit" },
		personality = "Very serious", effect = "Black smoke",
	},
	{
		id = "oni_warrior", name = "Oni Warrior", rarity = "Enchanting", kg = { 14, 65 }, tags = { "demon" },
		hair = rgb(30, 50, 120), eyes = rgb(255, 200, 60), outfit = rgb(25, 20, 25),
		look = { "Dark blue hair", "Large crimson horns", "Black armour with red cloth", "Ornamental sheathed sword" },
		personality = "Stoic", effect = "Flame aura",
	},
	{
		id = "kitsune_princess", name = "Kitsune Princess", rarity = "Enchanting", kg = { 12, 60 }, tags = { "fox", "demon" },
		hair = rgb(250, 250, 250), eyes = rgb(255, 200, 60), outfit = rgb(210, 40, 50),
		look = { "White hair with red tips", "Fox ears + six tails", "Red-and-white royal kimono" },
		personality = "Elegant", effect = "Red torii gates briefly appear behind her",
	},
	{
		id = "demon_princess", name = "Demon Princess", rarity = "Bewitching", kg = { 22, 95 }, tags = { "demon" },
		hair = rgb(15, 10, 15), eyes = rgb(220, 20, 40), outfit = rgb(180, 20, 30),
		look = { "Waist-length black hair", "Four small horns", "Elaborate red dress + large black cape" },
		personality = "Haughty", effect = "Dark flame aura",
	},
	{
		id = "nine_tail_empress", name = "Nine-Tail Empress", rarity = "Divine", kg = { 35, 140 }, tags = { "fox", "demon" },
		hair = rgb(250, 245, 245), eyes = rgb(255, 205, 60), outfit = rgb(250, 250, 245),
		look = { "White hair with crimson streaks", "Nine enormous tails", "White ceremonial kimono + ornate crown" },
		personality = "Imperious", effect = "Constant floating foxfire",
	},
	{
		id = "forgotten_oni", name = "Forgotten Oni", rarity = "Eternal", kg = { 50, 200 }, tags = { "demon" },
		hair = rgb(200, 205, 215), eyes = rgb(150, 10, 25), outfit = rgb(60, 10, 15),
		look = { "Very long silver hair, one broken horn", "Ancient black/red ceremonial armour", "Cracked porcelain mask at her waist", "Faint glowing markings on one arm" },
		personality = "Weary, ancient", effect = "Red particles constantly fall from her",
	},

	-- MOONLIT VILLAGE ----------------------------------------------------------
	{
		id = "ghost_girl", name = "Ghost Girl", rarity = "Charming", kg = { 2, 20 }, tags = { "ghost" },
		hair = rgb(245, 245, 255), eyes = rgb(160, 200, 255), outfit = rgb(235, 240, 255),
		look = { "Short white hair", "White oversized dress", "Semi-transparent lower body", "Small blue flame" },
		personality = "Curious", effect = "Fades in and out",
	},
	{
		id = "black_cat_girl", name = "Black Cat Girl", rarity = "Charming", kg = { 4, 28 }, tags = { "cat" },
		hair = rgb(15, 15, 20), eyes = rgb(255, 220, 40), outfit = rgb(40, 40, 50),
		look = { "Short black hair", "Cat ears + black tail", "Dark oversized sweater" },
		personality = "Very unimpressed", effect = "Paw prints",
	},
	{
		id = "witch_girl", name = "Witch Girl", rarity = "Alluring", kg = { 6, 38 }, tags = { "witch" },
		hair = rgb(140, 70, 200), eyes = rgb(80, 220, 110), outfit = rgb(80, 30, 120),
		look = { "Purple hair", "Black witch hat + purple cloak", "Small floating spellbook" },
		personality = "Bookish", effect = "Green magical particles",
	},
	{
		id = "crimson_vampire", name = "Crimson Vampire", rarity = "Alluring", kg = { 6, 38 }, tags = { "vampire" },
		hair = rgb(110, 15, 35), eyes = rgb(230, 30, 40), outfit = rgb(20, 15, 20),
		look = { "Long burgundy hair", "Black Victorian dress", "Small fangs + bat-shaped hair accessory" },
		personality = "Aloof", effect = "Red mist",
	},
	{
		id = "moon_witch", name = "Moon Witch", rarity = "Enchanting", kg = { 10, 55 }, tags = { "witch", "moon" },
		hair = rgb(170, 200, 240), eyes = rgb(80, 150, 255), outfit = rgb(30, 40, 100),
		look = { "Long silver-blue hair", "Dark blue witch robes", "Crescent-moon hat" },
		personality = "Calm", effect = "Floating moon fragments",
	},
	{
		id = "blood_countess", name = "Blood Countess", rarity = "Bewitching", kg = { 20, 90 }, tags = { "vampire" },
		hair = rgb(120, 10, 20), eyes = rgb(220, 20, 30), outfit = rgb(15, 10, 12),
		look = { "Extremely long dark-red hair", "Victorian black dress", "Red gemstone necklace + small black crown" },
		personality = "Cruel elegance", effect = "Blood-red particles",
	},
	{
		id = "night_empress", name = "Night Empress", rarity = "Divine", kg = { 30, 130 }, tags = { "moon" },
		hair = rgb(20, 30, 90), eyes = rgb(170, 90, 255), outfit = rgb(20, 20, 60),
		look = { "Long midnight-blue hair", "Black-and-blue royal dress", "Crescent crown", "Her shadow moves independently" },
		personality = "Silent sovereign", effect = "Floating stars",
	},
	{
		id = "lunar_sovereign", name = "Lunar Sovereign", rarity = "Eternal", kg = { 45, 185 }, tags = { "moon", "celestial" },
		hair = rgb(230, 240, 255), eyes = rgb(190, 110, 255), outfit = rgb(200, 215, 255),
		look = { "White hair with a blue gradient", "Enormous flowing celestial robe", "Floating crescent-ring crown", "A miniature moon behind her" },
		personality = "Distant, absolute", effect = "Stars orbit her",
	},
	{
		id = "the_unburied", name = "The Unburied", rarity = "Corrupted", kg = { 60, 250 }, tags = { "ghost", "corrupted" },
		hair = rgb(8, 8, 10), eyes = rgb(255, 20, 20), outfit = rgb(60, 55, 60),
		look = { "Long black hair covering most of her face", "One glowing red eye", "Torn old Victorian dress", "Floating pieces of broken cemetery stone" },
		personality = "Doesn't speak", effect = "The music distorts",
		hidden = true, unknownName = "???",
	},

	-- CELESTIAL HAVEN ----------------------------------------------------------
	{
		id = "sky_maiden", name = "Sky Maiden", rarity = "Charming", kg = { 3, 26 }, tags = { "celestial" },
		hair = rgb(255, 230, 130), eyes = rgb(90, 160, 255), outfit = rgb(250, 250, 255),
		look = { "Blonde hair", "White dress with light-blue ribbons", "Small feather accessories" },
		personality = "Dreamy", effect = "Cloud particles",
	},
	{
		id = "celestial_priestess", name = "Celestial Priestess", rarity = "Alluring", kg = { 6, 38 }, tags = { "celestial", "shrine" },
		hair = rgb(250, 250, 250), eyes = rgb(255, 200, 60), outfit = rgb(255, 235, 170),
		look = { "Long white hair", "White-and-gold ceremonial robes", "Halo-like ring behind her head" },
		personality = "Devout", effect = "Floating golden symbols",
	},
	{
		id = "valkyrie", name = "Valkyrie", rarity = "Enchanting", kg = { 14, 65 }, tags = { "celestial" },
		hair = rgb(210, 215, 225), eyes = rgb(80, 150, 255), outfit = rgb(200, 205, 215),
		look = { "Silver hair", "White/silver armour with wing-shaped shoulders", "Small feather cape + golden halo" },
		personality = "Proud", effect = "Feathers",
	},
	{
		id = "seraph", name = "Seraph", rarity = "Bewitching", kg = { 20, 90 }, tags = { "celestial" },
		hair = rgb(255, 215, 100), eyes = rgb(90, 170, 255), outfit = rgb(255, 245, 220),
		look = { "Long golden hair", "Six enormous white wings", "White/gold dress + floating halo" },
		personality = "Serene", effect = "Constant golden light",
	},
	{
		id = "heavenly_guardian", name = "Heavenly Guardian", rarity = "Bewitching", kg = { 24, 95 }, tags = { "celestial" },
		hair = rgb(200, 170, 90), eyes = rgb(80, 200, 110), outfit = rgb(240, 240, 235),
		look = { "Dark blonde hair", "Ornate white armour + giant feathered wings", "Gold crown + shield-shaped halo" },
		personality = "Dutiful", effect = "Protective light",
	},
	{
		id = "six_winged_seraph", name = "Six-Winged Seraph", rarity = "Divine", kg = { 35, 140 }, tags = { "celestial" },
		hair = rgb(255, 255, 255), eyes = rgb(255, 210, 60), outfit = rgb(255, 250, 240),
		look = { "White hair", "Six massive, independently moving wings", "Multiple golden halos", "Giant white ceremonial robes" },
		personality = "Overwhelming", effect = "Golden particles constantly falling",
	},
	{
		id = "fallen_angel", name = "Fallen Angel", rarity = "Divine", kg = { 30, 130 }, tags = { "celestial", "demon" },
		hair = rgb(15, 10, 20), eyes = rgb(160, 90, 255), outfit = rgb(40, 20, 60),
		look = { "Long black hair", "One white wing, one black wing", "Dark celestial dress", "Cracked halo" },
		personality = "Melancholic", effect = "Purple-black particles",
	},
	{
		id = "broken_seraph", name = "Broken Seraph", rarity = "Eternal", kg = { 45, 190 }, tags = { "celestial", "void" },
		hair = rgb(245, 245, 245), eyes = rgb(255, 220, 90), outfit = rgb(230, 230, 230),
		look = { "White hair with black ends", "Six wings, partially broken", "Cracked golden halo", "Golden cracks across her body" },
		personality = "Something that shouldn't exist", effect = "Floating feathers slowly disintegrate",
	},

	-- DEMON ACADEMY (event) ----------------------------------------------------
	{
		id = "crimson_heiress_academy", name = "Crimson Heiress (Academy)", rarity = "Eternal", kg = { 45, 190 }, tags = { "demon", "school", "event" },
		hair = rgb(210, 10, 35), eyes = rgb(255, 40, 40), outfit = rgb(20, 20, 30),
		look = { "Long crimson hair, small horns", "Black academy blazer + crimson tie", "Gold school crest" },
		personality = "Student council president energy", effect = "Red aura",
	},
	{
		id = "fallen_nun", name = "Fallen Nun", rarity = "Bewitching", kg = { 20, 90 }, tags = { "demon", "school", "event" },
		hair = rgb(210, 210, 220), eyes = rgb(160, 90, 230), outfit = rgb(25, 25, 30),
		look = { "Long silver hair", "Black-and-white nun-inspired academy uniform", "Small black halo + dark wings" },
		personality = "Too quiet", effect = "Purple particles",
	},
	{
		id = "white_dragon_princess", name = "White Dragon Princess", rarity = "Divine", kg = { 35, 140 }, tags = { "school", "ice", "event" },
		hair = rgb(250, 250, 255), eyes = rgb(90, 160, 255), outfit = rgb(240, 245, 255),
		look = { "Very long white hair", "White academy uniform with blue accents", "Small dragon horns + white dragon tail" },
		personality = "Proud", effect = "Ice particles",
	},
	{
		id = "sword_saint", name = "Sword Saint", rarity = "Divine", kg = { 30, 130 }, tags = { "school", "event" },
		hair = rgb(255, 220, 110), eyes = rgb(80, 150, 255), outfit = rgb(245, 245, 250),
		look = { "Long blonde ponytail", "White academy uniform with gold trim", "Decorative sword at her side" },
		personality = "Disciplined", effect = "Blue aura",
	},
	{
		id = "ice_queen", name = "Ice Queen", rarity = "Eternal", kg = { 45, 185 }, tags = { "school", "ice", "event" },
		hair = rgb(180, 220, 250), eyes = rgb(60, 240, 255), outfit = rgb(220, 235, 255),
		look = { "Long pale-blue hair", "White/blue academy uniform + small crown", "Ice crystals float around her" },
		personality = "Cold", effect = "Constant cold mist",
	},

	-- GLOBAL SECRETS -----------------------------------------------------------
	{
		id = "the_drowned", name = "The Drowned", rarity = "Corrupted", kg = { 70, 280 }, tags = { "ocean", "corrupted" },
		hair = rgb(5, 10, 15), eyes = rgb(120, 230, 255), outfit = rgb(30, 50, 80),
		look = { "Completely soaked black hair", "Pale blue skin, one glowing eye", "Torn sailor outfit", "Water constantly drips upward" },
		personality = "Doesn't speak", effect = "Tiny fish silhouettes swim through her",
		hidden = true, unknownName = "???",
	},
	{
		id = "starless", name = "Starless", rarity = "Eternal", kg = { 50, 200 }, tags = { "void", "celestial" },
		hair = rgb(0, 0, 0), eyes = rgb(255, 255, 255), outfit = rgb(10, 10, 25),
		look = { "Long pitch-black hair", "Completely white eyes", "Black celestial dress, no halo", "Her shadow looks like a galaxy" },
		personality = "Empty", effect = "Tiny stars disappear around her",
		hidden = true, mutationBias = { Void = 3 },
	},
	{
		id = "unknown", name = "???", rarity = "Mystery", kg = { 1, 999 }, tags = { "void" },
		hair = rgb(255, 255, 255), eyes = rgb(0, 0, 0), outfit = rgb(128, 128, 128),
		look = { "???" },
		personality = "???", effect = "???",
		hidden = true, unknownName = "???",
	},
}

local byId: { [string]: Character } = {}
for _, c in list do
	assert(byId[c.id] == nil, "duplicate character id " .. c.id)
	byId[c.id] = c
end

local function hasTag(c: Character, tag: string): boolean
	return table.find(c.tags, tag) ~= nil
end

return {
	list = list,
	byId = byId,
	hasTag = hasTag,
}
