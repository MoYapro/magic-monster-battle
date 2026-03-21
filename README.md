# Wand Magic

A 2D turn-based roguelite where mages wield wands loaded with spell graphs to fight through a series of battles.

## Gameplay Loop

```
Battle → Loot → Level Up → Path Selection → Battle → ...
```

- **Battle** — clear all monsters to continue; all mages die = run over
- **Loot** — pick up spells or wands dropped after the battle
- **Path Selection** — choose the next battle location (e.g. desert, water, forest)

**Run structure:** No win condition — the goal is to survive as many battles as possible. When all mages are dead the run ends and a new one can begin.

## Game Screens

### Battle View
```
+---------------------------+
|      Enemy Board (3x5)    |  ← enemies placed here
+---------------------------+
|     Mage Row              |  ← player's mages with their wands
+---------------------------+
|     Items & Mana          |  ← resources to spend each turn
+---------------------------+
```
Mages and monsters alternate taking actions. Goal: clear the board.

### Loot Screen
After each battle the player sees three areas:
- **New loot** — items dropped from the battle
- **Backpack** — currently stored wands and spells (limited space)
- **Mage wands** — the three equipped wands with their spell slots

The player freely moves loot between all three areas. Anything left in the loot area when the phase ends is lost. The phase ends explicitly when the player confirms they are done.

### Path Selection
After loot, the player picks the next battle from a random subset of currently unlocked biomes. The player is always shown **2 choices**; as more biomes unlock this may grow to **3**. 
The phase ends explicitly when the player confirms their selection.

**Biomes:**
- There are at least **3 starter biomes** available from the beginning
- Each biome has its own monster roster; some monsters may be shared across biomes
- Monsters drop monster specific loot with per-monster drop chances
- Difficulty within each biome scales independently — the player can revisit easier biomes but they will outscale other biomes if they are battled more often
- Cross-biome synergy: spells looted in one biome can counter enemies in another (e.g. water spells block poison used by graveyard enemies)
- After ~10 battles in a biome a **boss fight** triggers
- The boss should combine some of the mechanics / actions / traits seen earlier in this biome 
- Defeating a boss unlocks a new biome in path selection
- Path selection always shows a random subset of unlocked biomes

**Biome progression example:**
```
Forest (starter) → beat boss → unlocks Graveyard
Graveyard → beat boss → unlocks Hell
Coast (starter) → beat boss → unlocks Water
Water -> beat boss -> unlocks Sub-marine
```

## Core Systems

### Wand & Spell Graph
A wand holds between 2 (starter) and ~10 (end game) spell slots arranged as a **directed graph**. All edges point toward the tip — the tip is the graph's single endpoint (sink). On their turn, the player picks mana from the mana pool and places it onto spell slots. Each slot has a mana cost — when a slot has enough mana it is "charged". Once one or more slots are charged, the wand can be zapped at a target enemy.

**Wand Tip**
The tip is the sink of the graph and holds a tip spell that defines the hit pattern on the board. Examples:
- Single field
- Two horizontal
- Three vertical
- Area patterns

**Body Slots**
All other slots hold effect spells. Their position in the graph determines how they combine when fired together:
- *Sequential (in-line)* — spells on the same path to the tip interact **multiplicatively**
- *Parallel (branching)* — spells on separate branches merging toward the tip interact **additively**

This makes the graph layout and mana placement the core strategic decisions.

**Spell Interactions**
Spells carry element tags (e.g. `fire`, `water`, `poison`, `amplify`). Interaction rules operate on tags, not specific spells — a new spell automatically participates in any interaction matching its tags. Examples:
- *Synergy*: `poison` + `amplify` → multiply effect
- *Cancellation*: `fire` + `water` → cancel each other out

**Line of Sight**
A target cannot be hit if a monster or obstacle (tree, stone, wall, etc.) occupies a cell in front of it.

### Mages
The player controls three mages. Mages are lost permanently if killed in battle.

Each mage:
- Has one wand equipped for the current battle
- Has a **focus element** (a lootable, swappable item) that generates mana every round
- May carry additional wands and spells in a **backpack** (not usable mid-battle, rearranged in loot phase)

**Mage actions:** Zapping a wand is the primary action. Spell effects determine outcomes — damage, shields on one or multiple mages, stuns, blinds, kills, and other status effects that can negate incoming enemy actions.

