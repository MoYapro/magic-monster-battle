extends GutTest


func _make_setup(body_spell: SpellData, enemy: EnemyData) -> BattleSetup:
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = body_spell
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, tip])
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
	s.mage_statuses.append([])
	s.slot_charges["0/s0_0"] = 99  # body slot always charged
	s.slot_charges["0/tip"] = 1    # tip charged
	s.mana = 10
	return s


func _strike_spell() -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


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
	state.mage_statuses[0].append(StatusFrozen.new())
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


# --- on-hit effects ---

func test_fire_on_hit_applies_fire_stacks_to_surviving_enemy() -> void:
	var spell := SpellEmber.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	var fires: Array = (result.enemy_statuses.get("e1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusFire)
	assert_gt(fires.size(), 0)


func test_frost_applies_frozen_to_enemy() -> void:
	var spell := SpellFrost.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	var frozen: Array = (result.enemy_statuses.get("e1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusFrozen)
	assert_gt(frozen.size(), 0)


func test_poison_on_hit_applies_poison_stacks_to_enemy() -> void:
	var spell := SpellVenom.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	var poisons: Array = (result.enemy_statuses.get("e1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusPoison)
	assert_gt(poisons.size(), 0)


func test_poison_stacks_accumulate_across_two_zaps() -> void:
	var spell := SpellVenom.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var state1 := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	# re-charge the slot so second zap fires
	state1.slot_charges["0/s0_0"] = 99
	state1.slot_charges["0/tip"] = 1
	state1.mage_mana_spent[0] = 0
	var state2 := ActionZapWand.new(0, Vector2i(0, 0)).apply(state1, setup)
	var poisons: Array = (state2.enemy_statuses.get("e1", []) as Array).filter(
			func(s: StatusData) -> bool: return s is StatusPoison)
	assert_eq(poisons.size(), 1, "should have one merged poison entry")
	assert_eq((poisons[0] as StatusPoison).stacks, 4, "poison stacks should accumulate (2+2=4)")


func test_on_hit_effects_not_applied_when_enemy_is_killed() -> void:
	var spell := SpellEmber.create()
	var enemy := EnemyData.new("e1", "Target", 2, Vector2i(1, 1), Color.RED)  # low hp
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_false(result.enemy_hp.has("e1"))
	assert_false(result.enemy_statuses.has("e1"))


# --- backfire ---

func test_backfire_deals_damage_to_caster() -> void:
	# force_push + lightning + ember → backfire
	var body := SpellSlotData.new("s0_0", 0, 0, "s1_0")
	body.spell = SpellForcePush.create()
	var r1_slot := SpellSlotData.new("s1_0", 1, 0, "s2_0")
	r1_slot.spell = SpellLightning.create()
	var r2_slot := SpellSlotData.new("s2_0", 2, 0, "tip")
	r2_slot.spell = SpellEmber.create()
	var tip := SpellSlotData.new("tip", 3, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, r1_slot, r2_slot, tip])
	var mage := MageData.new("Mage", 30)
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := BattleSetup.new([enemy], [Vector2i(0, 0)], [mage], [wand], 10)
	var state := BattleState.new()
	state.enemy_hp["e1"] = 20
	state.mage_hp.append(30)
	state.mage_mana_spent.append(0)
	state.mage_statuses.append([])
	state.slot_charges["0/s0_0"] = 99
	state.slot_charges["0/s1_0"] = 99
	state.slot_charges["0/s2_0"] = 99
	state.slot_charges["0/tip"] = 1
	state.mana = 10
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_lt(result.mage_hp[0], 30)
	assert_eq(result.enemy_hp["e1"], 20)  # enemy unharmed


# --- bounce ---

func test_lightning_bounces_to_second_enemy() -> void:
	var e1 := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var e2 := EnemyData.new("e2", "Other", 20, Vector2i(1, 1), Color.BLUE)
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = SpellLightning.create()
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	var setup := BattleSetup.new(
		[e1, e2], [Vector2i(0, 0), Vector2i(1, 0)],
		[mage], [wand], 10)
	var s := BattleState.new()
	s.enemy_hp["e1"] = 20
	s.enemy_hp["e2"] = 20
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	s.slot_charges["0/s0_0"] = 99
	s.slot_charges["0/tip"] = 1
	s.mana = 10
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(s, setup)
	assert_eq(result.enemy_hp.get("e1", 0), 18, "e1 took lightning damage")
	assert_eq(result.enemy_hp.get("e2", 0), 18, "e2 took bounce damage")


# --- cast events ---

func test_cast_events_recorded_on_state() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_gt(result.cast_events.size(), 0)


# --- bone soul harvest ---

func test_bone_kill_refunds_all_zap_mana() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	state.slot_charges["0/s0_0"] = 1  # 1 mana on bone
	state.slot_charges["0/tip"] = 1   # 1 mana on tip
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_false(result.enemy_hp.has("e1"), "enemy should be dead")
	assert_eq(result.mana, 7, "2 mana spent this zap should be refunded")


func test_bone_no_refund_when_enemy_survives() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	state.slot_charges["0/s0_0"] = 1
	state.slot_charges["0/tip"] = 1
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup)
	assert_true(result.enemy_hp.has("e1"), "enemy should survive")
	assert_eq(result.mana, 5, "no refund when kill does not happen")
