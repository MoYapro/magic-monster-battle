# Monster drafts (linocut)

The monsters are drawn as two-colour linocut prints: black ink plus one colour block per monster, printed slightly out of register on cream paper. The carving marks follow each form, one paper rim runs around the whole figure, and the eyes are ember-coloured. Every monster faces left, towards the mages.

`00_all_monsters.png` shows every monster at bestiary size and at 128 px tile size. Each monster is `<id>.svg` (with body-part groups) plus `<id>.png`.

## Build

```
python3 generator-script/build.py
```

This runs every monster script, writes `<id>.svg` and `<id>.png` into this folder, and rebuilds `00_all_monsters.png`. It needs `python3`, `rsvg-convert` and `magick`.

## Generator scripts (`generator-script/`)

| File | Role |
|---|---|
| `build.py` | Renders all monsters and the overview |
| `style.py` | The `Print` class, jittered polygons, gouges, shared primitives (`bone`, `limb`, `mass`, `strand`, `claw`, `branch`, `flame`, `rag`, `eyes`, `ground`) |
| `helpers_a.py` … `helpers_d.py` | Helpers for one rim around the figure, curved shading, extra body-part shapes. They overlap and should be merged into `style.py` |
| `<id>.py` | One script per monster, with a fixed random seed so every build is identical |

1×1 monsters use a 512×512 canvas. 1×2 monsters (troll, treant) use 512×1024.

## Body parts

Every body part is a named SVG group with a `data-pivot` attribute (e.g. `upper_arm_front`, `jaw`, `leg_near_2_tibia`). The plan is to render each group to its own PNG and animate the parts in Godot (cutout animation: breathing, attack, hit, death).
