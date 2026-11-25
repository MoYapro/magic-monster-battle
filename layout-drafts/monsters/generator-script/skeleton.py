"""Skeleton (linocut v2): a gaunt, anatomically built bone warrior, sword held low, shield raised."""
import math

from helpers_a import (Print2, bony_foot, curve_cut, curved_rib, finger_bones, form, ink_line, long_bone,
                       paper_line, scaled)
from style import INK, PAPER, eyes, ground, knob, path, rng, rough, sliver

BONE = "#d9bf85"

J = dict(
    sh_near=(206, 164), el_near=(184, 236), wr_near=(176, 300),
    sh_far=(304, 162), el_far=(330, 232), wr_far=(336, 294),
    hip_near=(234, 306), kn_near=(214, 386), an_near=(204, 452),
    hip_far=(282, 306), kn_far=(300, 386), an_far=(316, 452),
)


SK = 0.8                 # skull scale: keeps the head small and gaunt
SKC = (252, 150)         # scale centre (base of the neck)


def S(pts):
    return scaled(pts, SK, SKC)


def skull(p):
    with p.group("skull", (258, 142)):
        cranium = S([(204, 84), (208, 64), (222, 46), (246, 34), (272, 36), (290, 50), (298, 72), (296, 94),
                     (286, 108), (272, 114), (262, 122), (246, 124), (226, 126), (212, 124), (206, 112),
                     (200, 100)])
        far_socket = S([(204, 78), (218, 74), (222, 90), (214, 100), (205, 96)])
        near_socket = S([(230, 74), (254, 70), (262, 86), (254, 102), (236, 102), (228, 88)])
        nose = S([(210, 102), (220, 102), (218, 116), (212, 116)])
        marks = [(path(rough(s, amp=0.8)), INK) for s in (far_socket, near_socket, nose)]
        marks.append(ink_line(*S([(258, 104), (272, 100), (288, 102)]), 3))
        marks.append(ink_line(*S([(262, 38), (268, 54), (262, 66)]), 2.5))
        marks.append(ink_line(*S([(262, 66), (272, 72), (284, 70)]), 2))
        marks.append(ink_line(*S([(226, 68), (244, 62), (262, 66)]), 3))
        marks += [(sliver(*S([(208 + i * 7, 118)])[0], math.pi / 2, 8, 4), INK) for i in range(6)]
        form(p, [cranium], tuple(S([(264, 34), (290, 78), (262, 126)])), toward=(1, 0.35), marks=marks,
             sw=4, rows=2, count=5, lmin=5, lmax=12, w=4, gap=6)
        eyes(p, S([(214, 88), (246, 88)]), 3.5)


def jaw(p):
    with p.group("jaw", (270, 120)):
        mand = S([(206, 122), (244, 126), (266, 118), (276, 102), (284, 106), (280, 128), (262, 142),
                  (236, 150), (216, 146), (204, 134)])
        marks = [(sliver(*S([(210 + i * 7, 125)])[0], -math.pi / 2, 8, 4), INK) for i in range(5)]
        form(p, [mand], tuple(S([(230, 152), (258, 130), (284, 102)])), toward=(0.5, 1), marks=marks,
             sw=3.5, rows=0, count=3, lmin=4, lmax=8, w=3)


def spine(p):
    with p.group("neck", (258, 152)):
        polys = [knob(258, 134 + i * 7, 6, 6, 0.3) for i in range(3)]
        p.part(polys, sw=3)
    with p.group("spine", (258, 290)):
        polys = [knob(258, 238 + i * 11, 8.5, 6, 0.2 * i) for i in range(5)]
        marks = [(sliver(266, 238 + i * 11, 0, 7, 4), INK) for i in range(5)]
        p.part(polys, marks=marks, sw=3.5)


