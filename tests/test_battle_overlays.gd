extends GutTest


func _setup_with_goblin() -> BattleSetup:
	var goblin := Goblin.new()
	goblin.id = "g1"
	var enemies: Array[EnemyData] = [goblin]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	var mages: Array[MageData] = [MageData.new("Lyra", 30), MageData.new("Eron", 30)]
	return BattleSetup.new(enemies, positions, mages, [], 10)


func _attack_index(enemy: EnemyData) -> int:
	for i in enemy.action_pool.size():
		if enemy.action_pool[i] is MonsterActionAttack:
			return i
	return -1


func test_threat_lists_monster_aiming_at_the_mage() -> void:
	var setup := _setup_with_goblin()
	var state := setup.make_initial_state()
	var index := _attack_index(setup.enemies[0])
	(state.enemies["g1"] as EnemyState).intent = {"action_index": index, "target": 1}
	var threats := MageThreats.for_mage(state, setup, 1)
	assert_eq(threats.size(), 1)
	assert_eq(threats[0]["enemy"], "Goblin")
	assert_gt(threats[0]["damage"], 0)


func test_no_threat_for_other_mage() -> void:
	var setup := _setup_with_goblin()
	var state := setup.make_initial_state()
	(state.enemies["g1"] as EnemyState).intent = {"action_index": _attack_index(setup.enemies[0]), "target": 1}
	assert_true(MageThreats.for_mage(state, setup, 0).is_empty())


func test_all_mage_intent_threatens_everyone() -> void:
	var setup := _setup_with_goblin()
	var state := setup.make_initial_state()
	(state.enemies["g1"] as EnemyState).intent = {"action_index": _attack_index(setup.enemies[0]), "all_mages": true}
	assert_eq(MageThreats.for_mage(state, setup, 0).size(), 1)


func test_attack_text_has_damage() -> void:
	var goblin := Goblin.new()
	var action := goblin.action_pool[_attack_index(goblin)]
	assert_gt(ActionText.damage(action), 0)
	assert_string_contains(ActionText.summary(action), "dmg")


func test_monster_details_build_for_goblin() -> void:
	var setup := _setup_with_goblin()
	var state := setup.make_initial_state()
	var panel := MonsterDetails.new()
	add_child_autofree(panel)
	panel.setup(setup.enemies[0], state.enemies["g1"], "Forest", "Lyra", func() -> void: pass)
	assert_gt(panel.get_child_count(), 0)


func test_victory_plaque_emits_claimed() -> void:
	var plaque := VictoryPlaque.new()
	add_child_autofree(plaque)
	plaque.setup("The Forest", 3, 4, [] as Array[String])
	watch_signals(plaque)
	plaque.get_children().filter(func(c: Node) -> bool: return c is WaxSealButton)[0].pressed.emit()
	assert_signal_emitted(plaque, "claimed")
