extends Node

# Persistent game state passed between scenes.

var mages: Array[MageData] = []
var wands: Array[WandData] = []        # parallel to mages; null = no wand equipped
var backpack: Array[SpellData] = []
var backpack_wands: Array[WandData] = []
var pending_loot: Array[SpellData] = []
var battle_drops: Array[SpellData] = []  # monster drops of the last battle; limited by LootRoller.MAX_PICKS
var pending_loot_wands: Array[WandData] = []
var current_biome: BiomeData = null
var is_initial_setup: bool = true
var battle_count: int = 0
var battle_count_by_biome: Dictionary = {}  # biome name -> int


func _ready() -> void:
	if mages.is_empty():
		_init_new_game()


func reset_to_new_game() -> void:
	mages.clear()
	wands.clear()
	backpack.clear()
	backpack_wands.clear()
	pending_loot.clear()
	battle_drops.clear()
	pending_loot_wands.clear()
	current_biome = null
	is_initial_setup = true
	battle_count = 0
	battle_count_by_biome.clear()
	_init_new_game()


func reroll_spell_loot() -> void:
	RunProgress.reroll_spell_loot(self, _random_rng())


func _init_new_game() -> void:
	RunProgress.start_new_game(self, _random_rng())


func _random_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng
