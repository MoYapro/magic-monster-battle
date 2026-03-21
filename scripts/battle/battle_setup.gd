class_name BattleSetup

# Immutable battle configuration — does not change during a battle.

var enemies: Array[EnemyData] = []
var enemy_positions: Array[Vector2i] = []
var mages: Array[MageData] = []
var wands: Array[WandData] = []
var max_mana: int = 10

# cell -> enemy_id (precomputed for fast lookup)
var _cell_to_enemy: Dictionary = {}


func _init(
	p_enemies: Array[EnemyData],
	p_positions: Array[Vector2i],
	p_mages: Array[MageData],
	p_wands: Array[WandData],
	p_max_mana: int
) -> void:
	enemies = p_enemies
	enemy_positions = p_positions
	mages = p_mages
	wands = p_wands
	max_mana = p_max_mana
	_build_cell_map()


func make_initial_state() -> BattleState:
	var state := BattleState.new()
	for enemy: EnemyData in enemies:
		state.enemy_hp[enemy.id] = enemy.max_hp
		for t: MonsterTraitData in enemy.traits:
			if t is MonsterTraitArmor:
				state.enemy_armor[enemy.id] = (t as MonsterTraitArmor).armor_amount
	for mage: MageData in mages:
		state.mage_hp.append(mage.max_hp)
		state.mage_mana_spent.append(0)
	state.mana = max_mana
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	state.monster_intents = roll_intents(state, rng)
	return state


func get_enemy_id_at(cell: Vector2i) -> String:
	return _cell_to_enemy.get(cell, "")


func get_enemy(p_id: String) -> EnemyData:
	for enemy: EnemyData in enemies:
		if enemy.id == p_id:
			return enemy
	return null


func roll_intents(state: BattleState, rng: RandomNumberGenerator) -> Dictionary:
	var intents := {}
	for enemy: EnemyData in enemies:
		if not state.enemy_hp.has(enemy.id) or enemy.action_pool.is_empty():
			continue
		var action_index := rng.randi_range(0, enemy.action_pool.size() - 1)
		var action: MonsterActionData = enemy.action_pool[action_index]
		var target := -1
		var target_name := ""
		if action.target_type == MonsterActionData.TargetType.MAGE:
			target = rng.randi_range(0, mages.size() - 1)
			target_name = mages[target].name
		intents[enemy.id] = {
			"action_index": action_index,
			"action_name": action.name,
			"target": target,
			"target_name": target_name,
		}
	return intents


func _build_cell_map() -> void:
	for i in enemies.size():
		var cells := EnemyGrid.get_cells_for_enemy(enemy_positions[i], enemies[i].grid_size)
		for cell: Vector2i in cells:
			_cell_to_enemy[cell] = enemies[i].id
