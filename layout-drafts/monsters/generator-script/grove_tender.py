"""Grove tender (linocut v2): a slender forest spirit of bark and leaves, with antler-like twigs on
its head, a long leaf robe and a gnarled branch staff. Calm and eerie, slim and humanoid, unlike
the treant. Faces left."""
import math

from helpers_d import body, chain, gouge, grain, sinew
from helpers_g import GPrint, leaf, leaf_vein, twig
from style import INK, PAPER, auto_cut, ground, knob, path, rng, sliver

LEAF = "#93c06a"

J = dict(
    neck=(250, 160), waist=(262, 278),
    sh_far=(296, 174), el_far=(322, 248), wr_far=(314, 318),
    sh_near=(232, 178), el_near=(194, 232), wr_near=(140, 238),
)


def mid(a, b, dx=0, dy=0, t=0.5):
    return a[0] + (b[0] - a[0]) * t + dx, a[1] + (b[1] - a[1]) * t + dy


def leaf_part(p, cx, cy, length, width, angle, color=None, sw=4):
    poly = leaf(cx, cy, length, width, angle)
    shade, marks = auto_cut([poly], depth=0.35, count=2, lmin=6, lmax=12, w=4)
    marks.append(leaf_vein(cx, cy, length, angle, 3, INK if color != INK else PAPER))
    p.part([poly], shade, marks, color=color, sw=sw)


def twig_fingers(p, at, angle, n=4, length=46, color=INK):
    x, y = at
    polys = [knob(x, y, 9, 6)]
    for i in range(n):
        a = angle + (i / (n - 1) - 0.5) * 0.9
        tip = (x + math.cos(a) * length * rng.uniform(0.85, 1.1), y + math.sin(a) * length * rng.uniform(0.85, 1.1))
        polys.append(twig((x, y), tip, 8, 1.5, rng.uniform(-0.2, 0.2)))
    p.part(polys, color=color, sw=3)


def staff(p):
    """A gnarled branch staff, its head split into a crown of twigs with a few leaves."""
    with p.group("staff", J["wr_near"]):
        a, c, b = (122, 460), (104, 260), (118, 86)
        line = chain([a, (112, 380), (124, 300), (106, 220), (116, 140), b])
        sinew(p, [a, (112, 380), (124, 300), (106, 220), (116, 140), b], [16, 18, 15, 17, 14, 12], color=INK,
              frac=0.25, gouges=4, extra=grain(line, 16, n=4, color=PAPER, width=3))
        for knot in ((114, 330), (110, 186)):
            p.part([knob(*knot, 11, 6)], color=INK, sw=3)
        for tip, w in (((80, 40), 10), ((112, 26), 10), ((150, 44), 9), ((64, 70), 7), ((160, 76), 7)):
            p.part([twig(b, tip, w, 1.5, rng.uniform(-0.25, 0.25))], color=INK, sw=3)
        for cx, cy, ang in ((82, 46, -2.2), (150, 50, -0.9), (128, 30, -1.4)):
            leaf_part(p, cx, cy, 30, 14, ang, color=LEAF, sw=3)


def antlers(p):
    with p.group("antlers", (250, 76)):
        for base, tip, w, forks in (((236, 86), (196, 22), 11, ((214, 52), (186, 50))),
                                    ((256, 80), (262, 10), 11, ((260, 44), (282, 26))),
                                    ((272, 90), (318, 34), 10, ((296, 60), (324, 64)))):
            polys = [twig(base, tip, w, 2, 0.15)]
            polys.append(twig(forks[0], forks[1], w * 0.6, 1.5, 0.1))
            p.part(polys, color=INK, sw=3)
        for cx, cy, ang in ((198, 30, -2.4), (282, 22, -0.6), (318, 40, -0.4), (186, 52, 2.9)):
            leaf_part(p, cx, cy, 26, 12, ang, color=LEAF, sw=3)


