"""Fire elemental (linocut v2): a hulking, broad-shouldered man of flame leaning towards the
mages, a scowling face burning in its head, clawed flame hands, its body tearing into a
blaze of tongues at the bottom, sparks drifting up."""
import math

from helpers_b import gouges, licked, rpart, shaded, spline, stroke, taper, wave
from style import INK, PAPER, Print, bezier, flame_pts, knob, path, rng

ORANGE = "#ee8636"
HOT = "#fff1b0"


def flick(x, y, h, lean=0.0, w=4):
    """A paper flame stroke rising from (x, y): the carved 'licks' inside the fire."""
    ln = spline(wave((x, y), (x + lean * h, y - h), 4, waves=0.8, n=6, phase=x * 0.07), 3)
    return stroke(ln, w, 0.6, PAPER)


def tongue(x, y, h, w, lean):
    return flame_pts(x, y, h, w, lean)


def blaze(p, name, base, specs, pivot):
    """A cluster of flame tongues standing on `base` (y), each with a paper core and flicks."""
    with p.group(name, pivot):
        polys = [tongue(x, base, h, w, lean) for x, h, w, lean in specs]
        line = [(x + w * 0.1, base - h * 0.95) for x, h, w, lean in sorted(specs)]
        shade, marks = shaded(spline([(300, base - 90), (400, base - 40), (480, base)], 6), (1, 0.6),
                              count=3, lmin=10, lmax=22, w=6)
        for x, h, w, lean in specs:
            marks.append(flick(x - w * 0.12, base - 4, h * 0.6, lean * 0.7, w=w * 0.16))
            if h > 90:
                marks.append((path(flame_pts(x - w * 0.1, base - h * 0.1, h * 0.38, w * 0.26, lean * 0.8)), PAPER))
            else:
                marks.append(stroke(spline(wave((x, base), (x + lean * h, base - h * 0.8), 3, n=5), 3), w * 0.18, 0.6, INK))
        rpart(p, polys, shade, marks)


def back_blaze(p):
    specs = [(150, 150, 80, -0.25), (210, 210, 90, -0.1), (300, 250, 100, 0.15), (370, 190, 80, 0.3),
             (420, 120, 60, 0.4), (260, 170, 80, 0.05)]
    blaze(p, "blaze_back", 470, specs, (270, 470))


def front_blaze(p):
    specs = [(70, 46, 38, -0.5), (112, 96, 52, -0.35), (150, 160, 70, -0.18), (196, 72, 48, 0.1),
             (236, 128, 66, -0.05), (284, 54, 44, 0.3), (318, 150, 72, 0.22), (370, 88, 54, 0.4),
             (412, 120, 56, 0.5), (452, 52, 40, 0.6)]
    blaze(p, "blaze_front", 478, specs, (260, 478))


def arm(p, side, shoulder, elbow, wrist, claw_ang, shade_dir, dark=False):
    s = "front" if side > 0 else "back"
    with p.group(f"upper_arm_{s}", shoulder):
        upper = licked(taper([shoulder, elbow], 64, 44), 20, step=16, up=1.3, lean=0.5)
        line = [(shoulder[0] + 10 * side, shoulder[1]), (elbow[0] + 12 * side, elbow[1])]
        shade, marks = shaded(spline([line[0], ((line[0][0] + line[1][0]) / 2 + 6, (line[0][1] + line[1][1]) / 2), line[1]], 6),
                              shade_dir, count=4, lmin=8, lmax=20, w=5)
        marks.append(flick(elbow[0] - 6 * side, elbow[1] - 4, 50, -0.2 * side, w=5))
        rpart(p, [upper], shade if not dark else None, marks, color=INK if dark else None)
    with p.group(f"forearm_{s}", elbow):
        fore = licked(taper([elbow, wrist], 46, 34), 16, step=15, up=1.3, lean=0.5)
        shade, marks = shaded(spline([(elbow[0] + 8, elbow[1]), (wrist[0] + 8, wrist[1])], 4),
                              shade_dir, count=3, lmin=6, lmax=16, w=5)
        marks.append(flick(wrist[0], wrist[1] - 2, 46, 0.15 * side, w=4))
        rpart(p, [fore], shade if not dark else None, marks, color=INK if dark else None)
    with p.group(f"claw_{s}", wrist):
        claw_hand(p, wrist, claw_ang, dark)


def claw_hand(p, at, ang, dark):
    hx, hy = at
    polys = [knob(hx, hy, 22, 7, 0.2)]
    for i in range(4):
        a = ang + 1.1 * (i / 3 - 0.5)
        L = rng.uniform(52, 64)
        tip = (hx + math.cos(a + 0.45) * L, hy + math.sin(a + 0.45) * L)
        mid = (hx + math.cos(a) * L * 0.62, hy + math.sin(a) * L * 0.62)
        polys.append(taper(bezier((hx, hy), mid, tip, 10), 15, 1.2))
    shade, marks = shaded(spline([(hx - 26, hy - 4), (hx + 4, hy + 10), (hx + 30, hy + 40)], 4), (1, 0.3),
                          count=3, lmin=6, lmax=12, w=4)
    rpart(p, polys, shade if not dark else None, marks, color=INK if dark else None, sw=4)


