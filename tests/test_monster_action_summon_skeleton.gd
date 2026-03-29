extends GutTest


func _make_setup(drummer_pos: Vector2i = Vector2i(2, 3)) -> BattleSetup:
	var enemies: Array[EnemyData] = [WarDrummer.new()]
	var positions: Array[Vector2i] = [drummer_pos]
	return BattleSetup.new(enemies, positions, [], [], 10)


func _make_state(drummer_hp: int) -> BattleState:
	var s := BattleState.new()
	s.enemy_hp["war_drummer_1"] = drummer_hp
	return s


func test_spawns_one_skeleton_at_full_hp() -> void:
	var setup := _make_setup()
	var state := _make_state(65)
	var action := MonsterActionSummonSkeleton.new()
	var result := action.execute(state, setup, "war_drummer_1", -1)
	assert_eq(setup.enemies.size(), 2)
	assert_true(result.enemy_hp.has(setup.enemies[1].id))


func test_spawns_three_skeletons_below_25_percent() -> void:
	var setup := _make_setup()
	var state := _make_state(10)  # 10/65 = 15%, below 25%
	var action := MonsterActionSummonSkeleton.new()
	action.execute(state, setup, "war_drummer_1", -1)
	assert_eq(setup.enemies.size(), 4)  # drummer + 3 skeletons


func test_spawns_one_skeleton_above_25_percent() -> void:
	var setup := _make_setup()
	var state := _make_state(50)  # 50/65 = 77%, above 25%
	var action := MonsterActionSummonSkeleton.new()
	action.execute(state, setup, "war_drummer_1", -1)
	assert_eq(setup.enemies.size(), 2)


func test_skeleton_spawns_with_full_hp() -> void:
	var setup := _make_setup()
	var state := _make_state(65)
	var action := MonsterActionSummonSkeleton.new()
	var result := action.execute(state, setup, "war_drummer_1", -1)
	var skeleton_id := setup.enemies[1].id
	assert_eq(result.enemy_hp[skeleton_id], Skeleton.new().max_hp)


func test_skeletons_placed_on_distinct_cells() -> void:
	var setup := _make_setup()
	var state := _make_state(10)
	var action := MonsterActionSummonSkeleton.new()
	action.execute(state, setup, "war_drummer_1", -1)
	var positions: Array[Vector2i] = []
	for i in range(1, setup.enemy_positions.size()):
		var pos := setup.enemy_positions[i]
		assert_false(positions.has(pos), "Two skeletons share position %s" % pos)
		positions.append(pos)


func test_no_spawn_when_grid_full() -> void:
	var enemies: Array[EnemyData] = [WarDrummer.new()]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	var state := _make_state(65)
	for row in EnemyGrid.ROWS:
		for col in EnemyGrid.COLS:
			if col == 0 and row == 0:
				continue
			var id := "filler_%d_%d" % [col, row]
			enemies.append(EnemyData.new(id, "Filler", 10, Vector2i(1, 1), Color.WHITE))
			positions.append(Vector2i(col, row))
			state.enemy_hp[id] = 10
	var setup := BattleSetup.new(enemies, positions, [], [], 10)
	var initial_count := setup.enemies.size()
	var action := MonsterActionSummonSkeleton.new()
	action.execute(state, setup, "war_drummer_1", -1)
	assert_eq(setup.enemies.size(), initial_count)


func test_skeleton_not_respawned_on_second_call() -> void:
	var setup := _make_setup()
	var state := _make_state(65)
	var action := MonsterActionSummonSkeleton.new()
	var result1 := action.execute(state, setup, "war_drummer_1", -1)
	var pos_after_first := setup.enemy_positions[1]
	var result2 := action.execute(result1, setup, "war_drummer_1", -1)
	assert_eq(setup.enemies.size(), 2, "no new skeleton spawned on second call")
	assert_eq(setup.enemy_positions[1], pos_after_first, "skeleton position unchanged")


func test_does_nothing_if_drummer_not_in_setup() -> void:
	var setup := _make_setup()
	var state := _make_state(65)
	var action := MonsterActionSummonSkeleton.new()
	var result := action.execute(state, setup, "nonexistent_id", -1)
	assert_eq(setup.enemies.size(), 1)
	assert_eq(result.enemy_hp.size(), state.enemy_hp.size())
