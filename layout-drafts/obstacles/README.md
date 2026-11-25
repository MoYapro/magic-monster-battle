# Obstacle drafts (linocut)

The battlefield obstacles, printed in the same two-colour linocut style as the monsters (`../monsters/`): black ink plus one colour block on cream paper, slightly out of register, carved shadow side towards the bottom right, one paper rim around the whole figure. They are drawn from the obstacle idea sheets and cover every obstacle in `scripts/battle/obstacles/`.

`00_all_obstacles.png` shows all of them on the dark UI colour. Each obstacle is `<id>.svg` + `<id>.png`; the id is the obstacle's script name.

## Canvas

512 px per grid cell, like the monsters, with the base standing near the bottom edge:

| Footprint | Canvas | Obstacles |
|---|---|---|
| 1×1 | 512 × 512 | barrel, ice block, lava rock, pyre, rotted stump, spore vent, stone, thornbush, web cocoon |
| 1×2 (tall) | 512 × 1024 | ancient pillar, bog pillar, broken pillar, cactus, crystal formation, frozen log, log, monolith, obelisk, obsidian spike, sarcophagus, stalactite pillar, stalagmite, tree |
| 2×1 (wide) | 1024 × 512 | ash pile, bone pile, boulder, bramble patch, crumbling wall, fossilized bone, ice wall, mudpit, mushroom circle, sand dune, snow drift, tide pool |
| 2×2 | 1024 × 1024 | altar, ancient stump, glacier chunk |

Obstacles do not animate, so each is a single group `obstacle` with its pivot at the middle of the base (enough for a hit wobble later).

## Build

```
python3 generator-script/build.py [ids...]
```

Renders the given obstacles (all when none are named) and rebuilds the overview. Needs `python3`, `rsvg-convert` and `magick`.

## Generator scripts (`generator-script/`)

| File | Role |
|---|---|
| `kit.py` | `ObstaclePrint` (the monsters' `Print2`, saving here), cast shadow, carved rocks, pebbles, wood grain, end rings, puffs, mounds, threads. Imports the monster generator's `style.py` and helpers |
| `small.py`, `tall.py`, `wide.py`, `big.py` | One function per obstacle, grouped by footprint, each with its colour |
| `build.py` | Renders everything and the overview |

Not yet in the game: `tools/export_art.py` still has to copy these into `assets/` and the grid has to draw them instead of the coloured blocks.
