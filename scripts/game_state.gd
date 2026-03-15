extends Node

# Persistent game state passed between scenes.

var mages: Array[MageData] = []
var wands: Array[WandData] = []
var backpack: Array[SpellData] = []
var backpack_wands: Array[WandData] = []
var pending_loot: Array[SpellData] = []
var pending_loot_wand: WandData = null
var current_biome: BiomeData = null
