"""Banshee (linocut v2): a gaunt floating woman-spirit, wailing, hair streaming back,
one long-fingered hand reaching towards the mages, the gown tearing into wisps."""
import math

from helpers_b import gouges, rpart, shaded, spline, stroke, taper, wave
from style import INK, PAPER, Print, bezier, knob, rng

BLUE = "#9fc2d6"
FACE = PAPER

HAIR_STRANDS = [  # (root, tip, width, waviness, phase)
    ((246, 80), (360, 22), 20, 14, 0.4), ((256, 84), (430, 26), 24, 18, 1.1),
    ((266, 96), (488, 58), 26, 20, 2.0), ((272, 112), (492, 118), 26, 18, 0.2),
    ((272, 128), (476, 170), 24, 20, 1.5), ((268, 142), (446, 214), 22, 18, 2.6),
    ((260, 156), (398, 246), 18, 14, 0.9), ((262, 104), (410, 80), 12, 10, 2.9),
    ((268, 132), (420, 140), 10, 10, 1.7),
]


def strand_line(root, tip, amp, phase):
    return spline(wave(root, tip, amp, waves=1.3, n=9, phase=phase), 4)


def hair(p):
    with p.group("hair", (264, 118)):
        lines = [strand_line(r, t, a, ph) for r, t, w, a, ph in HAIR_STRANDS]
        polys = [taper(ln, w, 2) for ln, (r, t, w, a, ph) in zip(lines, HAIR_STRANDS)]
        under = spline([(262, 150), (330, 190), (420, 200), (500, 175)], 6)
        shade, marks = shaded(under, (0.25, 1), count=7, lmin=10, lmax=26, w=5)
        for ln in lines:
            marks.append(stroke(ln[2:-3], 4, 1, INK))
        for ln in lines[::2]:
            marks.append(stroke([(x + 3, y - 4) for x, y in ln[4:-5]], 3, 0.8, PAPER))
        rpart(p, polys, shade, marks)


def finger(hx, hy, ang, length, bend, w=7):
    tip = (hx + math.cos(ang) * length, hy + math.sin(ang) * length)
    mid = (hx + math.cos(ang - bend) * length * 0.55, hy + math.sin(ang - bend) * length * 0.55)
    return taper(bezier((hx, hy), mid, tip, 10), w, 1.2)


def hand(p, at, base_ang, lengths, spread=0.9, bend=0.18, palm=10):
    hx, hy = at
    polys = [knob(hx, hy, palm, 6, 0.3)]
    n = len(lengths)
    for i, L in enumerate(lengths):
        a = base_ang + spread * (i / (n - 1) - 0.5)
        polys.append(finger(hx, hy, a, L, bend * (1 if i % 2 else 0.6)))

    marks = []
    rpart(p, polys, None, marks, color=FACE, sw=4)


def tatter_hem(a, b, n, depth, lean=(0.35, 1.0)):
    """Points from a to b with n long torn wisps hanging down (leaning by `lean`)."""
    (x1, y1), (x2, y2) = a, b
    pts = []
    for i in range(n * 2 + 1):
        t = i / (n * 2)
        x, y = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
        if i % 2:
            d = depth * rng.uniform(0.6, 1.15)
            x, y = x + lean[0] * d, y + lean[1] * d
        pts.append((x, y))
    return pts


def wisps(a, b, n, length, lean=0.4, curl=0.35, w_scale=1.4):
    """n curved torn wisps hanging from the edge a-b, leaning sideways and curling at the tips."""
    (x1, y1), (x2, y2) = a, b
    step = math.hypot(x2 - x1, y2 - y1) / n
    polys = []
    for i in range(n):
        t = (i + 0.5) / n
        rx, ry = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
        L = length * rng.uniform(0.55, 1.2)
        mid = (rx + lean * L * 0.4, ry + L * 0.55)
        tip = (rx + lean * L + curl * L * rng.uniform(0.3, 1.0), ry + L)
        polys.append(taper(bezier((rx, ry - 6), mid, tip, 10), step * w_scale, 1.5))
    return polys


def arm_back(p):
    with p.group("arm_back", (262, 200)):
        sleeve = [(250, 192), (300, 214), (334, 246), (340, 262), (262, 240)]
        line = spline([(256, 206), (300, 230), (338, 256)], 6)
        shade, marks = shaded(line, (0.2, 1), count=5, lmin=8, lmax=18, w=5)
        rpart(p, [sleeve] + wisps((262, 238), (338, 262), 4, 52, lean=0.5), shade, marks)
    with p.group("hand_back", (338, 258)):
        hand(p, (342, 262), 0.75, [44, 52, 50, 42], spread=1.0)


