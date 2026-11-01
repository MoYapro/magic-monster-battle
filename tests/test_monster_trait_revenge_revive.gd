extends GutTest


func _make_enemy(id: String, max_hp: int, reviver: bool = false) -> EnemyData:
	var enemy := EnemyData.new(id, id, max_hp, Vector2i(1, 1), Color.RED)
	if reviver:
		enemy.traits = [MonsterTraitRevengeRevive.new()]
	return enemy


func _make_setup(enemies: Array[EnemyData]) -> BattleSetup:
	var positions: Array[Vector2i] = []
	for i in enemies.size():
		positions.append(Vector2i(i, 0))
	var mages: Array[MageData] = [MageData.new("Mage", 30)]
	return BattleSetup.new(enemies, positions, mages, [], 10)


func _make_state(setup: BattleSetup) -> BattleState:
	var s := BattleState.new()
	for enemy: EnemyData in setup.enemies:
		var es := EnemyState.new()
		es.combatant.hp = enemy.max_hp
		s.enemies[enemy.id] = es
	return s


func test_reviver_brings_back_dead_ally_at_full_hp() -> void:
	var setup := _make_setup([_make_enemy("caller", 30, true), _make_enemy("ogre", 50)])
	var state := _make_state(setup)

	state.kill_enemy("ogre", setup)

	assert_true(state.enemies.has("ogre"), "Ogre should be revived")
	assert_eq((state.enemies["ogre"] as EnemyState).combatant.hp, 50)
	assert_eq((state.enemies["ogre"] as EnemyState).position, Vector2i(1, 0), "Revived at last position")
	assert_false(state.dead_enemies.has("ogre"))


func test_reviver_picks_strongest_dead_ally() -> void:
	var setup := _make_setup([
		_make_enemy("caller", 30, true), _make_enemy("goblin", 10), _make_enemy("ogre", 50)])
	var state := _make_state(setup)
	state.dead_enemies["goblin"] = state.enemies["goblin"]
	state.dead_enemies["ogre"] = state.enemies["ogre"]
	state.enemies.erase("goblin")
	state.enemies.erase("ogre")

	MonsterTraitRevengeRevive.new().apply_on_monster_dies(state, setup, "caller", "goblin")

	assert_true(state.enemies.has("ogre"), "Strongest dead ally should be revived")
	assert_false(state.enemies.has("goblin"))


func test_reviver_does_not_revive_another_reviver() -> void:
	var setup := _make_setup([_make_enemy("caller_a", 30, true), _make_enemy("caller_b", 30, true)])
	var state := _make_state(setup)

	state.kill_enemy("caller_a", setup)

	assert_false(state.enemies.has("caller_a"), "Bone callers must not revive each other")
	assert_true(state.dead_enemies.has("caller_a"))


func test_multiple_revivers_can_all_be_killed() -> void:
	var setup := _make_setup([_make_enemy("caller_a", 30, true), _make_enemy("caller_b", 30, true)])
	var state := _make_state(setup)

	state.kill_enemy("caller_a", setup)
	state.kill_enemy("caller_b", setup)

	assert_true(state.enemies.is_empty(), "Battle should be winnable")


func test_reviver_skips_revivers_and_revives_regular_ally() -> void:
	var setup := _make_setup([
		_make_enemy("caller_a", 30, true), _make_enemy("caller_b", 80, true), _make_enemy("goblin", 10)])
	var state := _make_state(setup)
	state.kill_enemy("goblin")
	state.kill_enemy("caller_b", setup)

	assert_true(state.enemies.has("goblin"), "Regular ally should be revived instead")
	assert_false(state.enemies.has("caller_b"))
