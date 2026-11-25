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


# --- new game ---

func test_start_new_game_creates_three_unarmed_mages() -> void:
	var run := _run()
	RunProgress.start_new_game(run, _rng(1))
	assert_eq(run.mages.map(func(m: MageData) -> String: return m.name), ["Lyra", "Eron", "Vael"])
	for m: MageData in run.mages:
		assert_eq(m.max_hp, 30)
		assert_eq(m.current_hp, 30)
	assert_eq(run.wands, [null, null, null])


func test_start_new_game_offers_four_starter_wands() -> void:
	var run := _run()
	RunProgress.start_new_game(run, _rng(1))
	assert_eq(run.pending_loot_wands.size(), 4)
	for w: WandData in run.pending_loot_wands:
		assert_eq(w.get_tip_slot().spell.spell_id, SpellSingle.create().spell_id)


func test_start_new_game_appends_to_existing_loot_wands() -> void:
	var run := _run()
	run.pending_loot_wands.append(WandGenerator.generate(_rng(3)))
	RunProgress.start_new_game(run, _rng(1))
	assert_eq(run.pending_loot_wands.size(), 5, "callers clear first (reset_to_new_game)")


# --- reroll ---

func test_reroll_replaces_loot_with_four_body_and_one_tip() -> void:
	var run := _run()
	run.battle_drops.append(SpellEmber.create())
	run.pending_loot.append(SpellEmber.create())
	RunProgress.reroll_spell_loot(run, _rng(5))
	assert_eq(run.pending_loot.size(), 5)
	assert_true(run.battle_drops.is_empty(), "rerolled loot has no pick limit")
	assert_eq(run.pending_loot_wands.size(), 1)
	for i in 4:
		assert_false(run.pending_loot[i].tags.has("tip"))
	assert_true(run.pending_loot[4].tags.has("tip"))


# --- path choices ---

func test_path_choices_are_two_distinct_unlocked_biomes() -> void:
	for seed in 20:
		var choices := RunProgress.pick_path_choices({}, _rng(seed))
		assert_eq(choices.size(), 2)
		assert_ne(choices[0], choices[1])
		assert_true(BiomesData.unlocked({}).has(choices[0]))
		assert_true(BiomesData.unlocked({}).has(choices[1]))


func test_path_choices_deterministic_for_seed() -> void:
	assert_eq(RunProgress.pick_path_choices({}, _rng(9)), RunProgress.pick_path_choices({}, _rng(9)))


func test_path_choices_can_include_unlocked_layer_two() -> void:
	var counts := {"Desert": 10}
	var seen := {}
	for seed in 200:
		for b: BiomeData in RunProgress.pick_path_choices(counts, _rng(seed)):
			seen[b.name] = true
	assert_true(seen.has("Pyramids"))
	assert_eq(seen.size(), BiomesData.unlocked(counts).size(), "every unlocked biome can come up")


func test_path_choices_do_not_mutate_registry() -> void:
	var before := BiomesData.all().duplicate()
	RunProgress.pick_path_choices({}, _rng(4))
	assert_eq(BiomesData.all(), before)


func test_choose_paths_with_single_biome_returns_it() -> void:
	var pool: Array[BiomeData] = [BiomesData.all()[0]]
	assert_eq(RunProgress.choose_paths(pool, _rng(1)), pool)


func test_choose_paths_with_empty_pool_returns_nothing() -> void:
	var pool: Array[BiomeData] = []
	assert_true(RunProgress.choose_paths(pool, _rng(1)).is_empty())


func test_choose_paths_does_not_mutate_pool() -> void:
	var pool: Array[BiomeData] = BiomesData.all().duplicate()
	var before := pool.duplicate()
	RunProgress.choose_paths(pool, _rng(3))
	assert_eq(pool, before)
