class_name BattleSetup

# Immutable battle configuration — does not change during a battle.

var enemies: Array[EnemyData] = []
var enemy_positions: Array[Vector2i] = []
var obstacles: Array[ObstacleData] = []
var obstacle_positions: Array[Vector2i] = []
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
	p_max_mana: int,
	p_obstacles: Array[ObstacleData] = [],
	p_obstacle_positions: Array[Vector2i] = []
) -> void:
	enemies = p_enemies
	enemy_positions = p_positions
	obstacles = p_obstacles
	obstacle_positions = p_obstacle_positions
	mages = p_mages
	wands = p_wands
	max_mana = p_max_mana
	_build_cell_map()


func make_initial_state() -> BattleState:
	var state := BattleState.new()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_fill_obstacles(state)
	_fill_monsters(state)
	_copy_mages(state)
	state.mana = max_mana
	state.monster_intents = roll_intents(state, rng)
	return state


func _fill_monsters(state: BattleState) -> void:
	for enemy: EnemyData in enemies:
		state.enemy_hp[enemy.id] = enemy.max_hp
		for t: MonsterTraitData in enemy.traits:
			if t is MonsterTraitArmor:
				state.enemy_armor[enemy.id] = (t as MonsterTraitArmor).armor_amount
			elif t is MonsterTraitBlock:
				state.enemy_block[enemy.id] = (t as MonsterTraitBlock).block_charges


func _fill_obstacles(state: BattleState) -> void:
	for obstacle: ObstacleData in obstacles:
		state.obstacle_hp[obstacle.id] = obstacle.max_hp


func _copy_mages(state: BattleState) -> void:
	for mage: MageData in mages:
		state.mage_hp.append(mage.max_hp)
		state.mage_mana_spent.append(0)
		state.mage_poison.append(0)
		state.mage_fire.append(0)
		state.mage_wet.append(0)
		state.mage_frozen.append(false)


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
		var action_index := enemy.pick_action_index(state, self, rng)
		var action: MonsterActionData = enemy.action_pool[action_index]
		var target := -1
		var target_name := ""
		var target_enemy_id := ""
		if action.target_type == MonsterActionData.TargetType.MAGE:
			var living: Array[int] = []
			for i in mages.size():
				if i < state.mage_hp.size() and state.mage_hp[i] > 0:
					living.append(i)
			if living.is_empty():
				continue
			if enemy is Banshee and state.monster_intents.has(enemy.id):
				var locked: int = state.monster_intents[enemy.id].get("locked_target", -1)
				target = locked if locked in living else living[rng.randi() % living.size()]
			else:
				target = living[rng.randi() % living.size()]
			target_name = mages[target].name
		elif action.target_type == MonsterActionData.TargetType.ALL_MAGES:
			target_name = "All"
		elif action.target_type == MonsterActionData.TargetType.MONSTER:
			var lowest_hp := INF
			for e: EnemyData in enemies:
				if state.enemy_hp.has(e.id) and state.enemy_hp[e.id] < lowest_hp:
					lowest_hp = state.enemy_hp[e.id]
					target_enemy_id = e.id
					target_name = e.display_name
		var intent := {
			"action_index": action_index,
			"action_name": action.name,
			"target": target,
			"target_name": target_name,
		}
		if action.target_type == MonsterActionData.TargetType.ALL_MAGES:
			intent["all_mages"] = true
		if not target_enemy_id.is_empty():
			intent["target_enemy_id"] = target_enemy_id
		if enemy is Banshee and target >= 0:
			intent["locked_target"] = target
		if action is MonsterActionAttack and (action as MonsterActionAttack).applies_web \
				and target >= 0 and target < wands.size():
			var candidates: Array[SpellSlotData] = []
			for slot: SpellSlotData in wands[target].slots:
				if slot.spell != null:
					candidates.append(slot)
			if not candidates.is_empty():
				intent["webbed_slot_id"] = candidates[rng.randi_range(0, candidates.size() - 1)].id
		intents[enemy.id] = intent
	return intents


func spawn_enemy(enemy: EnemyData, pos: Vector2i) -> void:
	for existing: EnemyData in enemies:
		if existing.id == enemy.id:
			return
	enemies.append(enemy)
	enemy_positions.append(pos)
	for cell: Vector2i in EnemyGrid.get_cells_for_enemy(pos, enemy.grid_size):
		_cell_to_enemy[cell] = enemy.id


func _build_cell_map() -> void:
	for i in enemies.size():
		var cells := EnemyGrid.get_cells_for_enemy(enemy_positions[i], enemies[i].grid_size)
		for cell: Vector2i in cells:
			_cell_to_enemy[cell] = enemies[i].id
	for i in obstacles.size():
		var cells := EnemyGrid.get_cells_for_enemy(obstacle_positions[i], obstacles[i].grid_size)
		for cell: Vector2i in cells:
			_cell_to_enemy[cell] = obstacles[i].id
