extends GutTest


func test_puddle_shows_the_wet_tile() -> void:
	var base := GroundTiles.base_for_biome("Desert")
	assert_eq(GroundTiles.tile_for(base, GroundType.Type.PUDDLE, Vector2i(2, 3)), "wet")


func test_soil_picks_from_the_biome_mix_stably() -> void:
	var base := GroundTiles.base_for_biome("Tundra")
	var a := GroundTiles.tile_for(base, GroundType.Type.SOIL, Vector2i(1, 4))
	assert_true(base.has(a))
	assert_eq(GroundTiles.tile_for(base, GroundType.Type.SOIL, Vector2i(1, 4)), a)


func test_unknown_biome_uses_default_mix() -> void:
	assert_eq(GroundTiles.base_for_biome("Nowhere"), GroundTiles.DEFAULT_BASE)


func test_every_biome_tile_exists() -> void:
	for biome in BiomesData.all():
		for tile in GroundTiles.base_for_biome(biome.name):
			assert_not_null(GroundTiles.texture(tile), "%s: %s" % [biome.name, tile])


func test_attack_intent_shows_damage() -> void:
	var goblin := Goblin.new()
	var index := -1
	for i in goblin.action_pool.size():
		if goblin.action_pool[i] is MonsterActionAttack:
			index = i
	assert_ne(index, -1)
	var dmg := (goblin.action_pool[index] as MonsterActionAttack).damage
	assert_eq(IntentLabel.text_for(goblin, {"action_index": index}), "⚔ %d" % dmg)


func test_all_mage_intent_is_marked() -> void:
	var goblin := Goblin.new()
	for i in goblin.action_pool.size():
		if goblin.action_pool[i] is MonsterActionAttack:
			assert_string_ends_with(IntentLabel.text_for(goblin, {"action_index": i, "all_mages": true}), " all")
			return


func test_unknown_action_falls_back_to_name() -> void:
	assert_eq(IntentLabel.text_for(Goblin.new(), {"action_index": 99, "action_name": "Lurk"}), "Lurk")
