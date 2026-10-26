class_name MonsterTraitRevengeRevive extends MonsterTraitData


func _init() -> void:
	super("Revenge Revive", 3)


func apply_on_monster_dies(state: BattleState, setup: BattleSetup, trait_owner_id: String, _dead_enemy_id: String) -> void:
	if state.dead_enemies.is_empty():
		return

	# Find the strongest dead enemy (highest max_hp), excluding self
	var best_id := ""
	var best_hp := -1
	for dead_id: String in state.dead_enemies:
		if dead_id == trait_owner_id:
			continue
		var dead_enemy := setup.get_enemy(dead_id)
		if dead_enemy == null:
			continue
		if dead_enemy.max_hp > best_hp:
			best_hp = dead_enemy.max_hp
			best_id = dead_id

	if best_id.is_empty():
		return

	var target_enemy := setup.get_enemy(best_id)
	var dead_info: Dictionary = state.dead_enemies[best_id]

	# Try last known position first, then a random free cell
	var last_pos := _get_last_pos(best_id, dead_info, setup)
	var revive_pos := Vector2i(-1, -1)

	if last_pos != Vector2i(-1, -1) and _can_place(last_pos, target_enemy.grid_size, state, setup):
		revive_pos = last_pos
	else:
		revive_pos = _find_free_cell(target_enemy.grid_size, state, setup)

	if revive_pos == Vector2i(-1, -1):
		return  # no space — no effect

	state.enemy_hp[best_id] = target_enemy.max_hp
	var saved_statuses: Array = dead_info.get("statuses", [])
	if not saved_statuses.is_empty():
		state.enemy_statuses[best_id] = saved_statuses.duplicate()
	state.enemy_positions[best_id] = revive_pos
	state.dead_enemies.erase(best_id)


func _get_last_pos(dead_id: String, dead_info: Dictionary, setup: BattleSetup) -> Vector2i:
	if dead_info.has("position"):
		return dead_info["position"]
	for i in setup.enemies.size():
		if setup.enemies[i].id == dead_id:
			return setup.enemy_positions[i]
	return Vector2i(-1, -1)


func _build_occupied(state: BattleState, setup: BattleSetup) -> Dictionary:
	var occupied := {}
	for i in setup.enemies.size():
		if not state.enemy_hp.has(setup.enemies[i].id):
			continue
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(
				setup.get_enemy_pos(i, state), setup.enemies[i].grid_size):
			occupied[cell] = true
	return occupied


func _can_place(pos: Vector2i, grid_size: Vector2i, state: BattleState, setup: BattleSetup) -> bool:
	if pos.x < 0 or pos.y < 0:
		return false
	return _fits_at(pos, grid_size, _build_occupied(state, setup))


func _find_free_cell(grid_size: Vector2i, state: BattleState, setup: BattleSetup) -> Vector2i:
	var occupied := _build_occupied(state, setup)
	var total := EnemyGrid.ROWS * EnemyGrid.COLS
	var start := randi() % total
	for i in range(start, total):
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if _fits_at(pos, grid_size, occupied):
			return pos
	for i in range(start - 1, -1, -1):
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if _fits_at(pos, grid_size, occupied):
			return pos
	return Vector2i(-1, -1)


func _fits_at(pos: Vector2i, grid_size: Vector2i, occupied: Dictionary) -> bool:
	if pos.x + grid_size.x > EnemyGrid.COLS or pos.y + grid_size.y > EnemyGrid.ROWS:
		return false
	for cell: Vector2i in EnemyGrid.get_cells_for_enemy(pos, grid_size):
		if occupied.has(cell):
			return false
	return true
