# Ember Grimoire screen drafts

Every screen drawn in the **Ember Grimoire** look: warm leather, wood and gold, a serif font, wands drawn as staffs with rune sockets, mana as ember drops, double-framed panels, a vignette, and a wax-seal button for the main action. The mood is dim and alchemical. `00_overview.png` shows all thirteen drafts together.

The linocut monster drafts from `monsters/` (rendered by `monsters/build.py` into `monsters/out/`) are embedded into the battle drafts, trimmed to the figure so they fill their cell; tall monsters (troll, treant) take two cells. Names, HP and attacks are the real values from `scripts/battle/monsters/`. Monsters without a drawing would fall back to a coloured token.

## Ground effects

Only **Wet** (puddle) exists in the game today (`GroundType.PUDDLE`). The others are proposals shown in the battle drafts:

Every battlefield cell shows one ground tile from `grounds/` (linocut, like the monsters). Each area mixes a few base grounds (Mossy Caverns: stone, dirt, mud, grass; Graveyard: dirt, mud, grass), picked per cell so the grid doesn't repeat. A state ground (wet, burning, frozen, poisoned, overgrown) replaces the base tile, as `grounds/README.md` describes. Fog and scorched have no tile yet and are still drawn on top. Boulders use the `stone_3` tile, graves are headstones, and monster cards are transparent so the ground shows under the monster.

| Ground | Look | Idea |
|---|---|---|
| Wet | blue pool with ripples | Conducts lightning, freezes into ice *(implemented as puddle)* |
| Frozen | pale ice with cracks | Brittle: cracks for bonus damage |
| Burning | red glow with flames | Burns whoever stands here each turn |
| Scorched | black ash with embers | Left behind after a fire burns out |
| Poisoned | green bog with violet slime | Poisons whoever stands here |
| Overgrown | green with vines | Snares; burns away quickly |
| Fog | drifting grey wisps | Steam: hides what stands inside it |

| File | Screen | Notes |
|---|---|---|
| `01a_battle_caverns.png` | Battle: start of a fight | Mana chalice on the left, mage rows with staffs, stone-map grid, intent badges, Lyra aiming Single + Splash at the goblin. Monsters: goblin (Bite 5 → Lyra), skeleton (Strike 4 → Vael), cave spider (Web Shot 3 → Eron, soaked by his ward), troll (two cells tall, regenerating 30), shadow panther (taking cover). Ground: wet, overgrown, fog. Seal = End Turn |
| `01b_battle_graveyard.png` | Battle: a hard fight | Vael has fallen (greyed row), Lyra is burning. Two skeletons (one frozen and striking Lyra, one stunned on burning ground), the banshee (blinded, wailing at Lyra) in fog, and a fire elemental (Flame Wave 11 → Eron). Ground: frozen, burning, scorched, toxic, fog, wet. Hovering a cell shows a ground tooltip |
| `01c_battle_won.png` | Battle won | The board dims and a "Victory" plaque shows turns, foes slain and who fell (no alchemy line: alchemy is discovered by tinkering, not unlocked by winning). Seal = Claim Spoils, which opens the loot screen |
| `01d_details_monster.png` | Monster details | Clicking a monster dims the battle and opens a bestiary page over the party side, with a dotted link to the token (still highlighted on the board). Shows art, role and biome, HP, statuses, flavour text, **this turn's action** (highlighted, incl. what its statuses do to it), the other actions it **might** roll, its traits, the ground it stands on, and possible drops |
| `01e_details_mage.png` | Mage details | Clicking a mage opens a page over the board; the mage's row stays lit. Shows HP with incoming damage, attributes (Max HP, mana per turn spent/left, focus element, mana debt from a fizzle), afflictions with duration, every enemy action aimed at this mage, and a one-line preview of what the wand would cast now |
| `01f_battle_big_wands_focus.png` | Battle with large wands: focus | Late-game wands with branches merging toward the tip (Lyra 14 runes in 4 lanes, Eron 11, Vael 10). The selected mage's row grows to show the full wand at normal rune size (38 px); the other mages collapse to a thin row with a read-only thumbnail (coloured dots, filled = charged). Click a row or press Tab to switch |
| `01g_battle_big_wands_compact.png` | Battle with large wands: compact | Same wands, all three always visible in the normal row height, with smaller runes (28 px, 74×38 px grid). Up to 6 columns × 4 lanes fit, so a 14-rune wand still fits; no switching, but the targets are smaller |
| `02_loot.png` | Loot | Three panels: **Spoils** (battle drops + loot wands, picks counter), **Satchel** (backpack, 24 pockets), **Wielded Wands**. A dotted line shows a rune being dragged. Seal = Go Forth |
| `03_level_up.png` | Level Up | One card per mage with **Vitality** (Max HP +10) and **Attunement** (Mana/turn +1); the hovered option glows. Clicking an option continues. No rest/heal button, since the party heals between battles anyway |
| `04_path_selection.png` | Path Selection | Biome cards with a coloured sigil, tagline, **Approach N of 10** pips and a boss omen from approach 5 on (see below); roads lead from "you are here". Clicking a card continues, there is no confirm button |
| `05_codex.png` | Codex overlay | Open book with bookmark tabs (Runes / Bestiary / Lands); the left page lists runes, undiscovered ones show "?", the right page shows details and known alchemy reactions |
| `06_game_over.png` | Game Over | "The Embers Fade", a cold brazier, greyed mage medallions, run stats. Seal = Begin Anew |
| `07_victory.png` | Victory | Shown after The Source's guardian falls: "The Great Work Is Done", a lit brazier, surviving mages glowing and fallen ones greyed, run stats. Seal = Begin Anew |

