"""1x1 obstacles (512 x 512): barrel, ice block, lava rock, pyre, rotted stump, spore vent,
stone, thornbush, web cocoon."""
import math

from kit import (thread, EMBER, INK, PAPER, ObstaclePrint, bezier, boulder, cast_shadow, crack, end_rings, flame_pts,
                 form, grain_lines, ink_line, jag, knob, leaf, lerp, oval, paper_line, path, pebbles, puff, rng,
                 rock, sliver, smoke_wisps, spots, taper, twig)

BASE = (256, 446)


def barrel(p):
    cast_shadow(p, 262, 448, 128)
    left = [(150, 150), (128, 290), (150, 438)]
    right = [(362, 150), (384, 290), (362, 438)]
    body = bezier(*left, 14) + bezier(*right, 14)[::-1]
    staves = [ink_line((cx, 160), (cx + (cx - 256) * 0.18, 292), (cx, 432), 3.5, 2) for cx in (182, 214, 246, 278, 310, 340)]
    hoops = [(path(taper(bezier((132, y), (256, y + 26), (380, y), 12), 13, 13)), INK) for y in (196, 380)]
    hoops += [(path(taper(bezier((140, y + 2), (256, y + 26), (372, y + 2), 12), 3, 3)), PAPER) for y in (196, 380)]
    rivets = [(path(knob(x, y, 4.5, 6)), PAPER) for x, y in ((170, 205), (256, 222), (340, 205), (170, 389), (256, 406))]
    form(p, body, ((352, 140), (380, 300), (352, 450)), color="#b07a3a", count=6, marks=staves + hoops + rivets)
    top = oval(256, 150, 106, 28, 24)
    form(p, top, ((180, 170), (256, 160), (340, 140)), color="#d2a060", count=3, lmin=4, lmax=8, w=3, rows=0,
         marks=[ink_line((165, 150), (256, 162), (346, 150), 3, 1), ink_line((185, 140), (256, 128), (330, 140), 3, 1)])
    pebbles(p, [(110, 444, 10), (404, 446, 8), (96, 432, 6)])


def ice_block(p):
    cast_shadow(p, 260, 440, 150, 14)
    puddle = oval(256, 438, 150, 18, 22)
    form(p, puddle, ((120, 440), (256, 430), (400, 436)), color="#9fd4ee", count=3, lmin=6, lmax=14, w=3, rows=0,
         marks=[paper_line((150, 440), (210, 436), (260, 442), 3, 1)])
    top = [(150, 150), (300, 118), (392, 150), (244, 186)]
    front = [(150, 150), (244, 186), (246, 420), (146, 392)]
    side = [(244, 186), (392, 150), (386, 384), (246, 420)]
    cracks = [(crack((170, 210), (230, 330), kinks=3, w=3), INK), (crack((200, 380), (235, 260), kinks=2, w=2.5), INK)]
    gleam = [paper_line((165, 175), (175, 260), (170, 360), 5, 1.5), paper_line((185, 190), (190, 230), (186, 280), 3, 1)]
    form(p, front, ((236, 186), (240, 300), (240, 424)), color="#bfe4f4", count=3, rows=0, marks=cracks + gleam)
    form(p, side, ((330, 160), (344, 300), (330, 410)), color="#9fd4ee", count=5,
         marks=[(crack((300, 200), (350, 360), kinks=3, w=3), PAPER)])
    form(p, top, ((140, 120), (200, 130), (260, 110)), color="#e2f3fa", count=1, rows=0,
         marks=[paper_line((190, 150), (260, 140), (330, 150), 4, 1)])
    for x, y in ((160, 400), (330, 412)):
        p.part([taper([(x, y), (x + 2, y + 18), (x, y + 30)], 9, 2)], color="#bfe4f4", sw=3)


def lava_rock(p):
    cast_shadow(p, 262, 444, 150)
    poly = [(110, 330), (126, 220), (190, 150), (290, 128), (370, 170), (412, 250), (404, 360), (330, 438),
            (190, 440), (126, 400)]
    pits = [(path(knob(x, y, r, 7, rng.uniform(0, 1))), INK) for x, y, r in
            ((180, 230, 16), (230, 190, 11), (276, 238, 19), (160, 300, 12), (214, 290, 9), (312, 200, 10),
             (250, 330, 14), (190, 360, 10), (340, 270, 9))]
    rims = [(path(knob(x - 3, y - 3, r * 0.45, 6)), PAPER) for x, y, r in ((180, 230, 16), (276, 238, 19), (250, 330, 14))]
    glow = [(path(taper([(300, 300), (330, 330), (346, 390), (330, 430)], 8, 2)), EMBER),
            (path(taper([(150, 380), (200, 400), (240, 432)], 6, 2)), EMBER),
            (path(taper([(360, 220), (380, 280), (400, 300)], 6, 2)), EMBER)]
    form(p, poly, ((380, 170), (350, 330), (210, 446)), color="#5a3a2a", count=7, rows=2, marks=pits + rims + glow)
    pebbles(p, [(100, 440, 13), (424, 438, 11), (440, 418, 7)], color="#5a3a2a")


