"""Overview of every spell and alchemy result in the game, read straight from the GDScript sources.

Each basic spell gets its first letter; spells sharing a first letter fuse it with the next consonant
(multi-word names: their initials). Alchemy results reuse their ingredients' letters.

Usage: python gen_all_spells.py [out_dir]
"""
import re
import subprocess
import sys
from pathlib import Path

from runes import DEFS, alchemy_body, spell_body

ROOT = Path(__file__).resolve().parents[2]
SPELL_DIR = ROOT / "scripts/battle/spells"
ALCHEMY_GD = ROOT / "scripts/battle/alchemy_table.gd"
OUT = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent)
BG, EDGE, TEXT, DIM = "#1b120d", "#a07a48", "#f3e3c4", "#b39470"
NEW_RE = re.compile(r'SpellData\.new\("([^"]+)",[^\[]*\[[^\]]*\], Color\(([\d.]+), ([\d.]+), ([\d.]+)\)')
ADD_RE = re.compile(r'_add\("(\w+)", "(\w+)", "(\w+)",\s*func\(\): return AlchemyResult\.success\(_(\w+)\(\)\)\)')
FUNC_RE = re.compile(r'static func _(\w+)\(\) -> SpellData:\s*var s := (SpellData\.new\([^\n]+)')


# ---------------------------------------------------------------- parsing (pure on text)
def hex_color(r, g, b):
    return "#" + "".join(f"{round(float(c) * 255):02x}" for c in (r, g, b))


def parse_spell(text):
    m = NEW_RE.search(text)
    return (m.group(1), hex_color(*m.groups()[1:])) if m else None


def parse_recipes(text):
    """[(result name, colour, (catalyst_id, a_id, b_id))] in table order."""
    results = {fn: parse_spell(new) for fn, new in FUNC_RE.findall(text)}
    return [(*results[fn], (cat, a, b)) for cat, a, b, fn in ADD_RE.findall(text)]


def load_spells():
    """{spell_id: (name, colour)}; the eight bolt directions collapse into one 'Bolt'."""
    spells = {}
    for f in sorted(SPELL_DIR.glob("spell_*.gd")):
        parsed = parse_spell(f.read_text())
        if parsed:
            sid = "bolt" if f.stem.startswith("spell_bolt_") else f.stem.removeprefix("spell_")
            spells[sid] = ("Bolt (8 directions)", parsed[1]) if sid == "bolt" else parsed
            spells[sid] = (RENAMES.get(spells[sid][0], spells[sid][0]), spells[sid][1])
    return spells


# ---------------------------------------------------------------- letters (pure)
VOWELS = set("AEIOU")
RENAMES = {"Sunder": "Shatter", "Conductor": "Galvanize", "Bomb": "Blast"}  # proposals, not yet in the game


def base_name(name):
    return name.split(" (")[0].upper()


def second_letters(name):
    """Candidates for the fused second letter: other initials for multi-word names, else following consonants."""
    words = base_name(name).split()
    if len(words) > 1:
        return [w[0] for w in words[1:]]
    return [c for c in words[0][1:] if c.isalpha() and c not in VOWELS]


def rune_letters(names):
    """Unique first letter -> that letter; shared first letter -> first letter + next consonant not yet used."""
    firsts = [base_name(n)[0] for n in names]
    taken, out = set(), {}
    for name, first in sorted(zip(names, firsts)):
        if firsts.count(first) == 1:
            out[name] = first
            continue
        pair = next(first + c for c in second_letters(name) if first + c not in taken)
        taken.add(pair)
        out[name] = pair
    return out


# ---------------------------------------------------------------- sheet
def text(x, y, s, size, fill, anchor="middle", weight="normal"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="C059" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{s}</text>')


def tile(x, y, title, sub, big, small):
    return text(x, y - 58, title, 13, TEXT) + text(x, y - 44, sub, 11, EDGE) + big(x - 18, y) + small(x + 50, y + 22)


def spells_section(spells, letters, y0, cols=6, cw=200, rh=150):
    body = text(30, y0 - 20, f"Spells ({len(spells)})", 20, TEXT, "start", "bold")
    for i, (sid, (name, col)) in enumerate(sorted(spells.items(), key=lambda s: s[1][0])):
        x, y = 30 + cw / 2 + (i % cols) * cw, y0 + 75 + (i // cols) * rh
        ch = letters[sid]
        old = next((o for o, n in RENAMES.items() if n == name), None)
        sub = "-".join(ch) + (f"   (was {old})" if old else "")
        body += tile(x, y, name, sub, lambda cx, cy: spell_body(ch, col, cx, cy, 40),
                     lambda cx, cy: spell_body(ch, col, cx, cy, 19))
    return body, y0 + rh * -(-len(spells) // cols)


def alchemy_section(recipes, spells, letters, y0, cols=6, cw=200):
    body = text(30, y0 - 20, f"Alchemy results ({len(recipes)})  -  reactants on top, catalyst at the bottom",
                20, TEXT, "start", "bold")
    for i, (name, col, (cat, a, b)) in enumerate(recipes):
        x, y = 30 + cw / 2 + (i % cols) * cw, y0 + 75
        ls = [letters[s] for s in (cat, a, b)]
        sub = f"{spells[a][0]} + {spells[b][0]} / {spells[cat][0]}"
        body += tile(x, y, name, sub, lambda cx, cy: alchemy_body(*ls, col, cx, cy, 40),
                     lambda cx, cy: alchemy_body(*ls, col, cx, cy, 19))
    return body, y0 + 150


def sheet():
    spells = load_spells()
    recipes = parse_recipes(ALCHEMY_GD.read_text())
    by_name = rune_letters([spells[s][0] for s in sorted(spells)])
    letters = {sid: by_name[name] for sid, (name, _) in spells.items()}
    body = text(30, 45, "All spells - 1 letter, or 2 fused when the first letter is shared", 26, TEXT, "start", "bold")
    spell_svg, y = spells_section(spells, letters, 100)
    alch_svg, y = alchemy_section(recipes, spells, letters, y + 50)
    return 30 * 2 + 200 * 6, y + 20, body + spell_svg + alch_svg


def render(stem):
    w, h, body = sheet()
    svg = OUT / f"{stem}.svg"
    svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
                   f'{DEFS}<rect width="{w}" height="{h}" fill="{BG}"/>{body}</svg>')
    subprocess.run(["rsvg-convert", str(svg), "-o", str(OUT / f"{stem}.png")], check=True)


if __name__ == "__main__":
    render("03_all_spells")
