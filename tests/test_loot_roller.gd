extends GutTest


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


func _enemy(id: String, pool: Array[SpellData]) -> EnemyData:
	var e := EnemyData.new(id, id, 10, Vector2i(1, 1), Color.WHITE)
	e.drop_pool = pool
	return e


func _killed(count: int) -> Array[EnemyData]:
	var killed: Array[EnemyData] = []
	for i in count:
		killed.append(_enemy("e%d" % i, [SpellEmber.create()]))
	return killed


func test_every_killed_monster_drops() -> void:
	assert_eq(LootRoller.roll_drops(_killed(7), _rng(1)).size(), 7)


func test_monster_without_pool_drops_nothing() -> void:
	var killed: Array[EnemyData] = [_enemy("e0", [])]
	assert_eq(LootRoller.roll_drops(killed, _rng(1)).size(), 0)


func _spells(count: int) -> Array[SpellData]:
	var spells: Array[SpellData] = []
	for _i in count:
		spells.append(SpellEmber.create())
	return spells


func test_picks_used_counts_drops_outside_loot_area() -> void:
	var drops := _spells(5)
	var loot_area: Array[SpellData] = [drops[0], drops[2], drops[4]]
	assert_eq(LootRoller.picks_used(drops, loot_area), 2)


func test_can_pick_until_limit_reached() -> void:
	var drops := _spells(5)
	var loot_area: Array[SpellData] = [drops[2], drops[3], drops[4]]
	assert_true(LootRoller.can_pick(drops[2], drops, loot_area))
	loot_area.erase(drops[2])
	assert_false(LootRoller.can_pick(drops[3], drops, loot_area), "3 picks used")


func test_returning_a_drop_frees_a_pick() -> void:
	var drops := _spells(5)
	var loot_area: Array[SpellData] = [drops[3], drops[4]]
	assert_false(LootRoller.can_pick(drops[3], drops, loot_area))
	loot_area.append(drops[0])
	assert_true(LootRoller.can_pick(drops[3], drops, loot_area))


func test_non_drop_spells_are_never_limited() -> void:
	var drops := _spells(3)
	var loot_area: Array[SpellData] = []
	var displaced := SpellFrost.create()
	loot_area.append(displaced)
	assert_true(LootRoller.can_pick(displaced, drops, loot_area))


func test_drop_comes_from_monster_pool_almost_always() -> void:
	var enemy := _enemy("e0", [SpellBone.create()])
	var rng := _rng(7)
	var from_pool := 0
	for _i in 1000:
		if LootRoller.roll_drop(enemy, rng).spell_id == "bone":
			from_pool += 1
	assert_gt(from_pool, 950)


func test_rare_random_drop_can_leave_the_pool() -> void:
	var enemy := _enemy("e0", [SpellBone.create()])
	var rng := _rng(7)
	var foreign := 0
	for _i in 5000:
		if LootRoller.roll_drop(enemy, rng).spell_id != "bone":
			foreign += 1
	assert_gt(foreign, 0)
