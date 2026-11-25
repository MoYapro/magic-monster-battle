extends GutTest


func _all_obstacles() -> Array[ObstacleData]:
	var seen := {}
	var out: Array[ObstacleData] = []
	for biome in BiomesData.all():
		for cls in biome.obstacle_pool:
			if not seen.has(cls):
				seen[cls] = true
				out.append(cls.new())
	return out


func test_every_obstacle_in_the_game_has_art() -> void:
	for obs in _all_obstacles():
		assert_not_null(ObstacleArt.texture(obs), "no art for %s" % ObstacleArt.art_id(obs))


func test_art_matches_the_footprint() -> void:
	for obs in _all_obstacles():
		var tex := ObstacleArt.texture(obs)
		if tex != null:
			assert_eq(Vector2i(tex.get_size()) / 256, obs.grid_size, ObstacleArt.art_id(obs))


func test_art_id_is_the_script_name() -> void:
	assert_eq(ObstacleArt.art_id(Boulder.new()), "boulder")
