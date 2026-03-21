class_name BattleComposer

enum BattleType { HORDE, ELITE }

const MIN_MONSTERS := 2
const HORDE_BASE_COUNT := 5
const ELITE_BASE_COUNT := 2



static func compose(biome: BiomeData, biome_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var battle_type: BattleType = BattleType.HORDE if rng.randi() % 2 == 0 else BattleType.ELITE
	var enemies := _select_monsters(biome.monster_pool, battle_type, biome_level, rng)
	var obstacles := _select_obstacles(rng)

	# Obstacles placed first — they claim front rows before enemies.
	var occupied: Dictionary = {}
	var raw_obs_pos := _place_items(obstacles, rng, occupied)
	var raw_enemy_pos := _place_items(enemies, rng, occupied)

	var placed_obstacles: Array[ObstacleData] = []
	var placed_obs_positions: Array[Vector2i] = []
	for i in obstacles.size():
		if raw_obs_pos[i].x >= 0:
			placed_obstacles.append(obstacles[i])
			placed_obs_positions.append(raw_obs_pos[i])

	var placed_enemies: Array[EnemyData] = []
	var placed_positions: Array[Vector2i] = []
	for i in enemies.size():
		if raw_enemy_pos[i].x >= 0:
			placed_enemies.append(enemies[i])
			placed_positions.append(raw_enemy_pos[i])

	return {
		"enemies": placed_enemies,
		"positions": placed_positions,
		"obstacles": placed_obstacles,
		"obstacle_positions": placed_obs_positions,
	}


static func _select_monsters(
	pool: Array,
	battle_type: BattleType,
	biome_level: int,
	rng: RandomNumberGenerator
) -> Array[EnemyData]:
	var sorted_pool := _sort_by_difficulty(pool)

	var candidates: Array
	var target_count: int
	if battle_type == BattleType.HORDE:
		candidates = _lower_half(sorted_pool)
		target_count = HORDE_BASE_COUNT + (biome_level - 1)
	else:
		candidates = _upper_half(sorted_pool)
		target_count = max(MIN_MONSTERS, ELITE_BASE_COUNT + (biome_level - 1) / 3)

	target_count = max(target_count, MIN_MONSTERS)

	var enemies: Array[EnemyData] = []
	var id_counts: Dictionary = {}
	for _i in target_count:
		var cls: GDScript = candidates[rng.randi() % candidates.size()]
		var enemy: EnemyData = cls.new()
		var base_id := enemy.display_name.to_lower().replace(" ", "_")
		id_counts[base_id] = id_counts.get(base_id, 0) + 1
		enemy.id = base_id + "_" + str(id_counts[base_id])
		enemies.append(enemy)

	return enemies


static func _select_obstacles(rng: RandomNumberGenerator) -> Array[ObstacleData]:
	var pool: Array = [
		preload("res://scripts/battle/obstacles/stone.gd"),
		preload("res://scripts/battle/obstacles/barrel.gd"),
		preload("res://scripts/battle/obstacles/log.gd"),
		preload("res://scripts/battle/obstacles/tree.gd"),
		preload("res://scripts/battle/obstacles/boulder.gd"),
		preload("res://scripts/battle/obstacles/monolith.gd"),
	]

	var weights: Array[int] = []
	var total_weight := 0
	for cls in pool:
		var w: int = cls.new().generation_weight
		weights.append(w)
		total_weight += w

	var count := rng.randi_range(1, 3)
	var obstacles: Array[ObstacleData] = []
	var id_counts: Dictionary = {}
	for _i in count:
		var roll := rng.randi_range(0, total_weight - 1)
		var cumulative := 0
		var chosen_cls: Variant = pool[pool.size() - 1]
		for j in pool.size():
			cumulative += weights[j]
			if roll < cumulative:
				chosen_cls = pool[j]
				break
		var obstacle: ObstacleData = chosen_cls.new()
		var base_id := obstacle.display_name.to_lower()
		id_counts[base_id] = id_counts.get(base_id, 0) + 1
		obstacle.id = base_id + "_" + str(id_counts[base_id])
		obstacles.append(obstacle)

	return obstacles


static func _sort_by_difficulty(pool: Array) -> Array:
	var sorted := pool.duplicate()
	var cache: Dictionary = {}
	for cls in sorted:
		cache[cls] = (cls as GDScript).new().difficulty_rating
	sorted.sort_custom(func(a: GDScript, b: GDScript) -> bool: return cache[a] < cache[b])
	return sorted


# Returns the easier half of the pool (for Horde).
# Pools of size <= 2 return the full pool so both battle types have variety.
static func _lower_half(sorted_pool: Array) -> Array:
	if sorted_pool.size() <= 2:
		return sorted_pool.duplicate()
	return sorted_pool.slice(0, sorted_pool.size() / 2 + 1)


# Returns the harder half of the pool (for Elite).
# Pools of size <= 2 return the full pool so both battle types have variety.
static func _upper_half(sorted_pool: Array) -> Array:
	if sorted_pool.size() <= 2:
		return sorted_pool.duplicate()
	return sorted_pool.slice(sorted_pool.size() / 2)


# Places any items with .main_role and .grid_size, biased by role order.
# Mutates occupied so callers can chain multiple placement passes.
static func _place_items(items: Array, rng: RandomNumberGenerator, occupied: Dictionary) -> Array[Vector2i]:
	var order := range(items.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return int(items[a].main_role) < int(items[b].main_role)
	)

	var positions: Array[Vector2i] = []
	positions.resize(items.size())

	for i in order:
		var grid_size: Vector2i = items[i].grid_size
		var role: MonsterRole.Type = items[i].main_role
		var valid: Array[Vector2i] = []
		for col in range(EnemyGrid.COLS - grid_size.x + 1):
			for row in range(EnemyGrid.ROWS - grid_size.y + 1):
				var pos := Vector2i(col, row)
				if _can_place(pos, grid_size, occupied):
					valid.append(pos)
		if valid.is_empty():
			positions[i] = Vector2i(-1, -1)
			continue
		var pref_row := _preferred_row(role)
		var chosen := _pick_biased(valid, pref_row, rng)
		positions[i] = chosen
		for dx in range(grid_size.x):
			for dy in range(grid_size.y):
				occupied[chosen + Vector2i(dx, dy)] = true

	return positions


# Maps a role's enum value onto a preferred grid row (0 = front, ROWS-1 = back).
static func _preferred_row(role: MonsterRole.Type) -> int:
	if role == MonsterRole.Type.NONE:
		return EnemyGrid.ROWS / 2
	return int(round(float(role) / float(MonsterRole.Type.ARTILLERY) * (EnemyGrid.ROWS - 1)))


# Picks randomly from valid positions biased toward preferred_row.
# Accepts the closest available row plus one further — guideline, not strict.
static func _pick_biased(valid: Array[Vector2i], preferred_row: int, rng: RandomNumberGenerator) -> Vector2i:
	var sorted := valid.duplicate()
	sorted.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return abs(a.y - preferred_row) < abs(b.y - preferred_row)
	)
	var min_dist: int = abs((sorted[0] as Vector2i).y - preferred_row)
	var candidates: Array[Vector2i] = sorted.filter(func(p: Vector2i) -> bool:
		return abs(p.y - preferred_row) <= min_dist + 1
	)
	return candidates[rng.randi() % candidates.size()]


static func _can_place(pos: Vector2i, size: Vector2i, occupied: Dictionary) -> bool:
	for dx in range(size.x):
		for dy in range(size.y):
			if occupied.has(pos + Vector2i(dx, dy)):
				return false
	return true
