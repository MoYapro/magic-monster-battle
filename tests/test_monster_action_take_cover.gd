extends GutTest


func _make_setup_with_obstacle(
	enemy_pos: Vector2i, obs_pos: Vector2i, obs_size: Vector2i = Vector2i(1, 1)
) -> BattleSetup:
	var enemies: Array[EnemyData] = [Goblin.new()]
	enemies[0].id = "goblin_a"
	var obstacle := ObstacleData.new("rock_1", "Rock", obs_size, Color.GRAY, 30)
	return BattleSetup.new(enemies, [enemy_pos], [], [], 10, [obstacle], [obs_pos])


func _make_setup_with_ally(enemy_pos: Vector2i, ally_pos: Vector2i) -> BattleSetup:
	var enemies: Array[EnemyData] = [Goblin.new(), Goblin.new()]
	enemies[0].id = "goblin_a"
	enemies[1].id = "goblin_b"
	return BattleSetup.new(enemies, [enemy_pos, ally_pos], [], [], 10)


func _make_state(extra_ids: Array = []) -> BattleState:
	var s := BattleState.new()
	s.enemy_hp["goblin_a"] = 30
	for id in extra_ids:
		s.enemy_hp[id] = 30
	return s


func test_moves_behind_obstacle() -> void:
	# obstacle at (2,2) size 1x1, behind = (3,2)
	var setup := _make_setup_with_obstacle(Vector2i(0, 0), Vector2i(2, 2))
	var state := _make_state()
	state.obstacle_hp["rock_1"] = 30
	MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.enemy_positions[0], Vector2i(3, 2))


func test_moves_behind_ally() -> void:
	# ally at (1,1) size 1x1, behind = (2,1)
	var setup := _make_setup_with_ally(Vector2i(0, 0), Vector2i(1, 1))
	var state := _make_state(["goblin_b"])
	MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.enemy_positions[0], Vector2i(2, 1))


func test_picks_closest_cover() -> void:
	# rock_1 at (1,0) is closer to goblin at (0,0), behind = (2,0)
	# rock_2 at (3,0) is farther, behind = (4,0)
	var enemies: Array[EnemyData] = [Goblin.new()]
	enemies[0].id = "goblin_a"
	var obs1 := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 30)
	var obs2 := ObstacleData.new("rock_2", "Rock", Vector2i(1, 1), Color.GRAY, 30)
	var setup := BattleSetup.new(
		enemies, [Vector2i(0, 0)], [], [], 10,
		[obs1, obs2], [Vector2i(1, 0), Vector2i(3, 0)]
	)
	var state := _make_state()
	state.obstacle_hp["rock_1"] = 30
	state.obstacle_hp["rock_2"] = 30
	MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.enemy_positions[0], Vector2i(2, 0))


func test_does_not_move_when_behind_is_out_of_bounds() -> void:
	# obstacle flush against the right edge — no column behind it
	var setup := _make_setup_with_obstacle(Vector2i(0, 0), Vector2i(EnemyGrid.COLS - 1, 0))
	var state := _make_state()
	state.obstacle_hp["rock_1"] = 30
	MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.enemy_positions[0], Vector2i(0, 0))


func test_does_not_move_when_behind_is_occupied() -> void:
	# obstacle at (1,0), behind (2,0) is blocked by ally
	var enemies: Array[EnemyData] = [Goblin.new(), Goblin.new()]
	enemies[0].id = "goblin_a"
	enemies[1].id = "goblin_b"
	var obstacle := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 30)
	var setup := BattleSetup.new(
		enemies, [Vector2i(0, 0), Vector2i(2, 0)], [], [], 10,
		[obstacle], [Vector2i(1, 0)]
	)
	var state := _make_state(["goblin_b"])
	state.obstacle_hp["rock_1"] = 30
	MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.enemy_positions[0], Vector2i(0, 0))


func test_does_not_move_behind_dead_obstacle() -> void:
	var setup := _make_setup_with_obstacle(Vector2i(0, 0), Vector2i(2, 2))
	var state := _make_state()
	# obstacle not in obstacle_hp (destroyed)
	MonsterActionTakeCover.new().execute(state, setup, "goblin_a", -1)
	assert_eq(setup.enemy_positions[0], Vector2i(0, 0))
