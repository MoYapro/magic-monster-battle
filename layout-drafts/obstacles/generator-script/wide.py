"""2x1 obstacles (1024 x 512, lying wide): ash pile, bone pile, boulder, bramble patch, crumbling wall,
fossilized bone, ice wall, mudpit, mushroom circle, sand dune, snow drift, tide pool."""
import math

from helpers_a import long_bone
from helpers_d import leaf_cluster
from kit import (EMBER, INK, PAPER, bezier, boulder, cast_shadow, crack, form, ink_line, jag, knob, leaf, lerp, mound,
                 oval, paper_line, path, pebbles, puff, rng, rock, sliver, smoke_wisps, taper, thread)

FLOOR = 450


def _ripples(x0, x1, y0, y1, n, color=INK, w=3.5):
    out = []
    for i in range(n):
        y = y0 + (y1 - y0) * (i + 0.5) / n
        a, b = (x0 + rng.uniform(0, 80), y), (x1 - rng.uniform(0, 80), y + rng.uniform(-10, 10))
        out.append((path(taper(bezier(a, (lerp(a, b, 0.5)[0], y - 18), b, 12), w, 1)), color))
    return out


def _skull(p, cx, cy, s=1.0):
    head = oval(cx, cy, 34 * s, 30 * s, 16)
    jaw = [(cx - 18 * s, cy + 18 * s), (cx + 18 * s, cy + 18 * s), (cx + 14 * s, cy + 36 * s), (cx - 14 * s, cy + 36 * s)]
    sockets = [(path(oval(cx + dx * s, cy + 2 * s, 9 * s, 10 * s, 8)), INK) for dx in (-13, 13)]
    sockets += [(path([(cx - 3 * s, cy + 14 * s), (cx + 3 * s, cy + 14 * s), (cx, cy + 8 * s)]), INK)]
    form(p, [head, jaw], ((cx + 10 * s, cy - 30 * s), (cx + 30 * s, cy), (cx + 14 * s, cy + 36 * s)), color=PAPER, count=2,
         rows=0, sw=3.5, marks=sockets + [ink_line((cx - 12 * s, cy + 28 * s), (cx, cy + 30 * s), (cx + 12 * s, cy + 28 * s), 2.5, 1)])


def ash_pile(p):
    cast_shadow(p, 520, FLOOR, 360)
    heap = mound(170, 870, FLOOR, 190, 4, 0.45)
    embers = [(path(knob(rng.uniform(260, 760), rng.uniform(320, 430), rng.uniform(4, 8), 5)), EMBER) for _ in range(14)]
    form(p, heap, ((560, 260), (760, 340), (840, 452)), color="#8a8078", count=7,
         marks=_ripples(240, 800, 300, 430, 4, INK, 3) + embers)
    for x, y in ((380, 420), (660, 410)):
        p.part([taper([(x, y), (x + 60, y - 20), (x + 120, y - 6)], 14, 8)], color=INK, sw=3)
    for x, y, r in ((470, 250, 26), (500, 200, 20), (590, 230, 30), (630, 170, 22), (680, 250, 18)):
        p.part([puff(x, y, r, 5)], color="#b8b0a8", sw=3,
               marks=[paper_line((x - r * 0.5, y - r * 0.2), (x - r * 0.1, y - r * 0.6), (x + r * 0.4, y - r * 0.5), 3, 1)])


def bone_pile(p):
    cast_shadow(p, 520, FLOOR, 380)
    heap = mound(150, 890, FLOOR, 120, 3, 0.5)
    form(p, heap, ((560, 330), (760, 380), (860, 452)), color="#6a5a40", count=5)
    for a, b in (((230, 400), (420, 330)), ((470, 410), (700, 360)), ((600, 330), (820, 410)), ((330, 300), (540, 350)),
                 ((690, 300), (870, 340)), ((160, 430), (300, 370))):
        long_bone(p, a, b, 20, color="#e0d4b0")
    for x, y, s in ((330, 260, 1.4), (620, 280, 1.2), (780, 380, 1.0), (450, 380, 0.9)):
        _skull(p, x, y, s)
    for k in range(5):
        x = 520 + k * 24
        p.part([taper(bezier((x, 300), (x + 20, 250), (x + 46, 310), 10), 12, 8)], color="#e0d4b0", sw=3)


