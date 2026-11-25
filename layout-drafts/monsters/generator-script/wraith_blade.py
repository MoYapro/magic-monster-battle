"""Wraith Blade (linocut v2): a flying magical sword with a will of its own. It hovers diagonally,
point down towards the mages, an ember eye in its fuller and a horned, snarling crossguard, with
solid spectral wisps streaming off the pommel and edges and rune shards drifting around it."""
import math

from helpers_a import Print2, form, ink_line, paper_line
from helpers_e import living_eye, plume_line, rune_glyph, shard
from style import EMBER, INK, PAPER, bezier, knob, path, rng, rough, sliver, taper

SPECTRE = "#b46fa6"   # red-violet, clearly apart from the cursed knight's blue-violet

ANG = math.radians(134)                     # pommel -> tip, pointing down-left at the mages
U = (math.cos(ANG), math.sin(ANG))
N = (-U[1], U[0])                           # points up-left
G = (318, 166)                              # centre of the crossguard
BLADE_L, BLADE_W = 326, 58


def at(d, s=0.0, base=G):
    """A point d along the blade axis from `base` and s to the side (towards N)."""
    return (base[0] + U[0] * d + N[0] * s, base[1] + U[1] * d + N[1] * s)


def shadow(p):
    with p.group("ground", (240, 468)):
        blot = [(160, 462), (210, 456), (290, 458), (320, 464), (280, 472), (196, 472)]
        p.part([blot], color=INK, sw=3)


def wisp(root, tip, w, amp, ph):
    line = plume_line(root, tip, amp, ph, waves=1.0)
    return taper(line, w, 2), line


def trail(p, name, roots):
    """Solid spectral wisps streaming up-right, away from the strike."""
    with p.group(name, roots[0][0]):
        polys, marks = [], []
        for root, tip, w, amp, ph in roots:
            poly, line = wisp(root, tip, w, amp, ph)
            polys.append(poly)
            inner = line[2:-4]
            if len(inner) > 3:
                marks.append((path(taper([(x + 2, y + 2) for x, y in inner], max(3, w * 0.2), 0.8)), INK))
        p.part(polys, marks=marks, color=SPECTRE, sw=4)


def trails(p):
    back = (-U[0], -U[1])
    pom = at(-96)
    trail(p, "trail_pommel", [
        (pom, (pom[0] + back[0] * 96 + 26, pom[1] + back[1] * 96 + 40), 34, 10, 0.3),
        (at(-80, 10), (pom[0] + back[0] * 80 - 30, pom[1] + back[1] * 80 + 6), 22, 8, 1.6),
        (at(-80, -12), (pom[0] + back[0] * 60 + 70, pom[1] + back[1] * 60 + 70), 22, 8, 2.5)])
    trail(p, "trail_edge_up", [
        (at(d, BLADE_W * 0.4 * (1 - d / BLADE_L)), (at(d, BLADE_W * 0.4)[0] + back[0] * L + N[0] * 30,
                                                     at(d, BLADE_W * 0.4)[1] + back[1] * L + N[1] * 30),
         w, 10, ph) for d, L, w, ph in ((60, 120, 24, 0.4), (140, 140, 22, 1.3), (220, 130, 18, 2.2))])
    trail(p, "trail_edge_down", [
        (at(d, -BLADE_W * 0.4 * (1 - d / BLADE_L)), (at(d, -BLADE_W * 0.4)[0] + back[0] * L - N[0] * 34,
                                                      at(d, -BLADE_W * 0.4)[1] + back[1] * L - N[1] * 34),
         w, 10, ph) for d, L, w, ph in ((90, 130, 24, 0.9), (180, 140, 20, 1.9))])