def head(p):
    """A long, dark bark face with pale carved grain, glowing eyes and a frame of leaves."""
    with p.group("head", J["neck"]):
        for cx, cy, ang in ((214, 104, -2.6), (210, 140, 2.9), (290, 104, -0.5), (294, 140, 0.2), (252, 82, -1.6)):
            leaf_part(p, cx, cy, 40, 18, ang, color=LEAF, sw=3)
        face = [(222, 98), (254, 84), (282, 96), (288, 130), (278, 170), (256, 198), (236, 196), (220, 170),
                (212, 132)]
        grain_lines = grain(chain([(270, 100), (282, 140), (262, 188)]), 30, n=4, color=PAPER, width=3)
        brow = [(gouge((214, 126), (230, 118), (250, 124), 5), PAPER), (gouge((252, 122), (262, 118), (272, 124), 4), PAPER)]
        cheek = [(gouge((232, 152), (236, 166), (232, 180), 4), PAPER)]
        mouth = [(gouge((230, 178), (242, 182), (254, 176), 4), PAPER)]
        p.part([face], marks=grain_lines + brow + cheek + mouth, color=INK, reg=(2, 2))
        p.eye(232, 138, 5)
        p.eye(260, 135, 4)
        for i, (cx, cy) in enumerate(((230, 190), (246, 198), (262, 188))):
            leaf_part(p, cx, cy, 34, 13, math.pi / 2 + (i - 1) * 0.35, color=LEAF, sw=3)


def arm(p, side, widths, color):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        sinew(p, [sh, mid(sh, el, 6), el], widths[:3], color=color, gouges=3,
              extra=grain(chain([sh, el]), widths[0], n=2, color=PAPER if color == INK else INK, width=3))
    with p.group(f"forearm_{side}", el):
        sinew(p, [el, mid(el, wr, -4), wr], widths[2:], color=color, gouges=3,
              extra=grain(chain([el, wr]), widths[2], n=2, color=PAPER if color == INK else INK, width=3))
        leaf_part(p, *mid(sh, el, 0, -4, 0.9), 34, 14, math.atan2(el[1] - sh[1], el[0] - sh[0]) + 0.6,
                  color=LEAF, sw=3)


def torso(p):
    with p.group("torso", J["waist"]):
        hull = [(228, 172), (258, 156), (296, 166), (304, 210), (294, 262), (288, 290), (240, 292), (230, 250),
                (222, 206)]
        ribs = [(gouge((236, 196 + i * 22), (262, 188 + i * 22), (290, 198 + i * 22), 5), INK) for i in range(3)]
        ribs += [(sliver(x, y, 1.9, 18, 4), INK) for x, y in ((246, 206), (270, 228), (252, 250), (276, 268))]
        body(p, hull, [(292, 168), (302, 236), (286, 292)], color=LEAF, count=5, lmin=8, lmax=16, w=5,
             extra=ribs)
        for cx, cy, ang in ((236, 170, 2.2), (270, 164, 1.2), (298, 182, 0.8)):
            leaf_part(p, cx, cy, 36, 16, ang, color=LEAF, sw=3)


def robe(p):
    """A long robe of overlapping hanging leaves, flaring to a ragged leaf hem, roots at the feet."""
    with p.group("robe", J["waist"]):
        for x, ang in ((318, 1.25), (300, 1.4)):
            leaf_part(p, x, 284, 170, 54, ang, color=INK, sw=4)
        for x in (188, 214, 262, 290):
            p.part([twig((x + 30, 430), (x + rng.uniform(-10, 10), 462), 10, 2, 0.2)], color=INK, sw=3)
        for i, (x, ang, ln) in enumerate(((236, 1.9, 178), (252, 1.72, 186), (268, 1.55, 182), (284, 1.4, 172),
                                          (244, 1.8, 140), (276, 1.5, 150))):
            leaf_part(p, x, 276 + (i // 4) * 30, ln, 56 if i < 4 else 44, ang, color=LEAF, sw=4)


def build():
    p = GPrint(LEAF, seed=71)
    with p.group("ground", (256, 466)):
        ground(p, 50, 470, 462)
    arm(p, "far", [20, 18, 16, 14, 12], INK)
    with p.group("hand_far", J["wr_far"]):
        twig_fingers(p, J["wr_far"], math.pi / 2 + 0.1, n=4, length=48)
    robe(p)
    antlers(p)
    torso(p)
    head(p)
    staff(p)
    arm(p, "near", [22, 20, 18, 16, 14], LEAF)
    with p.group("hand_near", J["wr_near"]):
        x, y = J["wr_near"]
        p.part([knob(x - 22, y + 2, 14, 6), [(x - 38, y - 12), (x - 6, y - 10), (x - 4, y + 14), (x - 38, y + 16)]],
               marks=[(sliver(x - 34, y - 6 + i * 8, 0.0, 26, 4), INK) for i in range(3)], color=LEAF, sw=3)
    return p


if __name__ == "__main__":
    build().save("grove_tender")
