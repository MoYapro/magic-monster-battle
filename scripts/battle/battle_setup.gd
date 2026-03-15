class_name BattleSetup

# Immutable battle configuration — does not change during a battle.

var enemies: Array[EnemyData] = []
var enemy_positions: Array[Vector2i] = []
var mages: Array[MageData] = []
var wands: Array[WandData] = []
var max_mana: int = 10
var mana_per_mage: int = 5

# cell -> enemy_id (precomputed for fast lookup)
var _cell_to_enemy: Dictionary = {}


func _init(
	p_enemies: Array[EnemyData],
	p_positions: Array[Vector2i],
	p_mages: Array[MageData],
	p_wands: Array[WandData],
	p_max_mana: int,
	p_mana_per_mage: int = 5
) -> void:
	enemies = p_enemies
	enemy_positions = p_positions
	mages = p_mages
	wands = p_wands
	max_mana = p_max_mana
	mana_per_mage = p_mana_per_mage
	_build_cell_map()


func make_initial_state() -> BattleState:
	var state := BattleState.new()
	for enemy: EnemyData in enemies:
		state.enemy_hp[enemy.id] = enemy.max_hp
	for mage: MageData in mages:
		state.mage_hp.append(mage.max_hp)
		state.mage_mana_spent.append(0)
	state.mana = max_mana
	return state


func get_enemy_id_at(cell: Vector2i) -> String:
	return _cell_to_enemy.get(cell, "")


func _build_cell_map() -> void:
	for i in enemies.size():
		var cells := EnemyGrid.get_cells_for_enemy(enemy_positions[i], enemies[i].grid_size)
		for cell: Vector2i in cells:
			_cell_to_enemy[cell] = enemies[i].id