def blade(p):
    with p.group("blade", G):
        near, far = [], []
        for k in range(13):
            t = k / 12
            d = BLADE_L * 0.9 * t
            half = BLADE_W / 2 * (1 - 0.35 * t)
            nick = 6 if k in (4, 8) else 0
            near.append(at(d, half - nick))
            far.append(at(d, -half + (5 if k == 6 else 0)))
        poly = near + [at(BLADE_L)] + far[::-1]
        fuller = taper([at(d) for d in range(20, int(BLADE_L * 0.8), 12)], 18, 4)
        marks = [(path(fuller), SPECTRE)]
        for d in (130, 166, 202, 236):
            marks += rune_glyph(*at(d), 7, ANG, color=INK, w=2.6)
        marks += living_eye(*at(74), 17, ANG)
        marks.append(paper_line(at(10, 17), at(140, 13), at(250, 6), 2.5, 1))
        shade = path([at(-10, -11), at(BLADE_L + 10, -4), at(BLADE_L + 10, -60), at(-10, -60)])
        p.part([poly], shade, marks, color=PAPER, sw=4)


def guard(p):
    with p.group("guard", G):
        boss = [at(-14, -24), at(-16, 0), at(-14, 24), at(12, 30), at(26, 14), at(26, -14), at(12, -30)]
        horns = [taper(bezier(at(-4, 24), at(14, 70), at(-44, 80), 12), 24, 3),
                 taper(bezier(at(-4, -24), at(14, -70), at(-44, -80), 12), 24, 3)]
        teeth = [(sliver(*at(24, s), ANG, 12, 6), PAPER) for s in (-14, -5, 4, 13)]
        maw = [(path([at(18, -20), at(30, -14), at(32, 14), at(18, 20), at(22, 0)]), INK)]
        marks = maw + teeth
        marks += living_eye(*at(-2, 13), 6, ANG + math.pi / 2) + living_eye(*at(-2, -13), 6, ANG + math.pi / 2)
        marks += [ink_line(at(-10, 30), at(-4, 0), at(-10, -30), 2.5)]
        form(p, [boss] + horns, (at(-30, -10), at(0, -40), at(40, -30)), toward=(N[0] * -1 + 0.3, -N[1] + 0.3),
             marks=marks, color=SPECTRE, sw=4.5, rows=1, count=6, lmin=5, lmax=10, w=3, gap=7)


def grip(p):
    with p.group("grip", G):
        poly = taper([at(-14), at(-84)], 20, 16)
        marks = [(path(taper([at(-20 - k * 11, 10), at(-26 - k * 11, -10)], 3.5, 3.5)), PAPER) for k in range(6)]
        p.part([poly], marks=marks, color=INK, sw=3.5)


def pommel(p):
    c = at(-96)
    with p.group("pommel", c):
        spikes = [[(c[0] + math.cos(a - 0.25) * 12, c[1] + math.sin(a - 0.25) * 12),
                   (c[0] + math.cos(a) * 30, c[1] + math.sin(a) * 30),
                   (c[0] + math.cos(a + 0.25) * 12, c[1] + math.sin(a + 0.25) * 12)]
                  for a in (ANG + math.pi + k * math.pi / 3 for k in (-1, 0, 1))]
        orb = knob(*c, 15, 9, 0.2)
        marks = [(path(knob(c[0] - 3, c[1] - 3, 6, 6)), EMBER), (path(knob(c[0] - 5, c[1] - 5, 2, 5)), PAPER)]
        form(p, [orb] + spikes, ((c[0] - 4, c[1] - 18), (c[0] + 14, c[1]), (c[0], c[1] + 18)), toward=(1, 0.5),
             marks=marks, color=SPECTRE, sw=4, rows=0, count=3, lmin=4, lmax=8, w=3)


def shards(p):
    with p.group("shards", G):
        spots = [(150, 110, 14, 0.6), (64, 270, 12, 2.0), (250, 340, 13, -0.4), (420, 250, 11, 1.2)]
        polys, marks = [], []
        for x, y, r, a in spots:
            polys.append(shard(x, y, r, a))
            marks += rune_glyph(x, y, r * 0.45, a, color=INK, w=2)
        p.part(polys, marks=marks, color=SPECTRE, sw=3)


def build():
    p = Print2(SPECTRE, seed=89)
    shadow(p)
    trails(p)
    shards(p)
    grip(p)
    pommel(p)
    blade(p)
    guard(p)
    return p


if __name__ == "__main__":
    build().save("wraith_blade")
