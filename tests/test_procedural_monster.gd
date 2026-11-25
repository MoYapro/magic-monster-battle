extends GutTest


func test_head_and_weapons_found_by_name() -> void:
	var names: Array[String] = ["ground", "torso", "head", "ear_far", "knife", "hand_near"]
	assert_eq(MonsterParts.head(names), "head")
	assert_eq(MonsterParts.weapons(names), ["knife"] as Array[String])


func test_no_head_gives_empty_name() -> void:
	assert_eq(MonsterParts.head(["blade", "guard"] as Array[String]), "")


func test_ground_does_not_move() -> void:
	assert_true(MonsterParts.is_static("ground"))
	assert_false(MonsterParts.is_static("torso"))


func test_hit_when_hp_drops() -> void:
	assert_eq(MonsterReactions.hit({"a": 20, "b": 10}, {"a": 15, "b": 10}), ["a"] as Array[String])


func test_died_when_missing_after() -> void:
	assert_eq(MonsterReactions.died({"a": 20, "b": 10}, {"a": 20}), ["b"] as Array[String])


func test_new_monster_is_neither_hit_nor_dead() -> void:
	assert_true(MonsterReactions.hit({}, {"a": 5}).is_empty())
	assert_true(MonsterReactions.died({}, {"a": 5}).is_empty())


func test_goblin_assembles_one_node_per_joint() -> void:
	var m := ProceduralMonster.create("goblin", Vector2(80, 80))
	add_child_autofree(m)
	assert_eq(m.parts.size(), m.rig.joints.size())
	assert_eq(m.parts["ear_far"].get_parent(), m.parts["head"])
	assert_almost_eq(m.scale.x, 80.0 / 256.0, 0.001)


func test_monster_without_rig_is_null() -> void:
	assert_null(ProceduralMonster.create("no_such_monster", Vector2(80, 80)))


func test_die_animation_finishes() -> void:
	var m := ProceduralMonster.create("goblin", Vector2(80, 80))
	add_child_autofree(m)
	watch_signals(m)
	m.play(&"die")
	await wait_for_signal(m.animation_finished, 3.0)
	assert_signal_emitted(m, "animation_finished")
