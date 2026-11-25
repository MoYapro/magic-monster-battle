"""1x2 obstacles (512 x 1024, standing upright): pillars, cactus, crystals, logs, monolith, obelisk,
obsidian spike, sarcophagus, stalactite pillar, stalagmite, tree."""
import math

from kit import (EMBER, INK, PAPER, bezier, boulder, cast_shadow, crack, crystal, end_rings, form, grain_lines,
                 ink_line, jag, knob, lerp, oval, paper_line, path, pebbles, rng, rock, sliver, spline, taper,
                 thread)
from helpers_d import leaf_cluster
from helpers_g import drip

FLOOR = 960


def _glyphs(x, y0, y1, n, size=18, color=PAPER):
    """Little carved rune signs stacked in a column."""
    out = []
    for i in range(n):
        cy = y0 + (y1 - y0) * (i + 0.5) / n
        a, b = (x - size / 2, cy - size / 2), (x + size / 2, cy + size / 2)
        kind = i % 4
        if kind == 0:
            out += [paper_line(a, lerp(a, b, 0.5), (a[0], b[1]), 4, 2), paper_line((a[0], cy), (x, cy), b, 4, 2)]
        elif kind == 1:
            out += [paper_line((x, a[1]), (x, cy), (x, b[1]), 4, 2), paper_line(a, (x, cy), (b[0], a[1]), 4, 2)]
        elif kind == 2:
            out += [paper_line(a, (x, b[1]), (b[0], a[1]), 4, 2)]
        else:
            out += [paper_line((a[0], cy), (x, a[1]), (b[0], cy), 4, 2), paper_line((x, cy), (x, b[1]), (x, b[1]), 4, 2)]
    return out


def _column(p, x0, x1, top, bottom, color, marks=()):
    shaft = [(x0, top), (x1, top), (x1 + 6, bottom), (x0 - 6, bottom)]
    flutes = [ink_line((x, top + 20), (x + 1, (top + bottom) / 2), (x, bottom - 20), 3.5, 2)
              for x in [x0 + (x1 - x0) * k / 5 for k in range(1, 5)]]
    form(p, shaft, ((x1 - 30, top), (x1 - 22, (top + bottom) / 2), (x1 - 26, bottom)), color=color, count=8,
         marks=flutes + list(marks))


def _plinth(p, cx, y, w, h, color):
    for k, (ww, hh) in enumerate(((w, h * 0.55), (w * 0.86, h * 0.45))):
        yy = y - (h * 0.55 if k else 0)
        slab = [(cx - ww / 2, yy - hh), (cx + ww / 2, yy - hh), (cx + ww / 2 + 4, yy), (cx - ww / 2 - 4, yy)]
        form(p, slab, ((cx + ww / 2 - 24, yy - hh), (cx + ww / 2 - 20, yy - hh / 2), (cx + ww / 2 - 24, yy)),
             color=color, count=2, rows=0)


def _grass(p, xs, y=FLOOR, color="#7aa653"):
    for x in xs:
        for k in range(3):
            p.part([taper([(x + k * 8, y), (x + k * 8 + rng.uniform(-14, 14), y - rng.uniform(26, 52))], 7, 1)],
                   color=color, sw=2)


def ancient_pillar(p):
    cast_shadow(p, 262, FLOOR, 170)
    _plinth(p, 256, FLOOR - 4, 300, 90, "#c8b48a")
    _column(p, 186, 326, 200, FLOOR - 90, "#c8b48a", _glyphs(256, 330, 700, 5, 24))
    neck = [(176, 170), (336, 170), (330, 214), (182, 214)]
    form(p, neck, ((300, 170), (316, 192), (300, 214)), color="#c8b48a", count=2, rows=0,
         marks=[ink_line((186, 192), (256, 186), (326, 192), 3, 1)])
    cap = [(140, 100), (372, 100), (380, 172), (132, 172)]
    form(p, cap, ((330, 100), (346, 136), (330, 172)), color="#d8c49a", count=3, rows=0,
         marks=[ink_line((150, 130), (256, 124), (362, 130), 3, 1)])
    _grass(p, (130, 390))
    for a, c, b in (((180, 880), (150, 820), (196, 760)), ((330, 900), (360, 820), (318, 740))):
        thread(p, bezier(a, c, b, 10), 5, 8)


