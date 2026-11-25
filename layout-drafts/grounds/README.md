# Ground drafts (linocut)

Top-down ground tiles for battlefield cells, in the same linocut print language as the monsters: jittered carved edges, tapered gouges, colour blocks printed slightly out of register, and rows of tool marks as a background texture. There is no blur and there are no gradients. Grounds sit under the monsters, so they stay in mid and dark tones with small marks and no big black masses, which keeps the cream-rimmed monsters standing out.

`00_all_grounds.png` shows the base grounds, the state grounds and a mock-up battle grid with monsters standing on mixed cells.

## Tiles

Every tile is fully opaque and covers the whole cell edge to edge. A cell shows exactly one tile: a state doesn't sit on top of a base, it replaces it.

- **Base grounds**, with 2–3 variants each so a grid doesn't repeat:
  - `dirt_1/2`, `grass_1/2`, `sand_1/2`, `snow_1/2`, `mud_1/2`.
  - `stone_1/2/3`: natural stony ground. `stone_1` and `stone_2` are earth with embedded stones and gravel; `stone_3` has large boulders filling most of the cell.
- **State grounds:**
  - `wet`: a flooded cell, dark water with ripples, glints, drowned grass tips and stones.
  - `burning`: charred earth with ash, glowing ember cracks and flame tongues spread across it.
  - `frozen`: an ice sheet with pale plates, cracks and frost marks.
  - `poisoned`: a sickly green bog with a network of violet slime, plus lilac and green bubbles.
  - `overgrown_1` / `overgrown_2`: dense undergrowth over dark earth. Variant 1 is tangled vines; variant 2 is broad-leaved ground cover with thick roots.

In the game, `SOIL` would map to a biome's base ground and `PUDDLE` to `wet`.

Tiles are 256×256 and meant to be shown at about 80–128 px. They are not seamless: each cell keeps a faint carved edge.

## Build

```
python3 generator-script/build.py
```

This runs every ground script, writes `<id>.svg` and `<id>.png` into this folder, checks that no tile has a transparent pixel, and rebuilds `00_all_grounds.png`. The mock-up uses the monster PNGs from `../monsters/`. It needs `python3`, `rsvg-convert` and `magick`.

## Generator scripts (`generator-script/`)

| File | Role |
|---|---|
| `build.py` | Renders all tiles, runs the opacity check, builds the overview and the mock-up grid |
| `style.py` | The `Tile` class (`base`, `texture`, `block`, `gouges`, `poly`, `line`), jittered polygons, blobs, tapered strokes |
| `<ground>.py` | One script per ground. A script with variants writes all of them. Each uses a fixed random seed, so every build is identical |