def boulder_(p):
    cast_shadow(p, 520, FLOOR, 400, 18)
    poly = [(110, 440), (130, 330), (220, 210), (380, 150), (580, 140), (760, 180), (880, 270), (920, 380), (880, 450),
            (180, 452)]
    facets = [((380, 150), (450, 300)), ((450, 300), (220, 320)), ((450, 300), (640, 280)), ((640, 280), (760, 180)),
              ((640, 280), (700, 452)), ((450, 300), (420, 452))]
    rock(p, poly, ((800, 200), (880, 360), (820, 452)), color="#a8a090", cracks=3, facets=facets, count=10)
    pebbles(p, [(90, 446, 18), (940, 440, 22), (970, 452, 10), (60, 452, 10), (200, 456, 12)], color="#a8a090")


def bramble_patch(p):
    cast_shadow(p, 520, FLOOR, 420)
    rng.seed(21)
    mass = [(70, 452), (100, 380), (200, 330), (340, 300), (520, 290), (700, 300), (840, 330), (940, 390), (960, 452)]
    form(p, mass, ((800, 310), (920, 380), (930, 452)), color="#4a6a2a", count=7,
         marks=[(path(knob(rng.uniform(120, 900), rng.uniform(340, 440), rng.uniform(6, 12), 5)), INK) for _ in range(16)])
    for i in range(26):
        x0 = rng.uniform(80, 940)
        a = rng.uniform(math.pi * 1.1, math.pi * 1.9)
        L = rng.uniform(90, 200)
        tip = (x0 + math.cos(a) * L, FLOOR - 10 + math.sin(a) * L * 0.8)
        line = bezier((x0, FLOOR - 10), (lerp((x0, FLOOR), tip, 0.5)[0], tip[1] - 30), tip, 10)
        thread(p, line, 5, 6)
        for k in range(2, 9, 3):
            x, y = line[k]
            d = path([(x - 3, y), (x + 3, y), (x + (12 if k % 2 else -12), y - 12)])
            p.rim(d, 4)
            p.fill(d)
    for x, y, ang in ((260, 320, -2.0), (520, 300, -1.5), (760, 310, -1.0), (420, 330, -2.4), (650, 300, -0.7)):
        form(p, leaf(x, y, 34, 18, ang), ((x, y), (x + 10, y + 4), (x + 30, y)), color="#7aa653", count=1, rows=0, sw=3)


def crumbling_wall(p):
    cast_shadow(p, 520, FLOOR, 430)
    rows_ = 6
    for r in range(rows_):
        y1 = FLOOR - 10 - r * 46
        offset = 0 if r % 2 else 40
        for k in range(10):
            x0 = 90 + offset + k * 84
            x1 = x0 + 78
            height_left = 6 if x0 < 420 else (2 + int(abs(x0 - 560) / 90) if x0 < 700 else 6)
            if r >= height_left or x1 > 950:
                continue
            brick = [(x0, y1 - 42), (x1, y1 - 42 + rng.uniform(-3, 3)), (x1, y1), (x0, y1)]
            form(p, brick, ((x1 - 16, y1 - 42), (x1 - 10, y1 - 20), (x1 - 16, y1)), color="#b8885a", count=1, rows=0,
                 sw=3.5, marks=[(crack((x0 + 10, y1 - 30), (x0 + 50, y1 - 12), kinks=1, w=2.5), INK)] if rng.random() < 0.3 else [])
    for x, y, ang in ((520, 440, 0.3), (600, 436, -0.4), (680, 444, 0.1), (560, 410, 0.9)):
        brick = [(x + math.cos(ang) * dx - math.sin(ang) * dy, y + math.sin(ang) * dx + math.cos(ang) * dy)
                 for dx, dy in ((-36, -18), (36, -18), (36, 18), (-36, 18))]
        form(p, brick, (brick[1], brick[2], brick[3]), color="#a8784a", count=1, rows=0, sw=3)
    for x in (100, 140, 860, 900):
        for k in range(3):
            p.part([taper([(x + k * 8, FLOOR), (x + k * 8 + rng.uniform(-14, 14), FLOOR - rng.uniform(30, 60))], 7, 1)],
                   color="#7aa653", sw=2)


