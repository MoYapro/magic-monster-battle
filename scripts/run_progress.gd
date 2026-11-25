class_name RunProgress

# Run-level bookkeeping between scenes. `run` is the GameState autoload
# (or a fresh instance of scripts/game_state.gd in tests).


static func record_win(run: Object, mages: Array[MageData], wands: Array[WandData]) -> void:
	run.battle_count += 1
	if run.current_biome != null:
		var biome_name: String = run.current_biome.name
		run.battle_count_by_biome[biome_name] = run.battle_count_by_biome.get(biome_name, 0) + 1
	run.mages = mages
	run.wands = wands


static func loot_biome(biome: BiomeData) -> BiomeData:
	return biome if biome != null else BiomesData.all()[0]


static func generate_loot(run: Object, killed: Array[EnemyData], rng: RandomNumberGenerator) -> void:
	var biome := loot_biome(run.current_biome)
	run.pending_loot.clear()
	run.pending_loot_wands.clear()
	run.pending_loot_wands.append(WandGenerator.generate_biome_wand(rng, biome.layer))
	run.battle_drops = LootRoller.roll_drops(killed, rng)
	run.pending_loot.append_array(run.battle_drops)
