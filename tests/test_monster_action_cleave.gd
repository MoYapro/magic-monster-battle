extends GutTest


func _make_state(mage_hps: Array) -> BattleState:
	var s := BattleState.new()
	s.enemy_hp["troll"] = 200
	for hp in mage_hps:
		s.mage_hp.append(hp)
		s.mage_mana_spent.append(0)
		s.mage_statuses.append([])
	return s


func _make_setup(mage_count: int) -> BattleSetup:
	var enemies: Array[EnemyData] = [Troll.new()]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	var mages: Array[MageData] = []
	var wands: Array[WandData] = []
	for i in mage_count:
		mages.append(MageData.new("Mage %d" % i, 30))
		wands.append(null)
	return BattleSetup.new(enemies, positions, mages, wands, 10)


func test_cleave_damages_all_mages() -> void:
	var setup := _make_setup(2)
	var state := _make_state([30, 30])
	var cleave := MonsterActionCleave.new("Cleave", 8)
	var result := cleave.execute(state, setup, "troll_1", -1)
	assert_eq(result.mage_hp[0], 22)
	assert_eq(result.mage_hp[1], 22)


func test_cleave_does_not_overkill_below_zero() -> void:
	var setup := _make_setup(2)
	var state := _make_state([5, 30])
	var cleave := MonsterActionCleave.new("Cleave", 8)
	var result := cleave.execute(state, setup, "troll_1", -1)
	assert_eq(result.mage_hp[0], 0)
	assert_eq(result.mage_hp[1], 22)


func test_cleave_respects_attack_mult() -> void:
	var setup := _make_setup(2)
	var state := _make_state([30, 30])
	state.enemy_attack_mult["troll_1"] = 2.0
	var cleave := MonsterActionCleave.new("Cleave", 8)
	var result := cleave.execute(state, setup, "troll_1", -1)
	assert_eq(result.mage_hp[0], 14)
	assert_eq(result.mage_hp[1], 14)
