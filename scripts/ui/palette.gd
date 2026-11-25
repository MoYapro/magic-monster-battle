class_name Palette
extends RefCounted

# Ember Grimoire theme, matching layout-drafts/ (EMBER in gen_drafts.py).

# --- Ember chrome ---
const COLOR_FRAME          := Color("#0b0705")
const COLOR_PANEL_RAISED   := Color("#352318")
const COLOR_INNER_BORDER   := Color("#4a3220")
const COLOR_ACCENT         := Color("#f0a030")
const COLOR_SEAL           := Color("#9a2a1a")
const COLOR_SEAL_LIGHT     := Color("#e2643a")
const COLOR_SEAL_TEXT      := Color("#ffe8d0")

# --- Screen chrome ---
const COLOR_BG             := Color("#1b120d")
const COLOR_HEADER_BG      := Color("#24170e")
const COLOR_BORDER         := Color("#6b4a2a")
const COLOR_PANEL          := Color("#2a1c14")
const COLOR_SECTION        := Color("#a07a48")

# --- Text ---
const COLOR_TEXT_BRIGHT    := Color("#f3e3c4")
const COLOR_TEXT_DIM       := Color("#b39470")
const COLOR_TEXT_STAT      := Color("#e8d3a8")

# --- HP / health ---
const COLOR_HP_FULL        := Color("#d9a032")
const COLOR_HP_LOW         := Color("#e2442a")
const COLOR_HP_BG          := Color("#140c08")
const COLOR_HP_LOSS        := Color("#e2442ae0")
const COLOR_HP_LABEL       := Color("#e8d3a8")

# --- Targeting ---
const COLOR_TARGET_AVAILABLE := Color("#ffd34a")
const COLOR_TARGET_HOVER     := Color("#e2643a")
const COLOR_TARGET_BLOCKED   := Color("#6b5a48")
const COLOR_TARGET_FLASH     := Color("#ff8a2ae6")

# --- Widget panels (MageDisplay / ManaDisplay) ---
const COLOR_WIDGET_BG      := Color("#2a1c14")
const COLOR_WIDGET_BORDER  := Color("#6b4a2a")
const COLOR_WIDGET_DEAD    := Color("#3a0e08")

# --- Mana ---
const COLOR_MANA           := Color("#ff8a2a")
const COLOR_MANA_DROPLET   := Color("#e2642a")
const COLOR_MANA_EMPTY     := Color("#3a2414")
const COLOR_MANA_BORDER    := Color("#ffb84a")
const COLOR_MANA_LABEL     := Color("#b39470")

# --- Shield bar ---
const COLOR_SHIELD_FILL    := Color("#e8d9a8b3")
const COLOR_SHIELD_EDGE    := Color("#fff3dc")

# --- Wand display ---
const COLOR_WAND_BG          := Color("#24170e")
const COLOR_WAND_BG_BORDER   := Color("#6b4a2a")
const COLOR_WAND_SLOT_BODY   := Color("#3b281a")
const COLOR_WAND_SLOT_TIP    := Color("#4a2a12")
const COLOR_WAND_BORDER_BODY := Color("#8b6a40")
const COLOR_WAND_BORDER_TIP  := Color("#ffb84a")
const COLOR_WAND_EDGE        := Color("#a07a48")
const COLOR_PIP_FILLED       := Color("#ff8a2a")
const COLOR_PIP_EMPTY        := Color("#3a2414")
const COLOR_ACTIVE_BORDER    := Color("#f0a030")

# --- Bomb icon drawing ---
const COLOR_BOMB_BODY        := Color("#241a14")
const COLOR_BOMB_RIM         := Color("#c9b89a")
const COLOR_BOMB_SHINE       := Color(1.0, 1.0, 1.0, 0.28)
const COLOR_BOMB_FUSE        := Color(0.68, 0.56, 0.30)
const COLOR_BOMB_SPARK       := Color(1.0, 0.82, 0.18)
const COLOR_BOMB_SPARK_HOT   := Color(1.0, 1.0, 0.80)
const COLOR_BOMB_SLOT_FILL   := Color(0.35, 0.22, 0.05, 0.50)
const COLOR_BOMB_SLOT_BORDER := Color(0.62, 0.44, 0.14, 0.88)

# --- Enemy grid ---
const COLOR_GRID_CELL        := Color("#2a1d14")
const COLOR_GRID_BORDER      := Color("#4a3420")
const COLOR_GRID_HP          := Color("#fff3dc")
const COLOR_GRID_INTENT      := Color("#ffcf6a")
const COLOR_GRID_SHIELD_TEXT := Color("#f0a030")
const COLOR_GRID_FROZEN      := Color("#9fd4f0")
const COLOR_GRID_BLOCK       := Color("#e8d9a8")

# --- Status effects ---
const COLOR_STATUS_POISON := Color(0.50, 0.20, 0.65)
const COLOR_STATUS_FIRE   := Color(0.95, 0.42, 0.05)
const COLOR_STATUS_WET    := Color(0.25, 0.55, 0.90)
const COLOR_STATUS_PUDDLE := Color(0.20, 0.45, 0.75, 0.35)

# --- Floating damage ---
const COLOR_DAMAGE_HIT      := Color("#fff3dc")
const COLOR_DAMAGE_FIZZLE   := Color("#8a7a68")
const COLOR_DAMAGE_BACKFIRE := Color("#e2442a")
const COLOR_TEXT_SHADOW     := Color(0.0, 0.0, 0.0, 0.85)

# --- Tooltips ---
const COLOR_TOOLTIP_BG      := Color("#1b120df7")
const COLOR_TOOLTIP_BORDER  := Color("#8b6a40")
const COLOR_TOOLTIP_NAME    := Color("#f3e3c4")
const COLOR_TOOLTIP_BODY    := Color("#b39470")
const COLOR_TOOLTIP_STATS   := Color("#e8d3a8")
const COLOR_TOOLTIP_SECTION := Color("#a07a48")

# --- Debug bar ---
const COLOR_DEBUG_BG    := Color("#140c08")
const COLOR_DEBUG_SEP   := Color("#4a3220")
const COLOR_DEBUG_LABEL := Color("#b39470")

# --- Level-up screen ---
const COLOR_GAIN           := Color("#9fc86a")
const COLOR_OPTION_BG      := Color("#2a1c14")
const COLOR_SELECTED_BG    := Color("#3a2618")
const COLOR_SELECTED_BORDER := Color("#f0a030")

# --- Loot screen ---
const COLOR_SLOT_EMPTY       := Color("#24170e")
const COLOR_SLOT_BORDER      := Color("#4a3220")
const COLOR_DROP_HIGHLIGHT   := Color("#f0a0301f")
const COLOR_DROP_BORDER      := Color("#f0a030cc")
const COLOR_WAND_CARD        := Color("#352318")
const COLOR_WAND_CARD_BORDER := Color("#a07a48")

# --- Game over screen ---
const COLOR_GAME_OVER_BG    := Color("#140a07")
const COLOR_GAME_OVER_TITLE := Color("#e2442a")
const COLOR_GAME_OVER_SUB   := Color("#b39470")
