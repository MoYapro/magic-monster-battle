class_name MonsterActionSummonSkeleton extends MonsterActionData


func _init() -> void:
	name = "Raise Fallen"
	target_type = TargetType.SELF


func execute(state: BattleState, setup: BattleSetup, enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	var drummer := setup.get_enemy(enemy_id)
	if drummer == null:
		return new_state
	var hp_frac := float(new_state.enemy_hp.get(enemy_id, 0)) / float(drummer.max_hp)
	var count: int
	if hp_frac < 0.25:
		count = 3
	elif hp_frac < 0.5:
		count = 2
	else:
		count = 1
	for i in count:
		var skeleton_id := "skeleton_%s_%d" % [enemy_id, i]
		if new_state.enemy_hp.has(skeleton_id):
			continue
		var pos := _find_free_cell(setup, new_state)
		if pos == Vector2i(-1, -1):
			break
		_spawn_skeleton(setup, new_state, pos, skeleton_id)
	return new_state


func _find_free_cell(setup: BattleSetup, state: BattleState) -> Vector2i:
	var occupied := {}
	for i in setup.enemies.size():
		if not state.enemy_hp.has(setup.enemies[i].id):
			continue
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(setup.enemy_positions[i], setup.enemies[i].grid_size):
			occupied[cell] = true
	var total := EnemyGrid.ROWS * EnemyGrid.COLS
	var start := randi() % total
	for i in range(start, total):
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if not occupied.has(pos):
			return pos
	for i in range(start - 1, -1, -1):
		var pos := Vector2i(i % EnemyGrid.COLS, i / EnemyGrid.COLS)
		if not occupied.has(pos):
			return pos
	return Vector2i(-1, -1)


func _spawn_skeleton(setup: BattleSetup, state: BattleState, pos: Vector2i, skeleton_id: String) -> void:
	var skeleton := Skeleton.new()
	skeleton.id = skeleton_id
	setup.spawn_enemy(skeleton, pos)
	state.enemy_hp[skeleton.id] = skeleton.max_hp