def bog_pillar(p):
    cast_shadow(p, 262, FLOOR, 180)
    pool = oval(256, FLOOR - 4, 190, 26, 24)
    form(p, pool, ((120, FLOOR), (256, FLOOR - 10), (400, FLOOR)), color="#5a7a5a", count=3, rows=0,
         marks=[paper_line((140, FLOOR - 2), (220, FLOOR - 8), (280, FLOOR), 3, 1)])
    trunk = [(160, FLOOR - 10), (178, 600), (190, 280), (200, 150), (320, 140), (330, 300), (340, 620), (362, FLOOR - 10)]
    form(p, trunk, ((300, 140), (330, 560), (330, FLOOR)), color="#8a6a3a", count=8,
         marks=grain_lines((230, 220), (240, 900), 4, 80, 4))
    moss = [(184, 130), (336, 124), (344, 200), (300, 236), (250, 220), (200, 240), (176, 200)]
    form(p, moss, ((300, 130), (330, 190), (300, 236)), color="#6a8a4a", count=3, rows=0)
    for x, L in ((190, 220), (215, 140), (240, 300), (268, 180), (296, 260), (326, 160)):
        for poly in drip(x, 200, L, 16, rng.uniform(-0.1, 0.1)):
            p.part([poly], color="#6a8a4a", sw=3)
    _grass(p, (110, 150, 370, 400), FLOOR - 10, "#6a8a4a")


def broken_pillar(p):
    cast_shadow(p, 262, FLOOR, 190)
    _plinth(p, 256, FLOOR - 4, 300, 90, "#c0b8a8")
    top = jag((190, 330), (322, 270), 4, 60)
    shaft = [(184, FLOOR - 90)] + top + [(330, FLOOR - 90)]
    flutes = [ink_line((x, 340), (x + 1, 600), (x, FLOOR - 110), 3.5, 2) for x in (212, 240, 268, 296)]
    cracks = [(crack((200, 420), (300, 520), kinks=3, w=5), INK), (crack((250, 600), (320, 700), kinks=2, w=4), INK)]
    form(p, shaft, ((300, 280), (310, 600), (300, FLOOR - 90)), color="#c0b8a8", count=8, marks=flutes + cracks)
    for x, y, r in ((110, FLOOR - 10, 28), (400, FLOOR - 6, 34), (440, FLOOR - 30, 18), (80, FLOOR - 34, 14)):
        rock(p, boulder(x, y - r * 0.5, r, 6, 0.8, rng.uniform(0, 1)), ((x, y - r), (x + r * 0.6, y - r * 0.4), (x + r, y)),
             color="#c0b8a8", cracks=0, count=2, sw=3)


def _rounded_bar(x0, x1, top, bottom):
    """An upright bar with a round top: cactus trunks and arms."""
    r = (x1 - x0) / 2
    arc = [((x0 + x1) / 2 + r * math.cos(a), top + r - r * math.sin(a)) for a in [math.pi * k / 10 for k in range(11)]]
    return [(x1, bottom)] + arc[::-1][::-1] + [(x0, bottom)] if False else [(x1, bottom), (x1, top + r)] + arc[1:-1] + [(x0, top + r), (x0, bottom)]


def _cactus_part(p, poly, x0, x1, top, bottom):
    ribs = [ink_line((x, top + 30), (x + 1, (top + bottom) / 2), (x, bottom - 10), 3.5, 2)
            for x in [x0 + (x1 - x0) * k / 4 for k in (1, 2, 3)]]
    spines = [(sliver(x0 + (x1 - x0) * rng.choice((0.25, 0.5, 0.75)), rng.uniform(top + 20, bottom - 10),
                      rng.uniform(-2.8, -0.4), 13, 3), INK) for _ in range(int((bottom - top) / 22))]
    form(p, poly, ((x1 - 18, top), (x1 - 12, (top + bottom) / 2), (x1 - 18, bottom)), color="#7aa653", count=5,
         marks=ribs + spines)


