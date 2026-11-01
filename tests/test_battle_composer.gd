extends GutTest


func _biome(layer: int) -> BiomeData:
	var b := BiomeData.new("Test", "", Color.WHITE, Vector2i.ZERO, layer, [])
	b.obstacle_pool = [Stone, Obelisk, SandDune, Log]
	return b


func _has_blocking(pool: Array) -> bool:
	return pool.any(func(cls) -> bool: return cls.new().is_blocking)


func test_starter_biome_level_1_pool_has_only_low_obstacles() -> void:
	assert_eq(BattleComposer.obstacle_pool_for(_biome(1), 1), [SandDune, Log])


func test_starter_biome_level_2_pool_has_only_low_obstacles() -> void:
	assert_false(_has_blocking(BattleComposer.obstacle_pool_for(_biome(1), 2)))


func test_starter_biome_level_3_uses_full_pool() -> void:
	assert_eq(BattleComposer.obstacle_pool_for(_biome(1), 3).size(), 4)


func test_later_layer_level_1_uses_full_pool() -> void:
	assert_eq(BattleComposer.obstacle_pool_for(_biome(2), 1).size(), 4)


func test_starter_biome_without_low_obstacles_spawns_none() -> void:
	var biome := _biome(1)
	biome.obstacle_pool = [Stone, Obelisk]
	biome.monster_pool = BiomesData.by_layer(1)[0].monster_pool
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	assert_eq(BattleComposer.compose(biome, 1, rng)["obstacles"].size(), 0)


func test_every_starter_biome_spawns_no_blocking_obstacles_on_level_1() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for biome: BiomeData in BiomesData.by_layer(1):
		for _i in 10:
			var obstacles: Array = BattleComposer.compose(biome, 1, rng)["obstacles"]
			assert_false(obstacles.any(func(o: ObstacleData) -> bool: return o.is_blocking), biome.name)
