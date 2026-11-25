extends GutTest

const GameStateScript := preload("res://scripts/game_state.gd")


func _run() -> Node:
	return autofree(GameStateScript.new())


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


func _killed() -> Array[EnemyData]:
	var e := EnemyData.new("e", "E", 10, Vector2i(1, 1), Color.WHITE)
	e.drop_pool = [SpellEmber.create()]
	var none := EnemyData.new("n", "N", 10, Vector2i(1, 1), Color.WHITE)
	return [e, e, none]


func test_record_win_counts_total_and_biome() -> void:
	var run := _run()
	run.current_biome = BiomesData.all()[1]
	RunProgress.record_win(run, [] as Array[MageData], [] as Array[WandData])
	RunProgress.record_win(run, [] as Array[MageData], [] as Array[WandData])
	assert_eq(run.battle_count, 2)
	assert_eq(run.battle_count_by_biome[BiomesData.all()[1].name], 2)


func test_record_win_without_biome_counts_only_total() -> void:
	var run := _run()
	RunProgress.record_win(run, [] as Array[MageData], [] as Array[WandData])
	assert_eq(run.battle_count, 1)
	assert_true(run.battle_count_by_biome.is_empty())


func test_record_win_stores_mages_and_wands() -> void:
	var run := _run()
	var mages: Array[MageData] = [MageData.new("A", 30)]
	var wands: Array[WandData] = [null]
	RunProgress.record_win(run, mages, wands)
	assert_eq(run.mages, mages)
	assert_eq(run.wands, wands)


func test_loot_biome_defaults_to_first() -> void:
	assert_eq(RunProgress.loot_biome(null), BiomesData.all()[0])
	assert_eq(RunProgress.loot_biome(BiomesData.all()[3]), BiomesData.all()[3])


func test_generate_loot_replaces_pending_loot() -> void:
	var run := _run()
	run.pending_loot.append(SpellEmber.create())
	run.pending_loot_wands.append(WandGenerator.generate(_rng(1)))
	run.pending_loot_wands.append(WandGenerator.generate(_rng(2)))
	RunProgress.generate_loot(run, _killed(), _rng(7))
	assert_eq(run.pending_loot_wands.size(), 1)
	assert_eq(run.battle_drops.size(), 2, "one drop per killed monster with a pool")
	assert_eq(run.pending_loot, run.battle_drops)


func test_generate_loot_is_deterministic_for_seed() -> void:
	var a := _run()
	var b := _run()
	RunProgress.generate_loot(a, _killed(), _rng(42))
	RunProgress.generate_loot(b, _killed(), _rng(42))
	assert_eq(a.pending_loot_wands[0].slots.size(), b.pending_loot_wands[0].slots.size())
	assert_eq(a.battle_drops.map(func(s: SpellData) -> String: return s.spell_id),
			b.battle_drops.map(func(s: SpellData) -> String: return s.spell_id))