def pyre(p):
    cast_shadow(p, 262, 450, 170)
    flames = [(246, 330, 230, 120, -0.05), (196, 340, 150, 80, -0.2), (306, 342, 170, 86, 0.18),
              (156, 360, 100, 60, -0.3), (350, 362, 110, 60, 0.3)]
    for x, y, h, w, lean in flames:
        poly = flame_pts(x, y, h, w, lean)
        core = (path(flame_pts(x - w * 0.05, y - h * 0.04, h * 0.5, w * 0.4, lean * 0.6)), PAPER)
        form(p, poly, ((x + w * 0.2, y - h), (x + w * 0.35, y - h * 0.4), (x + w * 0.2, y)), color=EMBER,
             count=2, lmin=8, lmax=16, w=4, rows=0, marks=[core])
    logs = [((100, 430), (300, 330)), ((412, 430), (210, 330)), ((150, 444), (380, 380)), ((360, 446), (130, 372)),
            ((250, 446), (256, 300))]
    for a, b in logs:
        poly = taper([a, lerp(a, b, 0.5), b], 38, 32)
        form(p, poly, (lerp(a, b, 0.0), lerp(a, b, 0.5), b), color="#8a5a2a", count=3, rows=0,
             marks=grain_lines(a, b, 2, 12, 3) + end_rings(a[0], a[1], 13, 13, 2, 2))
    smoke_wisps(p, [(250, 110, 70, 16, 0.5), (290, 120, 56, 12, 0.8)])


def rotted_stump(p):
    cast_shadow(p, 262, 446, 170)
    top = jag((176, 170), (340, 150), 5, 40)
    body = [(150, 430), (176, 300)] + top + [(352, 300), (372, 430)]
    roots = [taper(bezier((180, 400), (120, 420), (70, 446), 10), 34, 6),
             taper(bezier((340, 400), (400, 418), (448, 444), 10), 34, 6),
             taper(bezier((250, 420), (240, 440), (220, 456), 8), 30, 8)]
    for r in roots:
        form(p, r, ((r[0][0], r[0][1]), (r[3][0], r[3][1] + 4), (r[6][0], r[6][1] + 4)), color="#8a7a4a", count=2, rows=0)
    form(p, body, ((334, 150), (352, 300), (346, 440)), color="#8a7a4a", count=6,
         marks=grain_lines((200, 210), (210, 420), 3, 50) + [(path(knob(230, 280, 14, 7)), INK),
                                                            (path(knob(226, 276, 6, 6)), PAPER)])
    for x, y, w in ((190, 300, 46), (330, 260, 40), (176, 370, 36), (350, 360, 30)):
        shelf = [(x - w / 2, y), (x + w / 2, y), (x + w * 0.42, y + 10), (x, y + 16), (x - w * 0.42, y + 10)]
        p.part([shelf], color=PAPER, sw=3, marks=[ink_line((x - w * 0.35, y + 6), (x, y + 10), (x + w * 0.35, y + 6), 2, 1)])
    for x in (110, 140, 380, 410):
        for k in range(3):
            p.part([taper([(x + k * 8, 446), (x + k * 8 + rng.uniform(-14, 14), 446 - rng.uniform(30, 60))], 7, 1)],
                   color="#7aa653", sw=2)


def spore_vent(p):
    cast_shadow(p, 262, 446, 170)
    bulb = [(170, 440), (120, 380), (126, 300), (180, 250), (220, 210), (226, 170), (290, 170), (296, 212),
            (340, 252), (394, 300), (400, 380), (350, 440)]
    form(p, bulb, ((330, 230), (386, 330), (330, 446)), color="#b89ad0", count=6,
         marks=spots(250, 330, 110, 70, 12, 5, 11, INK) + [ink_line((200, 260), (180, 360), (200, 440), 3, 1),
                                                           ink_line((320, 262), (340, 360), (318, 440), 3, 1)])
    p.part([oval(258, 172, 34, 10, 16)], color=INK, sw=3)
    for x, y, r in ((236, 120, 30), (284, 86, 38), (330, 52, 26), (196, 70, 20), (360, 110, 18), (150, 130, 14)):
        p.part([puff(x, y, r, 5)], color="#e0d0ec", sw=3,
               marks=[paper_line((x - r * 0.5, y - r * 0.2), (x - r * 0.1, y - r * 0.6), (x + r * 0.4, y - r * 0.5), 3, 1)])
    pebbles(p, [(110, 440, 16), (410, 442, 18), (150, 452, 9)], color="#b89ad0")


