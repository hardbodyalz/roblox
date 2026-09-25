-- Behaviour checks for zones, hotspots, travel gating, modifiers and rolls. Run with: python3 tests/run.py
local RS = proxy("ReplicatedStorage")
local Islands = require(RS.Shared.Config.Islands)
local Balance = require(RS.Shared.Config.Balance)
local Rarities = require(RS.Shared.Config.Rarities)
local Equipment = require(RS.Shared.Config.Equipment)
local Characters = require(RS.Shared.Config.Characters)
local Zones = require(RS.Shared.Zones)
local Modifiers = require(RS.Shared.Modifiers)
local Roll = require(RS.Shared.Roll)
local Travel = require(RS.Shared.Travel)

local passed, failed = 0, 0
local function check(name, cond, extra)
	if cond then passed += 1 else failed += 1; print("FAIL " .. name .. " " .. tostring(extra or "")) end
end

-- Every rarity has minigame + shake tuning; every rod has the new fields.
for _, r in Rarities.list do
	check("minigame " .. r.id, Balance.Minigame[r.difficulty] ~= nil)
	check("shakes " .. r.id, Balance.Shakes[r.difficulty] ~= nil)
end
for _, rod in Equipment.rods do
	check("rod fields " .. rod.id, rod.castRange ~= nil and rod.color ~= nil and rod.accent ~= nil)
end
-- Every table entry points at a real character.
for _, island in Islands.list do
	for _, e in island.table do check("char " .. e.id, Characters.byId[e.id] ~= nil) end
end

-- Zones and hotspots
local function spotId(z) return z.spot and z.spot.id end
local function islandId(z) return z.island and z.island.id end
local sakura = Islands.byId.sakura_shore
for _, island in Islands.list do
	for _, spot in island.spots do
		local c = Islands.hotspotCenter(island, spot)
		local z = Zones.at(c)
		check("hotspot centre " .. spot.id, islandId(z) == island.id and spotId(z) == spot.id, tostring(islandId(z)) .. "/" .. tostring(spotId(z)))
		check("hotspot not deep " .. spot.id, not z.deep)
	end
end
local pier = Islands.spotsById.village_pier
local tip = Islands.spotPosition(sakura, pier)
local c = Islands.hotspotCenter(sakura, pier)
local reach = (c - tip).Magnitude + Islands.hotspotRadius(pier)
check("pier hotspot reachable with the Old Rod", (c - tip).Magnitude - Islands.hotspotRadius(pier) < Equipment.rodsById.old_rod.castRange, reach)
local z = Zones.at(Vector3.new(0, 0, 250))
check("plain sakura water", islandId(z) == "sakura_shore" and z.spot == nil and not z.deep, spotId(z))
z = Zones.at(Vector3.new(-420, 0, 250))
check("open sea is deep", z.deep, islandId(z))
z = Zones.at(Vector3.new(0, 0, 650))
check("sea under Celestial Haven is not Celestial", islandId(z) ~= "celestial_haven", islandId(z))
z = Zones.at(Vector3.new(700, 0, -250))
check("oni waters", islandId(z) == "oni_coast", islandId(z))
check("describe", Zones.describe(Zones.at(c)) == "Village Pier")
ATTRS.EventActive = false
z = Zones.at(Vector3.new(0, 0, -850))
check("ended event island falls back", islandId(z) ~= "demon_academy", islandId(z))
ATTRS.EventActive = true
check("event island when active", islandId(Zones.at(Vector3.new(0, 0, -850))) == "demon_academy")

-- Travel gating
check("old boat reaches sakura", Travel.canReach("old_minnow", "sakura_shore"))
check("old boat can't reach oni", not Travel.canReach("old_minnow", "oni_coast"))
check("bluefin reaches moonlit", Travel.canReach("bluefin", "moonlit_village"))

-- Modifiers: perfect cast and deep water
local perks = Modifiers.perksFrom({}, {}, 0, 0)
local env = { weather = "Sunny", isNight = false, moonPhase = "Full", demonTide = false, serverLuck = false }
local loadout = { rod = "old_rod", boat = "old_minnow", bait = "normal" }
local plain = Modifiers.compute(loadout, { island = "sakura_shore" }, env, perks)
local perfect = Modifiers.compute(loadout, { island = "sakura_shore", perfect = true }, env, perks)
local deep = Modifiers.compute(loadout, { island = "sakura_shore", deep = true }, env, perks)
local lighthouse = Modifiers.compute(loadout, { island = "sakura_shore", spot = "lighthouse" }, env, perks)
check("base luck", plain.luck == 5, plain.luck)
check("perfect luck", math.abs(perfect.luck - 5 * Balance.PERFECT_LUCK_MULT) < 1e-9, perfect.luck)
check("perfect bite", perfect.biteSpeed > plain.biteSpeed)
check("deep luck", deep.luck == 5 + Balance.DEEP_WATER_LUCK, deep.luck)
check("deep secrets", deep.secretMult == Balance.DEEP_WATER_SECRET_MULT)
check("hotspot luck", lighthouse.luck == 30, lighthouse.luck)
local boosted = Modifiers.perksFrom({ DoubleLuck = true }, { Luck = 10 }, 5, 1)
check("perksFrom", boosted.doubleLuck and boosted.luckBoost and boosted.collectorBoost and not boosted.fastReel)

-- Rolls: deep water triples the world secrets' share
local oddsPlain = Roll.odds(Roll.characterWeights("sakura_shore", "Sunny", plain))
local oddsDeep = Roll.odds(Roll.characterWeights("sakura_shore", "Sunny", deep))
check("secret odds rise in deep water", oddsDeep.the_drowned > oddsPlain.the_drowned * 2.5, oddsDeep.the_drowned / oddsPlain.the_drowned)
local total = 0
for _, p in oddsDeep do total += p end
check("odds sum to 1", math.abs(total - 1) < 1e-9, total)

print(string.format("Crimson Heiress at the Village Pier hotspot: 1 in %d", math.floor(1 / Roll.odds(Roll.characterWeights("sakura_shore", "Sunny", Modifiers.compute(loadout, { island = "sakura_shore", spot = "village_pier" }, env, perks))).crimson_heiress + 0.5)))
print(string.format("%d passed, %d failed", passed, failed))