def cactus(p):
    cast_shadow(p, 262, FLOOR, 140)
    for x0, x1, top, bottom, elbow in ((96, 156, 300, 600, (156, 560, 210)), (356, 416, 240, 540, (356, 500, 300))):
        _cactus_part(p, _rounded_bar(x0, x1, top, bottom), x0, x1, top, bottom)
        ex, ey, inner = elbow
        lo, hi = (min(ex, inner), max(ex, inner))
        joint = [(lo, ey - 30), (hi, ey - 30), (hi, ey + 30), (lo, ey + 30)]
        form(p, joint, ((lo, ey + 20), ((lo + hi) / 2, ey + 26), (hi, ey + 20)), color="#7aa653", count=2, rows=0)
    _cactus_part(p, _rounded_bar(200, 312, 120, FLOOR - 6), 200, 312, 120, FLOOR - 6)
    pebbles(p, [(170, FLOOR - 2, 12), (350, FLOOR, 14)], color="#d8b070")


def crystal_formation(p):
    cast_shadow(p, 262, FLOOR, 200)
    for cx, h, w, lean in ((180, 420, 90, -0.1), (330, 480, 96, 0.12), (256, 760, 130, 0.0), (130, 260, 70, -0.25),
                           (390, 280, 70, 0.3), (220, 300, 66, -0.05)):
        poly = crystal(cx, FLOOR - 40, h, w)
        poly = [(x + (FLOOR - 40 - y) * lean, y) for x, y in poly]
        top = poly[0]
        facet = [ink_line(top, lerp(top, poly[3], 0.5), poly[3], 3.5, 2),
                 paper_line(lerp(top, poly[4], 0.15), lerp(top, poly[4], 0.5), lerp(top, poly[4], 0.85), 5, 1.5)]
        form(p, poly, (top, lerp(top, poly[2], 0.5), poly[2]), color="#a8d8e8", count=3, marks=facet)
    base = [(110, FLOOR), (140, FLOOR - 60), (220, FLOOR - 50), (300, FLOOR - 70), (400, FLOOR - 50), (420, FLOOR)]
    rock(p, base, ((330, FLOOR - 70), (390, FLOOR - 40), (400, FLOOR)), color="#8a8a80", cracks=0, count=3)


def monolith(p):
    cast_shadow(p, 262, FLOOR, 160)
    slab = [(150, FLOOR - 10), (170, 400), (196, 170), (240, 110), (300, 130), (340, 300), (360, 700), (370, FLOOR - 10)]
    facets = [((240, 110), (260, 600)), ((260, 600), (220, FLOOR - 10)), ((300, 130), (320, 500))]
    rock(p, slab, ((320, 140), (340, 520), (350, FLOOR)), color="#8a8a80", cracks=2, facets=facets, count=8,
         extra=_glyphs(240, 380, 760, 6, 22))
    pebbles(p, [(120, FLOOR - 2, 16), (400, FLOOR, 18), (430, FLOOR - 16, 10)], color="#8a8a80")


