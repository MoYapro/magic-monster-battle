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


const STARTER_MAGES := ["Lyra", "Eron", "Vael"]
const STARTER_MAGE_HP := 30
const STARTER_WAND_COUNT := 4
const REROLL_BODY_SPELLS := 4
const PATH_CHOICE_COUNT := 2


static func start_new_game(run: Object, rng: RandomNumberGenerator) -> void:
	var mages: Array[MageData] = []
	for mage_name: String in STARTER_MAGES:
		mages.append(MageData.new(mage_name, STARTER_MAGE_HP))
	run.mages = mages
	run.wands.clear()
	for _i in mages.size():
		run.wands.append(null)
	for _i in STARTER_WAND_COUNT:
		run.pending_loot_wands.append(WandGenerator.generate_starter(rng))


static func reroll_spell_loot(run: Object, rng: RandomNumberGenerator) -> void:
	run.pending_loot.clear()
	run.battle_drops.clear()
	run.pending_loot_wands.clear()
	run.pending_loot_wands.append(WandGenerator.generate(rng))
	var all_body := SpellRegistry.all_body_spells()
	for _i in REROLL_BODY_SPELLS:
		run.pending_loot.append(all_body[rng.randi_range(0, all_body.size() - 1)])
	run.pending_loot.append(WandGenerator._pick_tip_spell(rng))


# Two distinct biomes, drawn uniformly from those unlocked by the battle counts.
static func pick_path_choices(battle_counts: Dictionary, rng: RandomNumberGenerator) -> Array[BiomeData]:
	var pool := BiomesData.unlocked(battle_counts)
	_shuffle(pool, rng)
	return pool.slice(0, PATH_CHOICE_COUNT)


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