def stone(p):
    cast_shadow(p, 262, 446, 170)
    poly = [(96, 420), (110, 320), (170, 220), (260, 170), (350, 190), (410, 270), (420, 380), (380, 440), (140, 444)]
    facets = [((170, 220), (230, 320)), ((230, 320), (110, 330)), ((230, 320), (300, 300)), ((300, 300), (350, 190)),
              ((300, 300), (330, 440)), ((230, 320), (230, 440))]
    rock(p, poly, ((392, 230), (396, 360), (330, 446)), color="#a8a090", cracks=2, facets=facets, count=6)
    pebbles(p, [(86, 444, 14), (436, 440, 16), (460, 450, 8), (70, 452, 8)], color="#a8a090")


def thornbush(p):
    cast_shadow(p, 262, 448, 190)
    rng.seed(11)
    bush = [(70, 446), (90, 360), (140, 290), (210, 250), (290, 240), (360, 270), (420, 330), (446, 446)]
    form(p, bush, ((380, 260), (420, 360), (400, 450)), color="#4a6a2a", count=5,
         marks=[(path(knob(rng.uniform(110, 400), rng.uniform(300, 430), rng.uniform(6, 12), 5)), INK) for _ in range(10)])
    for i in range(18):
        a = math.pi * (1.05 + i / 17 * 0.9) + rng.uniform(-0.1, 0.1)
        L = rng.uniform(140, 250)
        root = (256 + rng.uniform(-60, 60), 440)
        tip = (root[0] + math.cos(a) * L, root[1] + math.sin(a) * L * 0.95)
        ctrl = (lerp(root, tip, 0.5)[0] + rng.uniform(-50, 50), lerp(root, tip, 0.5)[1] - rng.uniform(0, 40))
        line = bezier(root, ctrl, tip, 12)
        thread(p, line, 6, 7)
        for k in range(2, 11, 2):
            x, y = line[k]
            side = 1 if k % 4 else -1
            d = path([(x - 3, y), (x + 3, y), (x + side * 14, y - 13)])
            p.rim(d, 4)
            p.fill(d)
    for x, y, ang in ((150, 300, -2.3), (360, 290, -0.8), (300, 250, -1.4), (112, 372, -2.8), (412, 350, -0.3),
                      (226, 262, -1.9)):
        form(p, leaf(x, y, 34, 18, ang), ((x, y), (x + 10, y + 4), (x + 30, y)), color="#7aa653", count=1, rows=0, sw=3)


def web_cocoon(p):
    cast_shadow(p, 262, 446, 170)
    threads = [((256, 260), (20, 20)), ((256, 260), (492, 30)), ((256, 260), (500, 300)), ((256, 260), (10, 330)),
               ((200, 230), (120, 20)), ((320, 230), (400, 10)), ((240, 380), (40, 470)), ((300, 380), (470, 470))]
    for a, b in threads:
        thread(p, [a, lerp(a, b, 0.5), b])
    for a, c, b in (((60, 60), (150, 140), (130, 300)), ((450, 60), (370, 150), (400, 300)),
                    ((40, 200), (120, 260), (60, 400)), ((470, 180), (400, 250), (470, 380))):
        thread(p, bezier(a, c, b, 10), 1.8)
    body = oval(256, 300, 140, 130, 28, -0.25)
    wraps = [(path(taper(bezier((120 + k * 10, 210 + k * 40), (256, 250 + k * 40 + rng.uniform(-20, 20)),
                                 (390 - k * 6, 230 + k * 38), 12), 5, 2)), PAPER) for k in range(5)]
    wraps += [(path(taper(bezier((180, 180 + k * 50), (260, 300), (340, 420 - k * 40), 10), 4, 1.5)), INK) for k in range(3)]
    form(p, body, ((350, 190), (392, 310), (330, 430)), color="#d8d0c0", count=6, marks=wraps)
    for a, b in (((120, 250), (70, 220)), ((370, 380), (430, 410)), ((210, 420), (170, 452))):
        p.part([taper([a, lerp(a, b, 0.5), b], 12, 10), knob(*b, 9, 6)], color=PAPER, sw=3)


OBSTACLES = {
    "barrel": (barrel, "#b07a3a"), "ice_block": (ice_block, "#9fd4ee"), "lava_rock": (lava_rock, "#5a3a2a"),
    "pyre": (pyre, EMBER), "rotted_stump": (rotted_stump, "#8a7a4a"), "spore_vent": (spore_vent, "#b89ad0"),
    "stone": (stone, "#a8a090"), "thornbush": (thornbush, "#6a8a3a"), "web_cocoon": (web_cocoon, "#d8d0c0"),
}
CELLS = (1, 1)