def obelisk(p):
    cast_shadow(p, 262, FLOOR, 170)
    for k, (w, h) in enumerate(((300, 50), (250, 44))):
        y = FLOOR - 4 - k * 50
        step = [(256 - w / 2, y - h), (256 + w / 2, y - h), (256 + w / 2 + 4, y), (256 - w / 2 - 4, y)]
        form(p, step, ((256 + w / 2 - 26, y - h), (256 + w / 2 - 22, y - h / 2), (256 + w / 2 - 26, y)),
             color="#d8c08a", count=2, rows=0)
    shaft = [(196, FLOOR - 100), (214, 200), (298, 200), (316, FLOOR - 100)]
    form(p, shaft, ((272, 200), (282, 500), (290, FLOOR - 100)), color="#d8c08a", count=8,
         marks=_glyphs(240, 260, 800, 8, 22) + [ink_line((256, 200), (258, 500), (262, FLOOR - 100), 3, 1.5)])
    tip = [(214, 200), (256, 80), (298, 200)]
    form(p, tip, ((256, 80), (270, 140), (286, 200)), color="#e8d4a0", count=2, rows=0)


def obsidian_spike(p):
    cast_shadow(p, 262, FLOOR, 190)
    for cx, h, w, lean in ((256, 800, 150, 0.0), (170, 460, 100, -0.18), (350, 520, 110, 0.16), (110, 260, 70, -0.3),
                           (410, 300, 74, 0.32), (220, 260, 80, -0.05), (300, 300, 84, 0.06)):
        poly = crystal(cx, FLOOR - 10, h, w)
        poly = [(x + (FLOOR - 10 - y) * lean, y) for x, y in poly]
        top = poly[0]
        sheen = [paper_line(lerp(top, poly[4], 0.1), lerp(top, poly[4], 0.45), lerp(top, poly[4], 0.8), 4, 1),
                 (path(taper([lerp(top, poly[3], 0.2), lerp(top, poly[3], 0.7)], 6, 1)), "#9a7aba")]
        form(p, poly, (lerp(top, poly[4], 0.3), lerp(top, poly[3], 0.5), poly[3]), color="#6a4a8a", count=3,
             marks=sheen)


def sarcophagus(p):
    cast_shadow(p, 262, FLOOR, 170)
    outer = [(256, 90), (360, 150), (372, 420), (330, FLOOR - 50), (182, FLOOR - 50), (140, 420), (152, 150)]
    form(p, outer, ((340, 150), (360, 500), (320, FLOOR - 50)), color="#c8a060", count=7)
    inner = [(256, 130), (330, 176), (338, 420), (304, FLOOR - 90), (208, FLOOR - 90), (174, 420), (182, 176)]
    knight = [(path(oval(256, 240, 40, 46, 14)), INK), (path(oval(252, 236, 30, 36, 12)), "#c8a060"),
              (path(taper([(256, 300), (256, 560), (256, 800)], 18, 10)), INK),
              (path(taper([(206, 360), (256, 380), (306, 360)], 12, 12)), INK),
              (path(taper([(214, 430), (256, 470), (298, 430)], 10, 10)), INK),
              paper_line((246, 300), (246, 560), (248, 780), 4, 2)]
    form(p, inner, ((320, 180), (330, 500), (300, FLOOR - 90)), color="#d8b070", count=5, rows=0, marks=knight)
    base = [(150, FLOOR - 60), (362, FLOOR - 60), (372, FLOOR - 4), (140, FLOOR - 4)]
    form(p, base, ((340, FLOOR - 60), (350, FLOOR - 30), (340, FLOOR)), color="#c8a060", count=2, rows=0)


def stalactite_pillar(p):
    cast_shadow(p, 262, FLOOR, 190)
    col = [(60, 20), (452, 20), (400, 90), (330, 200), (300, 420), (296, 620), (320, 820), (380, FLOOR - 10),
           (132, FLOOR - 10), (196, 820), (220, 620), (214, 420), (180, 200), (110, 90)]
    form(p, col, ((380, 60), (300, 500), (360, FLOOR)), color="#a09080", count=10,
         marks=grain_lines((256, 100), (258, 900), 4, 60, 4))
    for x, L in ((90, 120), (140, 220), (370, 200), (430, 110), (180, 160)):
        p.part([[(x - 16, 30), (x + 16, 30), (x, 30 + L)]], color="#a09080", sw=3)
    for x, h in ((100, 120), (420, 150), (60, 70), (460, 80)):
        form(p, [(x - 30, FLOOR), (x, FLOOR - h), (x + 30, FLOOR)], ((x, FLOOR - h), (x + 12, FLOOR - h / 2), (x + 22, FLOOR)),
             color="#a09080", count=1, rows=0, sw=3)


