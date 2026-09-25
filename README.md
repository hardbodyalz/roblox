# Waifu Fishing

Fish → catch a Waifu → watch her rise out of the water → roll rarity, mutation, weight → Keep / Sell / Lock → upgrade → sail further → repeat.

Built with [Rojo](https://github.com/rojo-rbx/rojo) 7.7.0.

## Running it

```bash
rojo build -o "roblox.rbxlx"   # then open in Studio
rojo serve                      # live-sync while editing
```

The world (ocean + islands) is generated when the server starts, so the place file is nearly empty until you press Play.

## Playing

| Input | Does |
| --- | --- |
| `1` / click the 🎣 slot | Take out / put away your rod |
| Hold click (or `E`, R2, the CAST button on touch) | Charge a cast. The meter swings up and down; let go in the gold band for a **Perfect Cast** (more Luck, faster bite) |
| Click while waiting | Reel the line back in |
| Click the **SHAKE** prompts (or Enter / A) | Set the hook after a bite |
| Hold to reel | Keep the 💗 inside your white bar until the line fills |

You can fish **in any water**: the sea, ponds, off a pier, while swimming. You can't cast onto land. Where the bobber lands decides what bites:

- The island whose shore is nearest supplies the character table. Its waters need a boat that could sail there (same Speed gate as the Sail menu).
- **Hotspots** (buoy rings off the piers, and the island ponds) add their Luck / mutation / tag bonus.
- **Open sea** (more than 220 studs from any shore) gives +10 Luck and triples the world-wide secret table.

Once she's landed, the Waifu surfaces where your bobber was, leaps over to stand beside you, and stays until you Keep / Sell / Lock her. Other players see your bobber, your line and your catches too.

Studio test commands (also work for the place owner in live servers), typed in chat:

| Command | Effect |
| --- | --- |
| `/weather HuecoVoid` | Force a weather (`Sunny`, `Rain`, `GoldenHour`, `DiamondStorm`, `EtherealFog`, `CelestialStorm`, `BloodMoon`, `HuecoVoid`, `Mystery`) |
| `/yen 100000` | Give yourself Yen |
| `/serverluck` | 5 minutes of 10× Server Luck |

Saving needs **Game Settings → Security → Enable Studio Access to API Services**. Without it you play on an unsaved profile.

## Where things live

Almost all tuning is data in `src/shared/Config`:

| File | What |
| --- | --- |
| `Characters.luau` | All 46 Waifus: rarity, weight range, tags, colours, look (tags also pick 3D accessories) |
| `Islands.luau` | Islands, hotspots and each island's character table |
| `Rarities.luau` / `Mutations.luau` | The two RNG tiers, values, how Luck scales each rarity |
| `Weather.luau` | Weather events and what they boost |
| `Equipment.luau` | Rods (incl. cast range and model colours), boats, bait, storage tiers |
| `Balance.luau` | Casting, shakes, reel minigame, bite timing, open sea, value curve |
| `Monetization.luau` | Gamepass / product ids (all `0` until created) |

Logic:

- `src/shared/Roll.luau`: the character roll, mutation roll, weight and value (pure functions)
- `src/shared/Modifiers.luau`: folds rod/boat/bait/where-the-bobber-landed/weather/passives/passes into one Luck + mutation table
- `src/shared/Zones.luau` + `Water.luau`: which waters a point belongs to, and whether it's water at all (shared by client aim and server validation)
- `src/server/Router.luau`: the one Request remote, rate-limited, dispatching to each service's `handlers`
- `src/server/Services`: data, fishing, inventory, shop, travel, weather, perks, achievements, rods (the held Tool), admin commands
- `src/server/World/Builder.luau`: placeholder island generator (replace with hand-built maps; keep spot positions from `Islands.spotPosition` and give pond water a `Water = true` attribute)
- `src/server/World/RodModel.luau`: builds each rod as a Tool with a `Tip` attachment for the line
- `src/client/Fishing`: cast / bite / shake / reel flow, charge meter, bobber + line, other players' fishing
- `src/client/Visuals`: the 3D Waifu model, her surfacing animation, weather and lighting
- `src/client/UI`: HUD, reel bar, shake prompts, catch card, windows, tutorial

Tests: `python3 tests/run.py` runs the pure shared modules under the `luau` CLI (`cargo install luau-cli`).

## How the RNG works

1. **Character roll**: the island's table plus the world-wide secrets. Luck multiplies each entry by `1 + luck/100 × rarity.luckGain`, so rarer tiers gain the most, while Corrupted and ??? deliberately gain less.
2. **Mutation roll**: independent of the first. Every non-Normal mutation is multiplied by the hotspot, weather, passes, boosts and passives.

Example: a starter at the Village Pier hotspot gets Crimson Heiress 1 in ~800. Ethereal Crimson Heiress is 1 in ~41,000.

The Perfect Cast flag comes from the client (the server can't see the meter), so its bonus is deliberately small.

## Not built yet

Trading, leaderboards beyond `leaderstats`, real boat sailing (travel is currently a timed transition), secret islands, Void Sea, Neon Tokyo, Spirit Forest, Auto Fish, VIP perks beyond the Yen bonus, real character art and animations (the 3D Waifus and portraits are built from parts / frames), sounds.