def gown(p):
    with p.group("gown", (236, 200)):
        neck = [(210, 168), (234, 164), (242, 206), (214, 208)]
        rpart(p, [neck], *shaded([(232, 160), (236, 210)], (1, 0), count=2, lmin=4, lmax=8, w=3), color=FACE, sw=4)
        top = [(196, 196), (218, 204), (240, 212), (262, 194), (278, 230), (268, 276),
               (300, 318), (360, 350), (420, 364), (450, 370)]
        left = [(180, 396), (178, 360), (196, 300), (210, 268), (204, 230)]
        outline = top + [(446, 384)] + left
        tails = wisps((182, 394), (440, 382), 8, 88, lean=0.45, curl=0.15, w_scale=1.3)
        line = spline([(262, 196), (274, 250), (292, 320), (322, 400), (350, 480)], 6)
        shade, marks = shaded(line, (1, -0.15), count=7, lmin=14, lmax=34, w=7)
        for x0, tip in ((214, (214, 470)), (234, (276, 486)), (250, (340, 484)), (262, (400, 466)),
                        (280, (446, 452)), (300, (470, 410))):
            ln = spline(wave((x0, 284), tip, 10, waves=1.0, n=7, phase=x0 * 0.1), 4)
            marks.append(stroke(ln, 5, 1, INK))
            marks.append(stroke([(x + 8, y) for x, y in ln[3:]], 3, 0.8, PAPER))
        marks.append(stroke(spline([(204, 236), (236, 252), (270, 238)], 5), 4, 2, INK))
        rpart(p, [outline] + tails, shade, marks)


def arm_front(p):
    with p.group("arm_front", (208, 198)):
        sleeve = [(214, 192), (170, 204), (126, 204), (98, 198), (98, 214), (216, 236)]
        sleeve_tails = wisps((102, 214), (214, 234), 5, 58, lean=0.25, curl=0.2)
        line = spline([(214, 214), (160, 222), (102, 214)], 6)
        shade, marks = shaded(line, (0, 1), count=6, lmin=8, lmax=20, w=5)
        marks.append(stroke(spline([(206, 200), (160, 210), (110, 206)], 5), 3, 1, INK))
        rpart(p, [sleeve] + sleeve_tails, shade, marks)
    with p.group("hand_front", (98, 204)):
        wrist = taper([(112, 206), (88, 200)], 12, 10)
        rpart(p, [wrist], color=FACE, sw=4)
        hand(p, (84, 199), math.pi + 0.05, [50, 62, 66, 60, 44], spread=1.05, bend=-0.2)


def face(p):
    outline = [(205, 86), (186, 102), (182, 114), (166, 134), (176, 141), (175, 150), (177, 192),
               (186, 210), (204, 204), (230, 180), (250, 150), (262, 120), (246, 86)]
    line = spline([(240, 88), (238, 130), (226, 172), (210, 204)], 6)
    shade, marks = shaded(line, (1, 0.25), count=4, lmin=6, lmax=14, w=4)
    marks += [
        (rpath([(175, 152), (192, 151), (199, 170), (195, 194), (183, 195), (177, 173)]), INK),
        (rpath([(184, 112), (206, 106), (212, 122), (194, 130)]), INK),
        stroke(spline([(200, 132), (214, 148), (222, 170), (214, 190)], 4), 7, 1, INK),
        stroke(spline([(182, 116), (176, 128), (172, 136)], 3), 2.5, 1, INK),
        stroke(spline([(186, 100), (200, 96), (214, 100)], 4), 4, 1, INK),
        stroke(spline([(196, 200), (204, 186), (206, 170)], 4), 3, 1, PAPER),
    ]
    rpart(p, [outline], shade, marks, color=FACE, sw=5)
    p.eye(198, 118, 4)


def rpath(pts):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z"


def hair_cap(p):
    cap = [(198, 90), (220, 72), (252, 74), (274, 98), (276, 132), (266, 162), (250, 172), (248, 140),
           (240, 110), (226, 94), (206, 98)]
    line = spline([(248, 76), (266, 120), (258, 168)], 6)
    shade, marks = shaded(line, (1, 0.2), count=4, lmin=8, lmax=16, w=4)
    for i in range(5):
        ln = spline([(206 + i * 12, 86 - i), (236 + i * 8, 84 + i * 6), (256 + i * 4, 112 + i * 10)], 4)
        marks.append(stroke(ln, 3, 1, INK))
    rpart(p, [cap], shade, marks)


def head(p):
    with p.group("head", (226, 176)):
        face(p)
        hair_cap(p)


def build():
    p = Print(BLUE, seed=21)
    hair(p)
    arm_back(p)
    gown(p)
    arm_front(p)
    head(p)
    return p


if __name__ == "__main__":
    build().save("banshee")
