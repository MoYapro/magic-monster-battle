"""Mud: dark churned earth with sunken hollows and wet glossy streaks."""
import math

from style import Tile, blob, rng, scatter, taper

BASE, EDGE = "#33251a", "#1d150e"
HOLLOW, RIDGE, GLINT = "#24190f", "#4b3726", "#6f5a42"


def hollow(t, x, y, r):
    """A sunken, wet hollow: dark pit, lighter churned ridge on its top-left rim, a glint."""
    t.poly(blob(x - 3, y - 4, r * 1.6, r * 0.7, rot=rng.uniform(-0.3, 0.3)), RIDGE, 0.9)
    t.poly(blob(x, y, r * 1.3, r * 0.45, rot=rng.uniform(-0.3, 0.3)), HOLLOW, 0.85)
    gx, gy = x - r * 0.3, y - r * 0.15
    t.poly(taper([(gx, gy), (gx + r * 0.5, gy - r * 0.1)], 3, 0.5), GLINT, 0.9, carve=False)


def streak(t, x, y, length):
    a = rng.uniform(-0.3, 0.1)
    pts = [(x + length * i / 6 * math.cos(a), y + length * i / 6 * math.sin(a) + 2 * math.sin(i)) for i in range(7)]
    t.poly(taper(pts, 0.5, 3.5), GLINT, 0.7, carve=False)


def build(seed, variant):
    t = Tile(seed)
    t.base(BASE, EDGE)
    t.texture(EDGE)
    for x, y in scatter(4 if variant == 1 else 6, margin=44, min_dist=55):
        hollow(t, x, y, rng.uniform(14, 24))
    for x, y in scatter(9, margin=30):
        streak(t, x, y, rng.uniform(18, 34))
    return t


def main():
    for v in (1, 2):
        build(600 + v, v).save(f"mud_{v}")


if __name__ == "__main__":
    main()