def body(p):
    with p.group("body", (258, 300)):
        outline = [(140, 150), (182, 124), (218, 112), (300, 114), (344, 128), (378, 152), (372, 204),
                   (344, 238), (322, 300), (334, 380), (182, 384), (196, 300), (172, 236), (146, 200)]
        poly = licked(outline, 32, step=18, up=1.4, spread=0.6, lean=0.5)
        line = spline([(300, 118), (290, 190), (300, 260), (316, 330), (330, 390)], 6)
        shade, marks = shaded(line, (1, 0.1), count=7, lmin=12, lmax=30, w=7)
        marks += [
            stroke(spline([(176, 176), (214, 196), (252, 190)], 5), 7, 2, INK),   # pec line
            stroke(spline([(256, 194), (286, 204), (306, 190)], 5), 6, 2, INK),
            stroke(spline([(254, 196), (252, 250), (256, 320)], 5), 5, 1, INK),   # sternum / abs
            stroke(spline([(214, 236), (240, 244), (252, 240)], 4), 5, 1, INK),
            stroke(spline([(218, 274), (240, 280), (252, 276)], 4), 5, 1, INK),
            stroke(spline([(224, 312), (240, 318), (252, 314)], 4), 4, 1, INK),
        ]
        marks += [flick(x, 384, rng.uniform(70, 130), rng.uniform(-0.2, 0.2), w=7) for x in (200, 222, 266, 290)]
        for x, y, h in ((168, 236, 70), (196, 172, 50), (234, 360, 90), (308, 224, 60)):
            ln = spline(wave((x, y), (x + 10, y - h), 5, waves=0.9, n=6, phase=x * 0.1), 3)
            marks.append(stroke(ln, 9, 0.8, INK))
        rpart(p, [poly], shade, marks)


def head(p):
    with p.group("head", (240, 134)):
        crest = [(196, 104), (210, 70), (238, 58), (270, 66), (292, 92), (290, 122), (276, 140),
                 (246, 150), (210, 146), (192, 128)]
        poly = licked(crest, 50, step=13, up=1.5, spread=0.5, lean=0.8)
        line = spline([(270, 66), (286, 110), (270, 148)], 5)
        shade, marks = shaded(line, (1, 0.2), count=3, lmin=6, lmax=14, w=5)
        marks += [
            (path([(192, 98), (250, 96), (246, 108), (222, 112), (196, 110)]), INK),   # brow ridge
            (path([(200, 112), (222, 112), (218, 122), (204, 120)]), INK),              # eye socket
            (path([(232, 110), (250, 106), (248, 118), (236, 120)]), INK),
            (path([(198, 132), (240, 130), (236, 150), (222, 158), (204, 150)]), INK),  # maw
        ]
        marks += [(path([(x, 132), (x + 7, 132), (x + 3.5, 144)]), PAPER) for x in (204, 214, 224)]
        marks += [(path([(x, 152), (x + 6, 152), (x + 3, 142)]), PAPER) for x in (210, 222)]
        marks += [flick(x, 92, rng.uniform(40, 60), 0.5, w=5) for x in (218, 244, 266)]
        rpart(p, [poly], shade, marks)
        p.fill(path([(205, 114), (219, 114), (214, 119), (207, 118)]), HOT)
        p.fill(path([(236, 112), (248, 109), (246, 115), (238, 116)]), HOT)


def sparks(p):
    with p.group("sparks", (256, 120)):
        for x, y, r in ((96, 120, 7), (130, 70, 5), (330, 52, 6), (400, 96, 8), (436, 160, 5), (70, 200, 6),
                        (372, 30, 4), (180, 40, 5), (452, 260, 5)):
            pts = [(x + r * 0.6, y - r * 2.2), (x + r * 0.7, y), (x, y + r * 0.8), (x - r * 0.6, y)]
            rpart(p, [pts], color=ORANGE, sw=2, reg=(2, 2))


def build():
    p = Print(ORANGE, seed=33)
    back_blaze(p)
    arm(p, -1, (352, 160), (410, 236), (414, 318), math.pi / 2 - 0.1, (1, 0.2), dark=True)
    body(p)
    head(p)
    arm(p, 1, (166, 162), (112, 242), (92, 322), math.pi / 2 + 0.25, (1, 0.25))
    front_blaze(p)
    sparks(p)
    return p


if __name__ == "__main__":
    build().save("fire_elemental")
