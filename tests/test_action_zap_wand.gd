extends GutTest


func _make_setup(spell: SpellData, enemy: EnemyData) -> BattleSetup:
	var tip := SpellSlotData.new("tip", 0, 0)
	tip.spell = spell
	var wand := WandData.new([tip])
	var mage := MageData.new("Mage", 30)
	var mages: Array[MageData] = [mage]
	var wands: Array[WandData] = [wand]
	var enemies: Array[EnemyData] = [enemy]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	return BattleSetup.new(enemies, positions, mages, wands, 10)


func _make_state(setup: BattleSetup) -> BattleState:
	var s := BattleState.new()
	for e: EnemyData in setup.enemies:
		s.enemy_hp[e.id] = e.max_hp
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_fire.append(0)
	s.mage_wet.append(0)
	s.mage_frozen.append(false)
	s.slot_charges["0/tip"] = 1
	s.mana = 10
	return s


func _strike_spell() -> SpellData:
	return SpellData.new("Strike", "S", [], Color.WHITE, [Vector2i(0, 0)], "", 5, 1)


# --- damage ---

func test_zap_reduces_enemy_hp_by_spell_damage() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_eq(result.enemy_hp["e1"], 15)


func test_zap_kills_enemy_when_damage_meets_or_exceeds_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_false(result.enemy_hp.has("e1"))


func test_zap_does_nothing_when_mage_is_frozen() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	state.mage_frozen[0] = true
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_eq(result.enemy_hp["e1"], 20)


# --- armor ---

func test_armor_absorbs_damage_before_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	state.enemy_armor["e1"] = 3
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	# 5 damage, 3 absorbed → 2 reaches hp
	assert_eq(result.enemy_hp["e1"], 18)


func test_armor_is_removed_when_fully_depleted() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	state.enemy_armor["e1"] = 3
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_false(result.enemy_armor.has("e1"))


# --- block ---

func test_block_prevents_all_damage() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	state.enemy_block["e1"] = 2
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_eq(result.enemy_hp["e1"], 20)


func test_block_consumes_one_charge_per_hit() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	state.enemy_block["e1"] = 2
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_eq(result.enemy_block.get("e1", 0), 1)


# --- fire / wet ---

func test_fire_spell_applies_fire_stacks_to_surviving_enemy() -> void:
	# damage=4 with fire tag → fire_stacks = max(0, 4-1) = 3
	var spell := SpellData.new("Ember", "E", ["fire"], Color.RED, [Vector2i(0, 0)], "", 4, 1)
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_eq(result.enemy_fire.get("e1", 0), 3)


func test_water_spell_applies_wet_stacks_to_enemy() -> void:
	var spell := SpellData.new("Frost", "F", ["water"], Color.BLUE, [Vector2i(0, 0)], "", 3, 1)
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_gt(result.enemy_wet.get("e1", 0), 0)
