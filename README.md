# Wand Magic

A 2D turn-based roguelite where mages wield wands loaded with spell graphs to fight through a series of battles.

## Gameplay Loop

```
Battle → Loot → Level up Phase -> Path Selection → Battle → ...
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
After loot, the player picks the next battle from a random subset of currently unlocked biomes. The player is always shown **2 choices**; as more biomes unlock this may grow to **3**. The phase ends explicitly when the player confirms their selection.

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
Spells in a wand influence each other when fired together:
- *Synergy*: e.g. a poison spell + a poison amplifier spell multiply their effect
- *Cancellation*: e.g. a fire spell + a water spell in the same wand cancel each other out

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

**HP:** Each mage has their own HP value. HP can increase via leveling up (details TBD). *(Level up phase to be designed separately.)*

### Enemies
Placed on a 3x5 grid. Stationary during battle. Cleared when HP reaches zero.

**Turn order:**
1. Each enemy rolls one of their actions and telegraphs it (target mage visible to player)
2. Mages take their turn
3. Enemy actions resolve — unless the enemy is disabled (stunned, blinded, dead, etc.)

**Actions:** Each monster has a short list (1–3) of possible actions (attack, shield, spellcast, etc.). One is selected randomly each turn.

**Size:** Monsters can occupy multiple grid fields. Example: a shield ogre is 2 fields wide and blocks attacks for enemies behind it.

**Obstacles:** Static at battle start but can be destroyed or moved by spells.

**Scaling & Composition:**
- Starter monsters are fully predefined
- Later monsters have randomized stats, effects, and/or actions — monsters are composed from parts rather than hardcoded, to support this variety
- Difficulty increases with each successive battle

### Mana Pool
All three mages share a single mana pool that persists between battles.

- Replenishes gradually each round (base rate TBD)
- Each mage's focus element adds mana every round
- Receives a large refill (e.g. 50%) after each battle
- **Mana cap** is determined by mage items

**On each turn:** the player freely allocates mana across any number of wands. If at least one slot on a wand is fully charged, that wand can be zapped. Multiple wands can be zapped in the same turn.

## Planned Features

### Battle
- [ ] Turn-based combat loop (mages and enemies alternate)
- [ ] Enemy placement on 3x5 grid
- [ ] Enemy behaviors and actions
- [ ] Mage actions driven by equipped wand
- [ ] Mana and item resource management
- [ ] Win/lose condition detection

### Wand System
- [ ] Spell slot graph structure (directed graph, handful of nodes)
- [ ] Path traversal during casting
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
- [ ] Shared monsters across biomes
- [ ] Per-biome difficulty scaling
- [ ] Boss fight trigger after ~10 battles per biome
- [ ] Biome unlock chain on boss defeat
- [ ] Cross-biome spell counters

## Implemented Features

_(none yet)_
