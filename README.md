# Waifu Fishing

Fish → catch a Waifu → roll rarity, mutation, weight → Keep / Sell / Lock → upgrade → sail further → repeat.

Built with [Rojo](https://github.com/rojo-rbx/rojo) 7.7.0.

## Running it

```bash
rojo build -o "roblox.rbxlx"   # then open in Studio
rojo serve                      # live-sync while editing
```

The world (ocean + islands) is generated when the server starts, so the place file is nearly empty until you press Play.

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
| `Characters.luau` | All 46 Waifus: rarity, weight range, tags, colours, look |
| `Islands.luau` | Islands, fishing spots and each island's character table |
| `Rarities.luau` / `Mutations.luau` | The two RNG tiers, values, how Luck scales each rarity |
| `Weather.luau` | Weather events and what they boost |
| `Equipment.luau` | Rods, boats, bait, storage tiers |
| `Balance.luau` | Minigame difficulty, bite timing, value curve |
| `Monetization.luau` | Gamepass / product ids (all `0` until created) |

Logic:

- `src/shared/Roll.luau`: the character roll, mutation roll, weight and value (pure functions)
- `src/shared/Modifiers.luau`: folds rod/boat/bait/spot/weather/passives/passes into one Luck + mutation table
- `src/server/Services`: data, fishing, inventory, shop, travel, weather, perks, achievements
- `src/server/World/Builder.luau`: placeholder island generator (replace with hand-built maps; keep spot positions from `Islands.spotPosition`)
- `src/client`: HUD, minigame, catch screen, windows, weather visuals, tutorial

## How the RNG works

1. **Character roll**: the island's table. Luck multiplies each entry by `1 + luck/100 × rarity.luckGain`, so rarer tiers gain the most, while Corrupted and ??? deliberately gain less.
2. **Mutation roll**: independent of the first. Every non-Normal mutation is multiplied by the spot, weather, passes, boosts and passives.

Example: a starter at Village Pier gets Crimson Heiress 1 in ~800. Ethereal Crimson Heiress is 1 in ~41,000.

## Not built yet

Trading, leaderboards beyond `leaderstats`, real boat sailing (travel is currently a timed transition), ocean exploration/secret islands, Void Sea, Neon Tokyo, Spirit Forest, Auto Fish, VIP perks beyond the Yen bonus, real character art.
