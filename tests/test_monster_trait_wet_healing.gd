extends GutTest


func _make_setup(max_hp: int) -> BattleSetup:
	var treant := Treant.new()
	treant.max_hp = max_hp
	var enemies: Array[EnemyData] = [treant]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	return BattleSetup.new(enemies, positions, [], [], 10)


func _make_state(hp: int, wet: int) -> BattleState:
	var s := BattleState.new()
	s.enemy_hp["treant_1"] = hp
	if wet > 0:
		s.add_enemy_status("treant_1", StatusWet.new(wet))
	return s


func test_heals_by_wet_stack_count() -> void:
	var setup := _make_setup(650)
	var state := _make_state(500, 4)
	var wet_healing := MonsterTraitWetHealing.new(1)
	var result := wet_healing.apply_end_of_round(state, setup, "treant_1")
	assert_eq(result.enemy_hp["treant_1"], 504)


func test_does_not_exceed_max_hp() -> void:
	var setup := _make_setup(650)
	var state := _make_state(648, 5)
	var wet_healing := MonsterTraitWetHealing.new(1)
	var result := wet_healing.apply_end_of_round(state, setup, "treant_1")
	assert_eq(result.enemy_hp["treant_1"], 650)


func test_no_heal_without_wet() -> void:
	var setup := _make_setup(650)
	var state := _make_state(500, 0)
	var wet_healing := MonsterTraitWetHealing.new(1)
	var result := wet_healing.apply_end_of_round(state, setup, "treant_1")
	assert_eq(result.enemy_hp["treant_1"], 500)


func test_does_not_consume_wet_stacks() -> void:
	var setup := _make_setup(650)
	var state := _make_state(500, 3)
	var wet_healing := MonsterTraitWetHealing.new(1)
	var result := wet_healing.apply_end_of_round(state, setup, "treant_1")
	var wet_status: StatusWet = (result.enemy_statuses.get("treant_1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusWet)[0]
	assert_eq(wet_status.stacks, 3)
