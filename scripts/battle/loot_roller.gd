class_name LootRoller

# Rolls post-battle spell drops (one per killed monster) and enforces the pick limit.

const MAX_PICKS := 3
const RANDOM_DROP_CHANCE := 0.01


static func roll_drops(killed: Array[EnemyData], rng: RandomNumberGenerator) -> Array[SpellData]:
	var drops: Array[SpellData] = []
	for enemy: EnemyData in killed:
		if not enemy.drop_pool.is_empty():
			drops.append(roll_drop(enemy, rng))
	return drops


# A monster always drops from its own pool, with a rare chance of any spell instead.
static func roll_drop(enemy: EnemyData, rng: RandomNumberGenerator) -> SpellData:
	if rng.randf() < RANDOM_DROP_CHANCE:
		var any := SpellRegistry.all_body_spells() + SpellRegistry.all_tip_spells()
		return any[rng.randi_range(0, any.size() - 1)]
	return enemy.drop_pool[rng.randi_range(0, enemy.drop_pool.size() - 1)]


# Drops count as picked once they have left the loot area.
static func picks_used(drops: Array[SpellData], loot_area: Array[SpellData]) -> int:
	return drops.filter(func(s: SpellData) -> bool: return not loot_area.has(s)).size()


static func can_pick(spell: SpellData, drops: Array[SpellData], loot_area: Array[SpellData]) -> bool:
	return not drops.has(spell) or picks_used(drops, loot_area) < MAX_PICKS
