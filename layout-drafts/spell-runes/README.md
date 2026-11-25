# Spell runes (draft)

Spell icons built from a hand-drawn rune alphabet (26 runes for A-Z, 10 for the digits 0-9).
A spell's icon is the rune of one or two letters of its name, glowing like embers on a dark disc
in the spell's colour, so it matches the Ember Grimoire layout drafts.

## Sheets

| File | Content |
|---|---|
| `03_all_spells.png` | **Main proposal**: every spell and alchemy result in the game, large and at game size (r = 19) |
| `00_overview.png` | Sample spells with one letter each, plus the alchemy row |
| `01_alphabet_trace.png` | The traced alphabet. Check against the original sketch, the tracing was done by eye |
| `02_how_to_read.png` | How several letters fuse into one rune (Frost -> F-R-S) |

## Generators

Requires Python 3 and `rsvg-convert`.

- `runes.py`: the generator. It turns plain letters into SVG icons.
  - `spell_icon("FR", "#ff4000")` returns a standalone SVG. `spell_body(...)` returns a fragment for a larger sheet.
  - `alchemy_icon(catalyst, reactant_a, reactant_b, colour)` does the same for alchemy results; each argument is a letter string.
  - CLI: `python runes.py spell FR "#ff4000" out.png [radius]` and
    `python runes.py alchemy FR FR FS "#d9d9d9" out.png [radius]`. An output name ending in `.png` is rendered directly.
- `gen_all_spells.py`: builds `03_all_spells.png`. It reads spell names and colours from
  `scripts/battle/spells/*.gd` and the recipes from `scripts/battle/alchemy_table.gd`, so rerunning it keeps the
  sheet in sync with the game.
- `gen_runes.py`: builds the other three sheets.

## Rules

**Which letters a spell gets**
- If the spell's first letter is unique among all spells: that one letter (Amplify = A).
- If other spells share the first letter: that letter fused with the next consonant that is still free
  (Fire = F-R, Frost = F-S). Multi-word names use their initials (Force Push = F-P).
- The 8 Bolt directions share one rune for now. The direction needs a separate marker.

**How letters fuse** (kept simple, so a reader can decode it once they know the rule)
- Every letter keeps its drawn shape. Nothing is mirrored or rotated.
- Letters with a long vertical stroke slide sideways until those strokes coincide (a shared stem).
  Letters without one stay centred.
- Strokes that end up nearly parallel (within 22°), close together (within 0.15 of the glyph size) and
  overlapping collapse into a single normal-width line.
- Line ends that nearly touch (within 0.06) snap onto one point.
- The fused rune does not show letter order: D-S and S-D give the same sign.

**Alchemy results**
- The two reactants' runes sit on top, the catalyst's rune at the bottom. They are pulled together so they touch
  and overlap slightly.
- The whole icon is drawn in the result spell's colour only.

## Rename proposals (not yet applied in the game)

With the fuse rule alone, three spells were unreadable or clashed. `gen_all_spells.py` previews these renames via
`RENAMES`:

| Now | Proposal | Problem with the current name |
|---|---|---|
| Sunder | Shatter (S-H) | S-D gives the same rune as Distillation's D-S |
| Conductor | Galvanize (G) | C and N runes are near-identical and merge into one shape |
| Bomb | Blast (B-L) | The M rune disappears into the B frame |

With these, no two spells share the same letter set.

## Known issues

- Some runes are close: F and T are both crossed lines, C and N are both corner shapes, Q is O with a dot.
  Worth redrawing in the alphabet itself.
- Pale spell colours (Steam, Soap, Single) look alike at game size, and Bomb's dark grey almost disappears on the
  dark disc.
- Alchemy icons are legible at large size. At game size they read as one compact glyph, not as three letters.
- Rejected directions (removed): carved stone, parchment brush, name ring, witch's-wheel sigil, full-spelling
  ligatures, block layout, and bind-runes with mirrored letters.
