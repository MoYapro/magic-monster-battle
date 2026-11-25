"""2x2 obstacles (1024 x 1024): altar, ancient stump, glacier chunk."""
import math

from helpers_d import leaf_cluster
from helpers_g import drip
from kit import (EMBER, INK, PAPER, bezier, boulder, cast_shadow, crack, crystal, end_rings, flame_pts, form, grain_lines,
                 ink_line, jag, knob, lerp, oval, paper_line, path, pebbles, rng, rock, sliver, taper, thread)
from tall import _glyphs

FLOOR = 960


def _block(p, top, front, side, color, marks=(), side_marks=(), top_marks=()):
    """A box in 3/4 view: lit top, front face, shadowed right side."""
    form(p, side, (side[0], lerp(side[0], side[2], 0.5), side[3]), color=color, count=6, marks=list(side_marks))
    form(p, front, (front[1], lerp(front[1], front[2], 0.5), front[2]), color=color, count=3, rows=0, marks=list(marks))
    form(p, top, (top[1], lerp(top[1], top[2], 0.5), top[2]), color=color, count=1, rows=0, marks=list(top_marks))


def altar(p):
    cast_shadow(p, 520, FLOOR, 460, 24)
    # stepped base
    _block(p, [(90, 800), (840, 800), (940, 740), (190, 740)], [(90, 800), (840, 800), (840, 920), (90, 920)],
           [(840, 800), (940, 740), (940, 860), (840, 920)], "#9a9488",
           marks=[ink_line((90, 860), (460, 864), (840, 860), 3, 1)] + [ink_line((x, 800), (x, 860), (x, 920), 3, 1) for x in (260, 470, 650)])
    _block(p, [(160, 460), (760, 460), (860, 390), (260, 390)], [(160, 460), (760, 460), (760, 800), (160, 800)],
           [(760, 460), (860, 390), (860, 730), (760, 800)], "#a8a090",
           marks=_glyphs(460, 520, 740, 1, 0) + [g for k, x in enumerate(range(230, 720, 70)) for g in _glyphs(x, 560, 680, 1, 40)]
           + [ink_line((160, 520), (460, 524), (760, 520), 3, 1), ink_line((160, 740), (460, 744), (760, 740), 3, 1)],
           side_marks=[g for g in _glyphs(810, 520, 700, 2, 30)])
    _block(p, [(120, 450), (800, 450), (910, 370), (230, 370)], [(120, 450), (800, 450), (800, 500), (120, 500)],
           [(800, 450), (910, 370), (910, 420), (800, 500)], "#b8b0a0",
           top_marks=[ink_line((300, 400), (520, 404), (780, 400), 3, 1), ink_line((480, 372), (470, 410), (460, 448), 3, 1)])
    for x, y, h in ((330, 400, 90), (640, 410, 60), (700, 400, 44)):
        p.part([[(x - 18, y), (x + 18, y), (x + 18, y - h), (x - 18, y - h)]], color=PAPER, sw=3,
               marks=[ink_line((x + 10, y - h), (x + 12, y - h / 2), (x + 10, y), 3, 1)])
        form(p, flame_pts(x, y - h, 50, 22, -0.05), ((x + 6, y - h - 50), (x + 10, y - h - 20), (x + 8, y - h)),
             color=EMBER, count=1, rows=0, sw=3)
    form(p, oval(500, 410, 70, 20, 16), ((460, 400), (520, 396), (570, 410)), color="#8a6a3a", count=2, rows=0)
    for x in (120, 170, 860, 910, 470):
        for k in range(3):
            p.part([taper([(x + k * 10, FLOOR - 40), (x + k * 10 + rng.uniform(-18, 18), FLOOR - 40 - rng.uniform(40, 80))], 9, 1)],
                   color="#6a8a4a", sw=2)