Wording in this theme: spells are called *runes*, the backpack is the *satchel*, and HP is *vitality*. That is flavour only, so the code can keep its current names.

## Shared conventions

Every draft follows these rules; keep them when adding screens.

- **Counters** use plain numbers: top-left reads `Battle 4 · Turn 3` in battle, `Battle 4 won` on loot and level-up, `Next: battle 5` on path selection.
- **HP** is always shown as `22/30`. "Vitality" is only the name of the Max HP upgrade, as "Attunement" is for mana per turn.
- **Mana** adds up: a mage's filled pips = the charged pips in their wand, and the pool in the chalice = 10 minus everything spent. Modifiers (Amp) and tip runes cost no mana, as in the game, so they have no pips.
- **Intents** match the damage shown on the mage they target (`⚔ −N` on the row and in the mage details).
- **Status icons** are the same on mages and monsters: ☠ poison, ✹ burning, ❄ frozen, ≈ wet, ⛨ armor/ward, ◌ blinded. Monster badges show icon + stacks (`☠2`) instead of letters, which used to clash (F for both fire and frozen).
- **Burning** is the status name everywhere (mage rows, details, ground); the banshee's trait is "Burning touch".
- **Wax seal** = the one main action. Bottom right on screens with a bottom bar; centred under the stats on the end screens (game over, victory) and on the battle-won plaque. Screens where clicking a card continues (level up, path selection) have none.

## One look for a spell

A spell is drawn the same everywhere (wand, spoils, satchel, codex, details): a round socket with a ring in the spell's colour, its **glowing rune** inside, and its **mana cost as pips below the socket**. In a wand, filled pips are charged mana; everywhere else all pips are empty. The name, where shown, sits under the pips. The wand tip gets a warm glow and a gold inner ring.

The runes come from `spell-runes/` (`runes.py`, letters as on `spell-runes/03_all_spells.png`): one rune letter per spell, or two fused letters when the first letter is shared (Ember `E`, Fire `F-R`, Frost `F-S`, Amplify `A`, Splash `S-P`, Single `S-N`, Line `L-N`, …). The eight bolts share the `B-T` rune and add a small direction arrow. Alchemy results show their recipe as a three-part rune (reactants on top, catalyst at the bottom).

The drafts use the real spells from `SpellRegistry` with their colour and mana cost; modifiers cost 0. Alchemy results (Steam, Ice Cube, …) only appear in the codex, never as loot. The codex example shows the Fire catalyst with its real recipes (Fire + Fire + Frost → Steam, Fire + Frost + Venom → fizzle).

## Boss omens

From approach 5 on, a biome card shows an omen that grows more ominous (and redder) until the guardian fight at approach 10:

| Approach | Omen |
|---|---|
| 5 | The air grows still. |
| 6 | Tracks too large for any beast. |
| 7 | Something watches from afar. |
| 8 | The ground trembles at night. |
| 9 | Its breath can be heard. |
| 10 | ☠ The guardian stirs |

These are generic for now; each biome could later get its own set (e.g. Swamp: "The reeds stop whispering.").

Regenerate:
```
python3 gen_drafts.py svg && for f in svg/*.svg; do rsvg-convert -z 1.5 "$f" -o "$(basename "${f%.svg}").png"; done
magick montage 01[a-g]*.png 0[2-7]_*.png -tile 5x3 -geometry 1016x572+4+4 -background '#0b0705' miff:- | magick - -gravity center -background '#0b0705' -extent 5120x2160 00_overview.png
```

## Monsters (`monsters/`)

Comic-style monster drafts that fit the Ember Grimoire look: thick dark-brown ink outlines, two-tone cel shading with light from the top left, a 3/4 view facing left (towards the mages), a ground shadow, and ember-orange eyes as the shared detail. Each monster keeps its in-game colour (`EnemyData` color) as its main tone. Glow and other effects are left out for now.

| File | Monster |
|---|---|
| `monsters/skeleton.png` / `.svg` | Skeleton: bone white, rusty iron sword, wooden shield with gold boss, leather loincloth |
| `monsters/banshee.png` / `.svg` | Banshee: pale blue spirit, wailing mouth, hair streaming back, claw reaching forward |
| `monsters/00_monsters_overview.png` | Both on bestiary cards, plus a preview at battle-tile size |

Regenerate: `cd monsters && python3 gen_monsters.py && for n in skeleton banshee; do rsvg-convert $n.svg -o $n.png; done`