def fossilized_bone(p):
    cast_shadow(p, 520, FLOOR, 400)
    heap = mound(120, 920, FLOOR, 140, 3, 0.55)
    form(p, heap, ((620, 320), (820, 380), (900, 452)), color="#9a7a50", count=6)
    spine = bezier((260, 330), (520, 250), (800, 330), 14)
    for k, (x, y) in enumerate(spine[2:-1]):
        rib = taper(bezier((x, y), (x + 30, y - 150 + abs(k - 5) * 8), (x + 60, y + 60), 10), 18, 8)
        form(p, rib, ((x + 20, y - 120), (x + 50, y - 60), (x + 60, y + 50)), color="#d8c08a", count=1, rows=0, sw=3.5)
    p.part([taper(spine, 26, 18)], color="#d8c08a", sw=4,
           marks=[ink_line(spine[k], spine[k], (spine[k][0] + 2, spine[k][1] + 12), 4, 3) for k in range(1, 13, 2)])
    long_bone(p, (200, 420), (420, 380), 24, color="#d8c08a")
    _skull(p, 210, 330, 1.3)


def ice_wall(p):
    cast_shadow(p, 520, FLOOR, 430)
    for x0, x1, h in ((90, 400, 230), (330, 680, 290), (600, 940, 250)):
        top = jag((x0, FLOOR - h), (x1, FLOOR - h - 20), 3, 30)
        slab = [(x0 - 10, FLOOR)] + top + [(x1 + 10, FLOOR)]
        form(p, slab, ((x1 - 50, FLOOR - h), (x1 - 30, FLOOR - h / 2), (x1 - 40, FLOOR)), color="#a8d8ee", count=5,
             marks=[(crack((x0 + 40, FLOOR - h + 40), (x0 + 140, FLOOR - 40), kinks=3, w=3.5), INK),
                    paper_line((x0 + 30, FLOOR - h + 30), (x0 + 36, FLOOR - h / 2), (x0 + 30, FLOOR - 30), 5, 1.5)])
    for x, y, r in ((80, 448, 20), (480, 452, 16), (960, 446, 22), (720, 454, 12)):
        form(p, boulder(x, y - r * 0.4, r, 5, 0.8), ((x, y - r), (x + r, y - r / 2), (x + r, y)), color="#bfe4f4", count=1,
             rows=0, sw=3)


def mudpit(p):
    pit = [(x + rng.uniform(-14, 14), y + rng.uniform(-8, 8)) for x, y in oval(520, 390, 420, 80, 30)]
    form(p, pit, ((180, 420), (520, 488), (880, 420)), toward=(0.2, 1), color="#8a6a3a", count=7,
         marks=[(path(oval(x, y, r, r * 0.4, 12)), INK) for x, y, r in ((380, 380, 26), (560, 400, 34), (700, 370, 22), (460, 420, 16))]
         + [(path(oval(x - r * 0.2, y - r * 0.15, r * 0.5, r * 0.15, 10)), PAPER) for x, y, r in ((380, 380, 26), (560, 400, 34))]
         + _ripples(180, 860, 350, 440, 3, PAPER, 3))
    for x, y in ((130, 440), (900, 430), (300, 470), (760, 470)):
        p.part([oval(x, y, 26, 9, 12)], color="#8a6a3a", sw=3)


