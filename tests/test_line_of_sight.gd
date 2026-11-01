extends GutTest


func _make_setup(
		tip_spell: SpellData,
		enemies: Array[EnemyData],
		enemy_positions: Array[Vector2i],
		obstacles: Array[ObstacleData] = [],
		obstacle_positions: Array[Vector2i] = []
) -> BattleSetup:
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = _strike()
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = tip_spell
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	return BattleSetup.new(enemies, enemy_positions, [mage], [wand], 10, obstacles, obstacle_positions)


func _make_state(setup: BattleSetup) -> BattleState:
	var s := BattleState.new()
	for e: EnemyData in setup.enemies:
		var es := EnemyState.new()
		es.combatant.hp = e.max_hp
		s.enemies[e.id] = es
	for o: ObstacleData in setup.obstacles:
		var os := ObstacleState.new()
		os.combatant.hp = o.max_hp
		s.obstacles[o.id] = os
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 99
	ms.slot_charges["tip"] = 1
	s.mages.append(ms)
	s.mana = 10
	return s


func _strike() -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


func _goblin(id: String, size: Vector2i = Vector2i(1, 1)) -> EnemyData:
	return EnemyData.new(id, "Goblin", 20, size, Color.GREEN)


func _hp(state: BattleState, id: String) -> int:
	return (state.enemies[id] as EnemyState).combatant.hp


# --- has_line_of_sight ---

func test_front_column_always_visible() -> void:
	var setup := _make_setup(SpellSingle.create(), [_goblin("g1")], [Vector2i(0, 0)])
	assert_true(setup.has_line_of_sight(Vector2i(0, 0), _make_state(setup)))


func test_enemy_blocks_enemy_behind_it() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("front"), _goblin("back")], [Vector2i(0, 1), Vector2i(2, 1)])
	assert_false(setup.has_line_of_sight(Vector2i(2, 1), _make_state(setup)))


func test_enemy_in_other_row_does_not_block() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("front"), _goblin("back")], [Vector2i(0, 0), Vector2i(2, 1)])
	assert_true(setup.has_line_of_sight(Vector2i(2, 1), _make_state(setup)))


func test_blocking_obstacle_blocks() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("g1")], [Vector2i(2, 0)], [Stone.new()], [Vector2i(1, 0)])
	assert_false(setup.has_line_of_sight(Vector2i(2, 0), _make_state(setup)))


func test_non_blocking_obstacle_does_not_block() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("g1")], [Vector2i(2, 0)], [Pyre.new()], [Vector2i(1, 0)])
	assert_true(setup.has_line_of_sight(Vector2i(2, 0), _make_state(setup)))


func test_destroyed_obstacle_does_not_block() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("g1")], [Vector2i(2, 0)], [Stone.new()], [Vector2i(1, 0)])
	var state := _make_state(setup)
	state.obstacles.erase("stone")
	assert_true(setup.has_line_of_sight(Vector2i(2, 0), state))


func test_empty_cell_behind_blocker_is_blocked() -> void:
	var setup := _make_setup(SpellSingle.create(), [_goblin("g1")], [Vector2i(0, 0)])
	assert_false(setup.has_line_of_sight(Vector2i(3, 0), _make_state(setup)))


func test_wide_enemy_does_not_block_its_own_back_cell() -> void:
	var setup := _make_setup(SpellSingle.create(), [_goblin("ogre", Vector2i(2, 1))], [Vector2i(0, 0)])
	assert_true(setup.has_line_of_sight(Vector2i(1, 0), _make_state(setup)))


func test_tall_enemy_partially_covered_is_hittable_in_open_row() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("ogre", Vector2i(1, 2))], [Vector2i(2, 0)], [Stone.new()], [Vector2i(1, 0)])
	var state := _make_state(setup)
	assert_false(setup.has_line_of_sight(Vector2i(2, 0), state))
	assert_true(setup.has_line_of_sight(Vector2i(2, 1), state))


# --- zap ---

func test_zap_at_blocked_cell_does_nothing() -> void:
	var setup := _make_setup(SpellSingle.create(),
			[_goblin("g1")], [Vector2i(2, 0)], [Stone.new()], [Vector2i(1, 0)])
	var result := ActionZapWand.new(0, Vector2i(2, 0)).apply(_make_state(setup), setup)
	assert_eq(_hp(result.state, "g1"), 20)
	assert_true(result.cast_events.is_empty())
	assert_true((result.state.mages[0] as MageState).slot_charges.has("tip"))


func test_pattern_hits_neighbour_around_the_corner() -> void:
	var setup := _make_setup(SpellBoltS.create(),
			[_goblin("open"), _goblin("hidden")], [Vector2i(1, 0), Vector2i(1, 1)],
			[Stone.new()], [Vector2i(0, 1)])
	var result := ActionZapWand.new(0, Vector2i(1, 0)).apply(_make_state(setup), setup)
	assert_eq(_hp(result.state, "open"), 15)
	assert_eq(_hp(result.state, "hidden"), 15)
