extends GutTest

# BonePile (2x1) placed at (2, 3) occupies cells (2,3) and (3,3).
# The dust cloud covers the 1-cell border around those cells: x 1–4, y 2–4.


func _make_setup(
		body_spell: SpellData,
		enemies: Array[EnemyData],
		enemy_positions: Array[Vector2i],
		obstacles: Array[ObstacleData],
		obstacle_positions: Array[Vector2i]
) -> BattleSetup:
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = body_spell
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	return BattleSetup.new(enemies, enemy_positions, [mage], [wand], 10, obstacles, obstacle_positions)


func _make_state(setup: BattleSetup) -> BattleState:
	var s := BattleState.new()
	for e: EnemyData in setup.enemies:
		s.enemy_hp[e.id] = e.max_hp
	for o: ObstacleData in setup.obstacles:
		s.obstacle_hp[o.id] = o.max_hp
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	s.slot_charges["0/s0_0"] = 99
	s.slot_charges["0/tip"] = 1
	s.mana = 10
	return s


func _strike() -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


# --- BonePile dust cloud ---

func test_hitting_bone_pile_blinds_adjacent_enemy() -> void:
	var bone_pile := BonePile.new()
	var enemy := EnemyData.new("goblin_1", "Goblin", 20, Vector2i(1, 1), Color.GREEN)
	var setup := _make_setup(
		_strike(),
		[enemy], [Vector2i(1, 3)],          # inside cloud
		[bone_pile], [Vector2i(2, 3)]
	)
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(_make_state(setup), setup)
	var blind: Array = (result.enemy_statuses.get("goblin_1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusBlind)
	assert_gt(blind.size(), 0)


func test_hitting_bone_pile_does_not_blind_distant_enemy() -> void:
	var bone_pile := BonePile.new()
	var enemy := EnemyData.new("goblin_1", "Goblin", 20, Vector2i(1, 1), Color.GREEN)
	var setup := _make_setup(
		_strike(),
		[enemy], [Vector2i(0, 0)],          # outside cloud
		[bone_pile], [Vector2i(2, 3)]
	)
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(_make_state(setup), setup)
	var blind: Array = (result.enemy_statuses.get("goblin_1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusBlind)
	assert_eq(blind.size(), 0)


func test_bone_pile_cloud_fires_even_when_destroyed_by_the_hit() -> void:
	var bone_pile := BonePile.new()
	var enemy := EnemyData.new("goblin_1", "Goblin", 20, Vector2i(1, 1), Color.GREEN)
	var setup := _make_setup(
		_strike(),
		[enemy], [Vector2i(1, 3)],
		[bone_pile], [Vector2i(2, 3)]
	)
	var state := _make_state(setup)
	state.obstacle_hp["bone_pile"] = 1      # will die from the hit
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(state, setup)
	assert_false(result.obstacle_hp.has("bone_pile"), "bone pile destroyed")
	var blind: Array = (result.enemy_statuses.get("goblin_1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusBlind)
	assert_gt(blind.size(), 0, "cloud still fires on lethal hit")


func test_hitting_bone_pile_reduces_its_hp() -> void:
	var bone_pile := BonePile.new()
	var setup := _make_setup(_strike(), [], [], [bone_pile], [Vector2i(2, 3)])
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(_make_state(setup), setup)
	assert_eq(result.obstacle_hp.get("bone_pile", -1), bone_pile.max_hp - 5)
