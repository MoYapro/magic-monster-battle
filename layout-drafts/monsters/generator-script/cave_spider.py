"""Cave spider (linocut v2): bulbous spotted abdomen, eight hairy three-segment legs with
their knees raised high above the body, fangs and a cluster of ember eyes. Faces left."""
import math

from helpers_c import (INK, PAPER, curve_cut, figure_rim, groove, oval, part, spikes, spots)
from style import Print, bar, bar_cut, bezier, eyes, ground, knob, path, rough, sliver, taper, rng

VIOLET = "#9d8cb4"

# leg: (name, base, knee, ankle, tip); far legs are drawn behind the body and printed darker
FAR_LEGS = [
    ("far_1", (196, 318), (150, 168), (88, 222), (64, 400)),
    ("far_2", (212, 314), (196, 150), (150, 250), (150, 430)),
    ("far_3", (240, 312), (300, 118), (388, 156), (404, 432)),
    ("far_4", (256, 308), (420, 122), (482, 200), (476, 428)),
]
NEAR_LEGS = [
    ("near_3", (238, 366), (318, 288), (396, 344), (420, 458)),
    ("near_4", (252, 360), (430, 300), (490, 368), (500, 455)),
    ("near_2", (200, 360), (176, 196), (118, 300), (110, 452)),
    ("near_1", (176, 346), (112, 214), (44, 296), (22, 426)),
]


def leg_segment(p, a, b, w1, w2, color, hair=True, joint=0):
    polys = [bar(*a, *b, w1, w2)]
    if joint:
        polys.append(knob(*b, joint, 7))
    if hair:
        n = max(2, int(math.hypot(b[0] - a[0], b[1] - a[1]) / 13))
        polys += spikes(a, b, n, w1 * 0.5, w=4, lean=0.7)
    shade, marks = bar_cut(*a, *b, max(w1, w2), frac=0.08)
    part(p, polys, shade, marks, color=color)


def leg(p, name, base, knee, ankle, tip, w, color):
    with p.group(f"leg_{name}_femur", base):
        leg_segment(p, base, knee, w, w * 0.85, color, joint=w * 0.62)
    with p.group(f"leg_{name}_tibia", knee):
        leg_segment(p, knee, ankle, w * 0.85, w * 0.6, color, joint=w * 0.45)
    with p.group(f"leg_{name}_tarsus", ankle):
        leg_segment(p, ankle, tip, w * 0.6, 2.5, color, hair=False)


def abdomen(p):
    cx, cy, rx, ry, rot = 352, 236, 122, 98, -0.25
    with p.group("abdomen", (262, 312)):
        body = oval(cx, cy, rx, ry, 22, rot)
        stalk = [(250, 300), (285, 290), (292, 326), (258, 330)]
        hairs = [s for a, b in zip(body[10:17], body[11:18]) for s in spikes(a, b, 2, 7, w=5, sides=(-1,))]
        arc = bezier((236, 330), (420, 300), (440, 120), 14)
        shade, marks = curve_cut(arc, (1, 0.6), count=9, lmin=14, lmax=30, w=7)
        marks += spots(cx - 10, cy - 10, rx * 0.8, ry * 0.75, 26, 4, 9)
        marks += [groove((280, 160 + i * 10), (360 + i * 8, 120 + i * 30), (430 + i * 6, 170 + i * 46), 4)
                  for i in range(3)]
        marks += [groove((400, 330), (470, 300), (466, 220), 5)]
        for _ in range(22):
            a, r = rng.uniform(0, 6.28), rng.uniform(0.3, 0.85)
            x, y = cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r
            marks.append((sliver(x, y, a + 1.9, rng.uniform(8, 14), 3), INK))
        part(p, [body, stalk] + hairs, shade, marks)


def cephalothorax(p):
    with p.group("cephalothorax", (215, 330)):
        body = oval(204, 336, 72, 52, 18, 0.1)
        brow = [(134, 318), (176, 290), (214, 300), (168, 326)]
        arc = bezier((168, 380), (262, 360), (276, 292), 10)
        shade, marks = curve_cut(arc, (1, 0.8), count=5, lmin=10, lmax=22, w=6)
        marks += [groove((230, 322), (250 + 6 * i, 300 - 4 * i), (262 + 10 * i, 288 + 22 * i), 3.5)
                  for i in range(3)]
        plate = oval(172, 316, 50, 24, 14, -0.12)
        marks.append((path(rough(plate, amp=2.5)), INK))
        part(p, [body, brow], shade, marks)
        eyes(p, [(160, 312), (188, 306)], 10)
        eyes(p, [(142, 326), (174, 330), (204, 322), (214, 300), (140, 306)], 5)


def fang(p, side, top, color):
    x, y = top
    with p.group(f"chelicera_{side}", top):
        hook = taper(bezier((x - 6, y + 40), (x - 10, y + 72), (x + 16, y + 78), 8), 11, 1.5)
        hs, hm = bar_cut(x - 6, y + 40, x + 4, y + 76, 11, frac=0.15, count=2)
        part(p, [hook], hs, hm, color=PAPER)
        base = taper(bezier((x, y), (x - 14, y + 26), (x - 6, y + 46), 8), 24, 15)
        shade, marks = bar_cut(x, y, x - 6, y + 46, 24, frac=0.1, count=2)
        part(p, [base], shade, marks, color=color)


def palp(p, side, base, knee, tip):
    with p.group(f"palp_{side}", base):
        leg_segment(p, base, knee, 11, 9, None, joint=6)
        leg_segment(p, knee, tip, 9, 5, None)


def build():
    p = Print(VIOLET, seed=31)
    with p.group("ground", (256, 452)):
        ground(p, 30, 500, 448)
    for name, *pts in FAR_LEGS:
        leg(p, name, *pts, 11, INK)
    abdomen(p)
    for name, *pts in NEAR_LEGS:
        leg(p, name, *pts, 14, None)
    cephalothorax(p)
    fang(p, "far", (186, 362), INK)
    palp(p, "near", (150, 360), (112, 366), (100, 404))
    fang(p, "near", (160, 368), None)
    figure_rim(p, 11)
    return p


if __name__ == "__main__":
    build().save("cave_spider")