def stalagmite(p):
    cast_shadow(p, 262, FLOOR, 190)
    cone = [(130, FLOOR - 4), (190, 700), (214, 480), (236, 260), (252, 90), (276, 250), (300, 470), (330, 700),
            (390, FLOOR - 4)]
    bands = [ink_line((150 + k * 8, y), (256, y + 18), (370 - k * 8, y), 4, 2) for k, y in
             enumerate((860, 760, 640, 520, 400, 290))]
    form(p, cone, ((270, 100), (310, 500), (360, FLOOR)), color="#b0a088", count=8, marks=bands)
    for x, h in ((90, 200), (420, 240), (60, 110), (460, 120)):
        cone2 = [(x - 36, FLOOR), (x, FLOOR - h), (x + 36, FLOOR)]
        form(p, cone2, ((x + 4, FLOOR - h), (x + 18, FLOOR - h / 2), (x + 30, FLOOR)), color="#b0a088", count=2,
             rows=0, sw=3)


def tree(p):
    cast_shadow(p, 262, FLOOR, 200)
    trunk = [(170, FLOOR), (210, 860), (220, 560), (200, 400), (230, 380), (256, 470), (290, 380), (320, 400),
             (300, 560), (306, 860), (350, FLOOR)]
    form(p, trunk, ((290, 420), (300, 700), (330, FLOOR)), color="#8a5a2a", count=6,
         marks=grain_lines((246, 480), (250, 940), 3, 50, 4))
    for side in (-1, 1):
        root = taper(bezier((256 + side * 70, FLOOR - 30), (256 + side * 120, FLOOR - 6), (256 + side * 170, FLOOR), 8), 36, 6)
        form(p, root, ((256 + side * 70, FLOOR - 40), (256 + side * 130, FLOOR - 16), (256 + side * 170, FLOOR)),
             color="#8a5a2a", count=1, rows=0)
    clumps = [(256, 300, 150), (130, 360, 110), (382, 350, 116), (256, 440, 120), (150, 220, 104), (360, 210, 110),
              (256, 140, 120), (90, 300, 84), (424, 270, 84), (180, 440, 96), (330, 450, 96), (256, 60, 80),
              (160, 120, 80), (350, 110, 84)]
    for cx, cy, r in sorted(clumps, key=lambda c: c[1]):
        blob = leaf_cluster(cx, cy, r, 11, rng.uniform(0, 1), 0.85)
        tufts = [(path(leaf_cluster(cx + rng.uniform(-r, r) * 0.4, cy + rng.uniform(-r, r) * 0.3, r * 0.22, 6,
                                    rng.uniform(0, 1), 0.8)), "#4a7a3a") for _ in range(3)]
        form(p, blob, ((cx + r * 0.3, cy - r), (cx + r * 0.75, cy), (cx + r * 0.3, cy + r)), color="#6a9a4a", count=4,
             rows=0, marks=tufts)


OBSTACLES = {
    "ancient_pillar": (ancient_pillar, "#c8b48a"), "bog_pillar": (bog_pillar, "#6a8a4a"),
    "broken_pillar": (broken_pillar, "#c0b8a8"), "cactus": (cactus, "#7aa653"),
    "crystal_formation": (crystal_formation, "#a8d8e8"),     "monolith": (monolith, "#8a8a80"), "obelisk": (obelisk, "#d8c08a"), "obsidian_spike": (obsidian_spike, "#6a4a8a"),
    "sarcophagus": (sarcophagus, "#c8a060"), "stalactite_pillar": (stalactite_pillar, "#a09080"),
    "stalagmite": (stalagmite, "#b0a088"), "tree": (tree, "#6a9a4a"),
}
CELLS = (1, 2)