def ribcage(p):
    with p.group("ribcage", (256, 240)):
        cavity = [(214, 166), (248, 152), (290, 160), (306, 186), (302, 222), (284, 248), (256, 256),
                  (226, 248), (206, 220), (204, 188)]
        p.part([cavity], color=INK, sw=3)
        ribs = []
        for i in range(7):
            y = 168 + i * 11
            narrow = max(0, i - 4) * 6
            ribs.append(curved_rib((247, y), (212 + narrow, y - 4), (208 + i * 1.5 + narrow * 1.6, y + 19), 8))
            ribs.append(curved_rib((255, y), (284 - narrow, y - 3), (298 - i * 1.5 - narrow * 1.6, y + 18), 7))
        sternum = [(244, 156), (256, 156), (258, 214), (250, 230), (243, 214)]
        clav = [curved_rib((250, 158), (230, 150), J["sh_near"], 9),
                curved_rib((254, 158), (280, 150), J["sh_far"], 8)]
        shade, marks = curve_cut((262, 150), (292, 200), (264, 260), toward=(1, 0.3), count=6,
                                 lmin=5, lmax=10, w=3)
        p.part(ribs + [sternum] + clav, shade, marks, sw=2.8)


def pelvis(p):
    with p.group("pelvis", (258, 292)):
        left = [(212, 264), (240, 270), (250, 288), (240, 304), (222, 302), (206, 284)]
        right = [(270, 270), (300, 260), (310, 282), (298, 302), (280, 306), (266, 290)]
        sacrum = [(250, 280), (266, 280), (262, 312), (254, 312)]
        pubis = [(230, 300), (286, 300), (276, 326), (240, 326)]
        marks = [(path(rough(knob(244, 312, 6, 6), amp=0.6)), INK), (path(rough(knob(272, 312, 6, 6), amp=0.6)), INK)]
        marks.append(ink_line((224, 282), (236, 286), (246, 300), 2.5))
        form(p, [left, right, sacrum, pubis], ((282, 262), (298, 292), (288, 326)), toward=(1, 0.2), marks=marks,
             sw=3.5, rows=1, count=4, lmin=5, lmax=10, w=3, gap=6)


def leg(p, side, toe_x):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        long_bone(p, hp, kn, 12, ends=1.9)
        p.part([knob(kn[0] - 3, kn[1] - 2, 8, 6)], sw=3)
    with p.group(f"shin_{side}", kn):
        long_bone(p, kn, an, 10, ends=1.6)
        ox = 7
        long_bone(p, (kn[0] + ox, kn[1] + 10), (an[0] + ox, an[1] - 6), 4.5, ends=1.2, knobs=(False, False))
    with p.group(f"foot_{side}", an):
        bony_foot(p, an, toe_x)


def arm_bones(p, side):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        p.part([knob(*sh, 10, 6)], sw=3)
        long_bone(p, sh, el, 10, ends=1.6)
    with p.group(f"forearm_{side}", el):
        long_bone(p, el, wr, 8, ends=1.4)
        long_bone(p, (el[0] + 6, el[1] + 6), (wr[0] + 6, wr[1] - 2), 5, ends=1.1, knobs=(False, False))


def shield(p):
    cx, cy, rx, ry = 350, 262, 46, 72
    with p.group("shield", J["wr_far"]):
        rim_pts = [(cx + rx * math.cos(a) * (1 + 0.03 * math.sin(3 * a)), cy + ry * math.sin(a))
                   for a in (i * 2 * math.pi / 28 for i in range(28))]
        planks = [ink_line((cx - rx + d, cy - ry * 0.9 + abs(d - rx) * 0.4), (cx - rx + d, cy),
                           (cx - rx + d, cy + ry * 0.9 - abs(d - rx) * 0.4), 2.5, 2.5) for d in (24, 46, 68)]
        notch = [(path([(cx + rx - 4, cy - 30), (cx + rx + 6, cy - 22), (cx + rx - 2, cy - 14)]), INK)]
        form(p, [rim_pts], ((cx + 10, cy - ry - 10), (cx + 34, cy), (cx + 6, cy + ry + 10)), toward=(1, 0.4),
             marks=planks + notch, sw=5, rows=2, count=7, lmin=8, lmax=16, w=4, gap=8)
        band = [(cx + rx * 0.86 * math.cos(a), cy + ry * 0.88 * math.sin(a)) for a in
                (i * 2 * math.pi / 28 for i in range(28))]
        p.fill(path(rough(band, amp=1.2)) + path(rough(rim_pts[::-1], amp=0.6)), INK)
        boss = knob(cx - 4, cy, 15, 8, 0.2)
        shade, marks = curve_cut((cx - 8, cy - 16), (cx + 6, cy - 2), (cx - 6, cy + 16), toward=(1, 0.5),
                                 count=2, lmin=3, lmax=6, w=2)
        p.part([boss], shade, marks, sw=3.5, color=PAPER)


