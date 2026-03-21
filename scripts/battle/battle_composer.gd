class_name BattleComposer

enum BattleType { HORDE, ELITE }

const MIN_MONSTERS := 2
const HORDE_BASE_COUNT := 5
const ELITE_BASE_COUNT := 2


static func compose(biome: BiomeData, biome_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var battle_type: BattleType = BattleType.HORDE if rng.randi() % 2 == 0 else BattleType.ELITE
	var enemies := _select_monsters(biome.monster_pool, battle_type, biome_level, rng)
	var positions := _place(enemies, rng)

	var placed_enemies: Array[EnemyData] = []
	var placed_positions: Array[Vector2i] = []
	for i in enemies.size():
		if positions[i].x >= 0:
			placed_enemies.append(enemies[i])
			placed_positions.append(positions[i])

	return {"enemies": placed_enemies, "positions": placed_positions}


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


static func _place(enemies: Array[EnemyData], rng: RandomNumberGenerator) -> Array[Vector2i]:
	# Place front-role monsters first so they claim preferred rows before back-row types.
	var order := range(enemies.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		return int(enemies[a].main_role) < int(enemies[b].main_role)
	)

	var occupied: Dictionary = {}
	var positions: Array[Vector2i] = []
	positions.resize(enemies.size())

	for i in order:
		var enemy: EnemyData = enemies[i]
		var valid: Array[Vector2i] = []
		for col in range(EnemyGrid.COLS - enemy.grid_size.x + 1):
			for row in range(EnemyGrid.ROWS - enemy.grid_size.y + 1):
				var pos := Vector2i(col, row)
				if _can_place(pos, enemy.grid_size, occupied):
					valid.append(pos)
		if valid.is_empty():
			positions[i] = Vector2i(-1, -1)
			continue
		var pref_row := _preferred_row(enemy.main_role)
		var chosen := _pick_biased(valid, pref_row, rng)
		positions[i] = chosen
		for dx in range(enemy.grid_size.x):
			for dy in range(enemy.grid_size.y):
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
