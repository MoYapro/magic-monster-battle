extends GutTest

const TARGET := Vector2i(2, 3)


func _slot(id: String, col: int, next_id: String, spell: SpellData) -> SpellSlotData:
	var s := SpellSlotData.new(id, col, 0, next_id)
	s.spell = spell
	return s


func _strike(damage: int = 6) -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", damage, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


func _splash_chain(splashes: int, spell: SpellData) -> Array:
	var slots := []
	for i in splashes:
		slots.append(_slot("sp%d" % i, i, "sp%d" % (i + 1) if i + 1 < splashes else "s", SpellSplash.create()))
	slots.append(_slot("s", splashes, "tip", spell))
	return slots


func _enemy(id: String, hp: int = 50, size := Vector2i(1, 1)) -> EnemyData:
	return EnemyData.new(id, id, hp, size, Color.RED)


func _zap(slots: Array, enemies: Array, positions: Array, tip: SpellData = SpellSingle.create(),
		obstacles: Array = [], obstacle_positions: Array = []) -> BattleState:
	var wand_slots: Array[SpellSlotData] = []
	wand_slots.assign(slots + [_slot("tip", 9, "", tip)])
	var e: Array[EnemyData] = []
	e.assign(enemies)
	var p: Array[Vector2i] = []
	p.assign(positions)
	var o: Array[ObstacleData] = []
	o.assign(obstacles)
	var op: Array[Vector2i] = []
	op.assign(obstacle_positions)
	var setup := BattleSetup.new(e, p, [MageData.new("Mage", 30)] as Array[MageData],
			[WandData.new(wand_slots)] as Array[WandData], 10, o, op)
	return ActionZapWand.new(0, TARGET).apply(_state(setup), setup).state


func _state(setup: BattleSetup) -> BattleState:
	var state := BattleState.new()
	for enemy: EnemyData in setup.enemies:
		state.enemies[enemy.id] = EnemyState.new()
		(state.enemies[enemy.id] as EnemyState).combatant.hp = enemy.max_hp
	for obstacle: ObstacleData in setup.obstacles:
		state.obstacles[obstacle.id] = ObstacleState.new()
		(state.obstacles[obstacle.id] as ObstacleState).combatant.hp = obstacle.max_hp
	var ms := MageState.new()
	ms.combatant.hp = 30
	for slot: SpellSlotData in setup.wands[0].slots:
		ms.slot_charges[slot.id] = 2
	state.mages.append(ms)
	state.mana = 10
	return state


func _hp(state: BattleState, eid: String) -> int:
	return (state.enemies[eid] as EnemyState).combatant.hp


func _ring() -> Array:
	return [[_enemy("t"), _enemy("up"), _enemy("right"), _enemy("down"), _enemy("diag"), _enemy("far")],
			[TARGET, Vector2i(2, 2), Vector2i(3, 3), Vector2i(2, 4), Vector2i(3, 2), Vector2i(4, 3)]]


func test_level_one_hits_orthogonal_neighbours() -> void:
	var r := _ring()
	var result := _zap(_splash_chain(1, _strike()), r[0], r[1])
	assert_eq(_hp(result, "t"), 44)
	for eid: String in ["up", "right", "down"]:
		assert_eq(_hp(result, eid), 47, eid)
	assert_eq(_hp(result, "diag"), 50)
	assert_eq(_hp(result, "far"), 50)


func test_level_two_hits_full_ring() -> void:
	var r := _ring()
	var result := _zap(_splash_chain(2, _strike()), r[0], r[1])
	assert_eq(_hp(result, "diag"), 47)
	assert_eq(_hp(result, "up"), 47)
	assert_eq(_hp(result, "far"), 50)


func test_without_splash_neighbours_untouched() -> void:
	var r := _ring()
	var result := _zap([_slot("s", 0, "tip", _strike())], r[0], r[1])
	assert_eq(_hp(result, "up"), 50)


func test_line_tip_splashes_around_all_cells_without_double_hits() -> void:
	var r := _ring()
	r[0].append(_enemy("top"))
	r[1].append(Vector2i(2, 1))
	var result := _zap(_splash_chain(1, _strike()), r[0], r[1], SpellLine.create())
	assert_eq(_hp(result, "up"), 44, "in the line: full damage only")
	assert_eq(_hp(result, "down"), 44)
	assert_eq(_hp(result, "diag"), 47, "next to the line's top cell")
	assert_eq(_hp(result, "top"), 47)


func test_wide_enemy_in_two_splash_cells_is_hit_once() -> void:
	var result := _zap(_splash_chain(2, _strike()), [_enemy("t"), _enemy("tall", 50, Vector2i(1, 2))],
			[TARGET, Vector2i(3, 2)])
	assert_eq(_hp(result, "tall"), 47)


func test_splash_damage_rounds_down() -> void:
	var r := _ring()
	var result := _zap(_splash_chain(1, _strike(5)), r[0], r[1])
	assert_eq(_hp(result, "right"), 48)


func test_splash_of_one_damage_does_nothing() -> void:
	var r := _ring()
	var result := _zap(_splash_chain(1, _strike(1)), r[0], r[1])
	assert_eq(_hp(result, "right"), 50)


func test_splash_applies_no_on_hit_effects() -> void:
	var r := _ring()
	var ember := SpellEmber.create()
	ember.damage = 6
	var result := _zap(_splash_chain(1, ember), r[0], r[1])
	assert_eq(_hp(result, "right"), 47)
	assert_true((result.enemies["right"] as EnemyState).combatant.statuses.is_empty())
	assert_false((result.enemies["t"] as EnemyState).combatant.statuses.is_empty())


func test_splash_respects_armor_and_block() -> void:
	var setup_enemies := [_enemy("t"), _enemy("right"), _enemy("down")]
	var slots := _splash_chain(1, _strike())
	var wand_slots: Array[SpellSlotData] = []
	wand_slots.assign(slots + [_slot("tip", 9, "", SpellSingle.create())])
	var e: Array[EnemyData] = []
	e.assign(setup_enemies)
	var setup := BattleSetup.new(e, [TARGET, Vector2i(3, 3), Vector2i(2, 4)] as Array[Vector2i],
			[MageData.new("Mage", 30)] as Array[MageData], [WandData.new(wand_slots)] as Array[WandData], 10)
	var state := _state(setup)
	(state.enemies["right"] as EnemyState).armor = 2
	(state.enemies["down"] as EnemyState).block = 1
	var result := ActionZapWand.new(0, TARGET).apply(state, setup).state
	assert_eq(_hp(result, "right"), 49, "3 splash − 2 armor")
	assert_eq(_hp(result, "down"), 50)
	assert_eq((result.enemies["down"] as EnemyState).block, 0)


func test_splash_damages_obstacle() -> void:
	var rock := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 10)
	var result := _zap(_splash_chain(1, _strike()), [_enemy("t")], [TARGET], SpellSingle.create(),
			[rock], [Vector2i(3, 3)])
	assert_eq((result.obstacles["rock_1"] as ObstacleState).combatant.hp, 7)


func test_splash_destroys_weak_obstacle() -> void:
	var rock := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 2)
	var result := _zap(_splash_chain(1, _strike()), [_enemy("t")], [TARGET], SpellSingle.create(),
			[rock], [Vector2i(3, 3)])
	assert_false(result.obstacles.has("rock_1"))


func test_splash_kills_enemy() -> void:
	var result := _zap(_splash_chain(1, _strike()), [_enemy("t"), _enemy("weak", 3)],
			[TARGET, Vector2i(3, 3)])
	assert_false(result.enemies.has("weak"))
	assert_true(result.dead_enemies.has("weak"))