def mushroom_circle(p):
    ring = oval(520, 390, 400, 60, 30)
    inner = oval(520, 392, 300, 34, 24)[::-1]
    form(p, [ring], ((520, 330), (880, 360), (900, 420)), color="#4a6a2a", count=6,
         marks=[(path(inner), "#3a2a1a")])
    spots_ = []
    for i in range(16):
        a = i * 2 * math.pi / 16 + rng.uniform(-0.1, 0.1)
        spots_.append((520 + 350 * math.cos(a), 390 + 48 * math.sin(a), rng.uniform(0.7, 1.3)))
    for x, y, s in sorted(spots_, key=lambda q: q[1]):
        stem = [(x - 9 * s, y), (x + 9 * s, y), (x + 7 * s, y - 50 * s), (x - 7 * s, y - 50 * s)]
        p.part([stem], color=PAPER, sw=3)
        cap = [(x - 38 * s, y - 44 * s)] + bezier((x - 36 * s, y - 46 * s), (x, y - 100 * s), (x + 36 * s, y - 46 * s), 10) + [(x + 38 * s, y - 44 * s)]
        form(p, cap, ((x + 10 * s, y - 90 * s), (x + 30 * s, y - 60 * s), (x + 38 * s, y - 44 * s)), color="#c86a4a",
             count=1, rows=0, sw=3,
             marks=[(path(knob(x + dx * s, y + dy * s, 5 * s, 6)), PAPER) for dx, dy in ((-14, -62), (8, -76), (18, -56))])


def sand_dune(p):
    cast_shadow(p, 520, FLOOR, 430, 14)
    dune = mound(60, 980, FLOOR, 250, 2, 0.62)
    form(p, dune, ((600, 210), (700, 300), (900, 440)), color="#e0b860", count=6,
         marks=_ripples(160, 640, 300, 440, 5, INK, 3) + [paper_line((300, 330), (560, 220), (620, 205), 5, 2)])
    for x in (140, 830):
        thread(p, bezier((x, FLOOR), (x - 20, FLOOR - 40), (x - 40, FLOOR - 60), 8), 4, 6)
        thread(p, bezier((x, FLOOR), (x + 16, FLOOR - 36), (x + 30, FLOOR - 50), 8), 4, 6)


def snow_drift(p):
    cast_shadow(p, 520, FLOOR, 430, 12)
    for x0, x1, h, pk in ((60, 640, 210, 0.5), (420, 990, 170, 0.55)):
        drift = mound(x0, x1, FLOOR, h, 2, pk)
        form(p, drift, ((x0 + (x1 - x0) * 0.6, FLOOR - h), (x0 + (x1 - x0) * 0.78, FLOOR - h * 0.5), (x1 - 40, FLOOR)),
             color="#e8eef4", count=5, marks=_ripples(x0 + 60, x1 - 120, FLOOR - h * 0.6, FLOOR - 20, 3, "#9fb8d0", 3))


def tide_pool(p):
    cast_shadow(p, 520, FLOOR, 420)
    water = oval(520, 380, 300, 64, 24)
    form(p, water, ((260, 410), (520, 462), (800, 410)), toward=(0.2, 1), color="#4a8ab0", count=4,
         marks=_ripples(280, 760, 350, 420, 3, PAPER, 3))
    for x, y, r in ((200, 360, 70), (260, 430, 50), (420, 310, 48), (640, 310, 56), (820, 360, 76), (760, 440, 54),
                    (520, 450, 44), (140, 430, 40), (900, 430, 40)):
        rock(p, boulder(x, y - r * 0.3, r, 7, 0.7, rng.uniform(0, 1)), ((x, y - r), (x + r * 0.7, y - r * 0.3), (x + r, y)),
             color="#8a8a80", cracks=0, count=2, sw=4)
    for x, y in ((470, 330), (600, 336), (560, 352)):
        thread(p, bezier((x, y + 30), (x - 10, y), (x + 6, y - 40), 8), 5, 6)


OBSTACLES = {
    "ash_pile": (ash_pile, "#8a8078"), "bone_pile": (bone_pile, "#e0d4b0"), "boulder": (boulder_, "#a8a090"),
    "bramble_patch": (bramble_patch, "#4a6a2a"), "crumbling_wall": (crumbling_wall, "#b8885a"),
    "fossilized_bone": (fossilized_bone, "#d8c08a"), "ice_wall": (ice_wall, "#a8d8ee"), "mudpit": (mudpit, "#8a6a3a"),
    "mushroom_circle": (mushroom_circle, "#c86a4a"), "sand_dune": (sand_dune, "#e0b860"),
    "snow_drift": (snow_drift, "#e8eef4"), "tide_pool": (tide_pool, "#4a8ab0"),
}
CELLS = (2, 1)