def ancient_stump(p):
    cast_shadow(p, 520, FLOOR, 470, 26)
    roots = [((380, 800), (220, 860), (60, FLOOR)), ((440, 820), (360, 900), (300, FLOOR + 10)),
             ((620, 820), (700, 900), (780, FLOOR + 10)), ((680, 800), (840, 860), (990, FLOOR)),
             ((520, 840), (520, 900), (520, FLOOR + 14))]
    for a, c, b in roots:
        poly = taper(bezier(a, c, b, 12), 90, 14)
        form(p, poly, (a, c, b), color="#8a7a5a", count=3, rows=0, marks=grain_lines(a, b, 2, 30, 3))
    top = jag((300, 260), (760, 200), 6, 140)
    trunk = [(320, 860), (330, 600), (300, 380)] + top + [(770, 380), (740, 600), (720, 860)]
    form(p, trunk, ((660, 220), (720, 520), (700, 860)), color="#8a7a5a", count=10,
         marks=grain_lines((420, 330), (430, 840), 6, 220, 5) + [(path(oval(470, 600, 26, 50, 12)), INK)])
    for x, y, w in ((700, 420, 110), (690, 470, 80), (340, 520, 70)):
        shelf = [(x - w / 2, y), (x + w / 2, y), (x + w * 0.42, y + 18), (x, y + 28), (x - w * 0.42, y + 18)]
        p.part([shelf], color="#d8b070", sw=3, marks=[ink_line((x - w * 0.35, y + 10), (x, y + 18), (x + w * 0.35, y + 10), 2.5, 1)])
    for x, y, r in ((370, 380, 46), (600, 340, 54), (420, 700, 40), (650, 640, 36)):
        blob = leaf_cluster(x, y, r, 8, rng.uniform(0, 1), 0.7)
        form(p, blob, ((x + r * 0.3, y - r), (x + r * 0.8, y), (x + r * 0.3, y + r)), color="#7a9a5a", count=2, rows=0, sw=3)
    pebbles(p, [(150, FLOOR - 6, 18), (900, FLOOR - 4, 22), (240, FLOOR + 6, 12), (820, FLOOR + 10, 12)], color="#8a8a80")


def glacier_chunk(p):
    cast_shadow(p, 520, FLOOR, 470, 24)
    shards = [(560, 870, 760, 300, 0.12), (380, 880, 560, 280, -0.08), (760, 900, 420, 220, 0.2), (230, 900, 380, 220, -0.2),
              (470, 900, 420, 240, 0.02), (860, 920, 260, 160, 0.3)]
    for cx, base, h, w, lean in shards:
        poly = crystal(cx, base, h, w)
        poly = [(x + (base - y) * lean, y) for x, y in poly]
        top = poly[0]
        form(p, poly, (lerp(top, poly[1], 0.3), lerp(top, poly[2], 0.5), poly[2]), color="#a8d8ee", count=5,
             marks=[(crack(lerp(top, poly[4], 0.3), lerp(top, poly[3], 0.8), kinks=3, w=3.5), INK),
                    paper_line(lerp(top, poly[4], 0.1), lerp(top, poly[4], 0.5), lerp(top, poly[4], 0.9), 6, 1.5)])
    snow = [(150, 640), (260, 560), (420, 600), (520, 560), (560, 620), (420, 680), (240, 690)]
    form(p, snow, ((500, 620), (430, 676), (300, 700)), toward=(0.3, 1), color="#eef4f8", count=2, rows=0)
    for x, L in ((170, 220), (210, 300), (250, 180), (290, 260), (330, 200), (370, 240)):
        p.part([taper([(x, 650), (x - 3, 650 + L * 0.5), (x, 650 + L)], 30, 2)], color="#bfe4f4", sw=3,
               marks=[paper_line((x - 8, 660), (x - 9, 650 + L * 0.3), (x - 7, 650 + L * 0.5), 3, 1)])
    pebbles(p, [(110, FLOOR - 10, 26), (180, FLOOR + 6, 18), (900, FLOOR - 4, 30), (960, FLOOR + 8, 16), (640, FLOOR + 10, 18)],
            color="#bfe4f4")


OBSTACLES = {"altar": (altar, "#a8a090"), "ancient_stump": (ancient_stump, "#8a7a5a"),
             "glacier_chunk": (glacier_chunk, "#a8d8ee")}
CELLS = (2, 2)