def sword(p):
    hx, hy = J["wr_near"][0] - 2, J["wr_near"][1] + 12
    ux, uy = -0.533, 0.846
    nx, ny = uy, -ux
    gx, gy = hx + ux * 18, hy + uy * 18
    tx, ty = gx + ux * 160, gy + uy * 160
    with p.group("sword", (hx, hy)):
        nicks = []
        blade = [(gx + nx * 8, gy + ny * 8)]
        for k in range(1, 8):
            d = k * 20
            off = 7.5 - k * 0.5 - (3 if k in (3, 6) else 0)
            blade.append((gx + ux * d + nx * off, gy + uy * d + ny * off))
        blade.append((tx, ty))
        blade += [(gx + ux * d - nx * (7.5 - d / 40), gy + uy * d - ny * (7.5 - d / 40)) for d in range(140, 0, -20)]
        blade.append((gx - nx * 8, gy - ny * 8))
        nicks.append(paper_line((gx + ux * 10, gy + uy * 10), (gx + ux * 60, gy + uy * 60),
                                (gx + ux * 120, gy + uy * 120), 2.5, 1))
        shade = path([(gx, gy), (tx, ty), (tx - nx * 30, ty - ny * 30), (gx - nx * 30, gy - ny * 30)])
        rust = [(path(rough(knob(gx + ux * d - nx * 2, gy + uy * d - ny * 2, rng.uniform(2, 4), 5), amp=0.5)), INK)
                for d in (36, 74, 98, 130)]
        p.part([blade], shade, nicks + rust, color=PAPER, sw=3.5)
        guard = [(gx + nx * 26, gy + ny * 26 - 2), (gx + nx * 26 + ux * 7, gy + ny * 26 + uy * 7),
                 (gx - nx * 24 + ux * 7, gy - ny * 24 + uy * 7), (gx - nx * 24, gy - ny * 24 + 2)]
        grip = [(hx - ux * 26 + nx * 5, hy - uy * 26 + ny * 5), (gx + nx * 5, gy + ny * 5),
                (gx - nx * 5, gy - ny * 5), (hx - ux * 26 - nx * 5, hy - uy * 26 - ny * 5)]
        p.part([guard, grip, knob(hx - ux * 30, hy - uy * 30, 7, 6)], sw=3.5, color=INK)


def build():
    p = Print2(BONE, seed=21)
    with p.group("ground", (260, 474)):
        ground(p, 120, 400, 470)
    arm_bones(p, "far")
    with p.group("hand_far", J["wr_far"]):
        finger_bones(p, J["wr_far"], math.pi * 0.5, fingers=3, length=26, w=5, palm=8, color=BONE)
    shield(p)
    leg(p, "far", 272)
    pelvis(p)
    leg(p, "near", 160)
    spine(p)
    ribcage(p)
    skull(p)
    jaw(p)
    arm_bones(p, "near")
    sword(p)
    with p.group("hand_near", J["wr_near"]):
        finger_bones(p, (J["wr_near"][0] - 2, J["wr_near"][1] + 10), math.pi * 0.05, fingers=4, length=20,
                     spread=0.9, w=6, curl=1.3, palm=9, color=BONE)
    return p


if __name__ == "__main__":
    build().save("skeleton")