- A mage can zap multiple times per turn if mana allows
- All three mages can act in a single player turn
- The player chooses where on the board to center the tip's hit pattern

**HP:** Each mage has their own HP value.

**Level Up Phase:** After each battle, the player upgrades one base stat of one mage. Upgradeable stats:
- Max health
- Max mana spend per round

### Enemies
Placed on a 3x5 grid. Stationary during battle. Cleared when HP reaches zero.

**Turn order (always telegraph → act → resolve, no interleaving):**
1. Each enemy rolls one of their actions and telegraphs it (target mage visible to player)
2. All mages take their turn (player acts freely across all three mages)
3. All enemy actions resolve simultaneously — unless the enemy is disabled (stunned, blinded, dead, etc.)

**Actions:** Each monster has a short list (1–3) of possible actions (attack, shield, spellcast, etc.). One is selected randomly each turn.

**Status effects:**
- *Stunned* — enemy action does not resolve this turn
- *Blinded* — enemy either misses entirely (50%) or hits a random mage instead of the telegraphed target (50%)

**Size:** Monsters can occupy multiple grid fields. Example: a shield ogre is 2 fields wide and blocks attacks for enemies behind it.

**Obstacles:** Static at battle start but can be destroyed or moved by spells.

**Scaling & Composition:**
- Starter monsters are fully predefined
- Later monsters have randomized stats, effects, and/or actions — monsters are composed from parts rather than hardcoded, to support this variety
- Difficulty increases with each successive battle

### Mana Pool
All three mages share a single mana pool that persists between battles.

- **Starting mana:** 10
- **Replenishment:** 2 mana per mage per turn (6/turn with a full party of 3)
- Each mage's focus element adds additional mana every round
- **Post-battle refill:** 50% of max mana (e.g. +5 if max is 10)
- **Mana cap** is determined by mage items (TBD — treat as a future variable in design choices until then)
- Each mage has a **max mana spend per round** stat that limits how much of the pool they can draw in a single turn; this stat is upgradeable

**On each turn:** the player freely allocates mana across any number of wands, up to each mage's spend cap. If at least one slot on a wand is fully charged, that wand can be zapped. Multiple wands can be zapped in the same turn.

## Planned Features

### Battle
- [ ] Turn-based combat loop (mages and enemies alternate)
- [ ] Enemy behaviors and actions
- [ ] Win/lose condition detection
- [ ] Mana placement on wand slots (mana cost per slot, charge system)

### Wand System
- [ ] Path traversal during casting (sequential × parallel spell interactions)
- [ ] Spell tag interactions (fire+water cancel, poison+amplify multiply, etc.)
- [ ] Wand editor / rearrangement UI

### Loot & Progression
- [ ] Loot screen with new loot / backpack / wand areas
- [ ] Free drag-and-drop of loot between areas
- [ ] Backpack space limit
- [ ] Persistent mage/wand/backpack state between battles
- [ ] Focus element slot per mage

### Path Selection
- [ ] Path selection screen showing random subset of unlocked biomes
- [ ] Biome definitions with own monster rosters and loot tables
- [ ] Per-biome difficulty scaling
- [ ] Boss fight trigger after ~10 battles per biome
- [ ] Biome unlock chain on boss defeat

## Implemented Features

### Battle
- [x] Enemy grid (3×5) with placement, bounds checking, multi-cell enemy support, removal, and damage
- [x] Enemy display with name and HP bar; enemies removed at 0 HP
- [x] Three mages with HP bars (MageDisplay)
- [x] Mana pool display — individual droplets that overlap when count is high
- [x] Targeting mode: click wand tip → all valid targets highlight yellow
- [x] Hover during targeting: hovered cells/enemies/mages/wands highlight red, hit pattern applied
- [x] Wand firing: deals summed spell damage to all cells in the tip's hit pattern

### Wand System
- [x] Directed spell-graph wand (SpellSlotData with next_id chain toward tip)
- [x] Wand generator: randomised column layout, guaranteed single tip, all slots connected
- [x] Body spells: Ember (fire), Frost (water), Venom (poison), Amplify (amplify), Shield (no dmg)
- [x] Tip spells: Single (1 cell), Line (3 vertical), Pierce (3 horizontal), Bomb (3×3 area)
- [x] Bomb has a hand-drawn icon; other spells show element-tinted abbreviation
- [x] Spell damage: each slot contributes damage summed at fire time
