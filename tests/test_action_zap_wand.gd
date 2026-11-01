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
		var es := EnemyState.new()
		es.combatant.hp = e.max_hp
		s.enemies[e.id] = es
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 99  # body slot always charged
	ms.slot_charges["tip"] = 1    # tip charged
	s.mages.append(ms)
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
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 15)


func test_zap_kills_enemy_when_damage_meets_or_exceeds_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	assert_false(result.enemies.has("e1"))


func test_zap_does_nothing_when_mage_is_frozen() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).combatant.statuses.append(StatusFrozen.new())
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 20)


# --- armor ---

func test_armor_absorbs_damage_before_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).armor = 3
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	# 5 damage, 3 absorbed → 2 reaches hp
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 18)


func test_armor_is_removed_when_fully_depleted() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).armor = 3
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).armor, 0)


# --- block ---

func test_block_prevents_all_damage() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).block = 2
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 20)


func test_block_consumes_one_charge_per_hit() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).block = 2
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).block, 1)


# --- on-hit effects ---

func test_fire_on_hit_applies_fire_stacks_to_surviving_enemy() -> void:
	var spell := SpellEmber.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	var fires: Array = (result.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusFire)
	assert_gt(fires.size(), 0)


func test_frost_applies_frozen_to_enemy() -> void:
	var spell := SpellFrost.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	var frozen: Array = (result.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusFrozen)
	assert_gt(frozen.size(), 0)


func test_poison_on_hit_applies_poison_stacks_to_enemy() -> void:
	var spell := SpellVenom.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	var poisons: Array = (result.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusPoison)
	assert_gt(poisons.size(), 0)


func test_poison_stacks_accumulate_across_two_zaps() -> void:
	var spell := SpellVenom.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result1 := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	# re-charge the slot so second zap fires
	(result1.mages[0] as MageState).slot_charges["s0_0"] = 99
	(result1.mages[0] as MageState).slot_charges["tip"] = 1
	(result1.mages[0] as MageState).mana_spent = 0
	var result2 := ActionZapWand.new(0, Vector2i(0, 0)).apply(result1, setup).state
	var poisons: Array = (result2.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusPoison)
	assert_eq(poisons.size(), 1, "should have one merged poison entry")
	assert_eq((poisons[0] as StatusPoison).stacks, 4, "poison stacks should accumulate (2+2=4)")


func test_on_hit_effects_not_applied_when_enemy_is_killed() -> void:
	var spell := SpellEmber.create()
	var enemy := EnemyData.new("e1", "Target", 2, Vector2i(1, 1), Color.RED)  # low hp
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	assert_false(result.enemies.has("e1"))


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
	var es1 := EnemyState.new()
	es1.combatant.hp = 20
	s.enemies["e1"] = es1
	var es2 := EnemyState.new()
	es2.combatant.hp = 20
	s.enemies["e2"] = es2
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 99
	ms.slot_charges["tip"] = 1
	s.mages.append(ms)
	s.mana = 10
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(s, setup).state
	assert_eq((result.enemies.get("e1") as EnemyState).combatant.hp, 18, "e1 took lightning damage")
	assert_eq((result.enemies.get("e2") as EnemyState).combatant.hp, 18, "e2 took bounce damage")


# --- cast events ---

func test_cast_events_recorded_on_result() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_gt(result.cast_events.size(), 0)


# --- bone soul harvest ---

func test_bone_kill_refunds_all_zap_mana() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges["s0_0"] = 1
	(state.mages[0] as MageState).slot_charges["tip"] = 1
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_false(result.enemies.has("e1"), "enemy should be dead")
	assert_eq(result.mana, 7, "2 mana spent this zap should be refunded")


func test_bone_refund_keeps_mage_spend_allowance_used() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges["s0_0"] = 1
	(state.mages[0] as MageState).slot_charges["tip"] = 1
	(state.mages[0] as MageState).mana_spent = 2
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq(result.mana, 7, "refund returns to the shared pool")
	assert_eq((result.mages[0] as MageState).mana_spent, 2, "mage allowance is not restored")


func test_bone_no_refund_when_enemy_survives() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges["s0_0"] = 1
	(state.mages[0] as MageState).slot_charges["tip"] = 1
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_true(result.enemies.has("e1"), "enemy should survive")
	assert_eq(result.mana, 5, "no refund when kill does not happen")


func test_bone_multi_kill_does_not_double_refund_mana() -> void:
	var e1 := EnemyData.new("e1", "Target1", 3, Vector2i(1, 1), Color.WHITE)
	var e2 := EnemyData.new("e2", "Target2", 3, Vector2i(1, 1), Color.WHITE)
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = SpellBone.create()
	var tip_spell := SpellData.new("Wide", "W", [], Color.WHITE,
			[Vector2i(0, 0), Vector2i(0, 1)], "", 0, 1)
	tip_spell.spell_type = "tip"
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = tip_spell
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	var setup := BattleSetup.new(
			[e1, e2] as Array[EnemyData],
			[Vector2i(0, 0), Vector2i(0, 1)] as Array[Vector2i],
			[mage] as Array[MageData],
			[wand] as Array[WandData], 10)
	var state := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 1
	ms.slot_charges["tip"] = 1
	state.mages.append(ms)
	state.mana = 8
	for e: EnemyData in setup.enemies:
		var es := EnemyState.new()
		es.combatant.hp = e.max_hp
		state.enemies[e.id] = es
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_false(result.enemies.has("e1"), "e1 should be dead")
	assert_false(result.enemies.has("e2"), "e2 should be dead")
	assert_eq(result.mana, 10, "refund happens only once, capped at max_mana")


func test_parallel_identical_spells_do_not_stack_on_zap() -> void:
	var a := SpellSlotData.new("a", 0, 0, "tip")
	a.spell = SpellBone.create()
	var b := SpellSlotData.new("b", 0, 1, "tip")
	b.spell = SpellBone.create()
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var enemy := EnemyData.new("e1", "Target", 100, Vector2i(1, 1), Color.WHITE)
	var setup := BattleSetup.new([enemy] as Array[EnemyData], [Vector2i(0, 0)] as Array[Vector2i],
			[MageData.new("Mage", 30)] as Array[MageData], [WandData.new([a, b, tip])] as Array[WandData], 10)
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges = {"a": 1, "b": 1, "tip": 1}
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 92, "two separate Bone hits of 4, not 4 · 2²")


# --- helpers for multi-slot wands ---

func _wand_slot(id: String, col: int, row: int, next_id: String, spell: SpellData) -> SpellSlotData:
	var s := SpellSlotData.new(id, col, row, next_id)
	s.spell = spell
	return s


func _multi_setup(slots: Array, enemies: Array, positions: Array) -> BattleSetup:
	var wand_slots: Array[SpellSlotData] = []
	wand_slots.assign(slots + [_wand_slot("tip", 9, 0, "", SpellSingle.create())])
	var typed_enemies: Array[EnemyData] = []
	typed_enemies.assign(enemies)
	var typed_positions: Array[Vector2i] = []
	typed_positions.assign(positions)
	return BattleSetup.new(typed_enemies, typed_positions,
			[MageData.new("Mage", 30)] as Array[MageData], [WandData.new(wand_slots)] as Array[WandData], 10)


func _zap_charged(setup: BattleSetup, charges: Dictionary, target: Vector2i) -> BattleState:
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges = charges.merged({"tip": 1})
	return ActionZapWand.new(0, target).apply(state, setup).state


func _fire_stacks(state: BattleState, eid: String) -> int:
	for status: StatusData in (state.enemies[eid] as EnemyState).combatant.statuses:
		if status is StatusFire:
			return status.stacks
	return 0


func _hp(state: BattleState, eid: String) -> int:
	return (state.enemies[eid] as EnemyState).combatant.hp


# --- zero-cost modifiers ---

func test_zero_cost_modifier_is_active_without_mana() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _multi_setup([_wand_slot("amp", 0, 0, "s", SpellAmplify.create()),
			_wand_slot("s", 1, 0, "tip", _strike_spell())], [enemy], [Vector2i(0, 0)])
	var result := _zap_charged(setup, {"s": 1}, Vector2i(0, 0))
	assert_eq(_hp(result, "e1"), 10, "Amplify doubles 5 without being charged")


func test_zero_cost_modifier_does_not_break_chain() -> void:
	var enemy := EnemyData.new("e1", "Target", 50, Vector2i(1, 1), Color.RED)
	var setup := _multi_setup([_wand_slot("a", 0, 0, "amp", _strike_spell()),
			_wand_slot("amp", 1, 0, "b", SpellAmplify.create()),
			_wand_slot("b", 2, 0, "tip", _strike_spell())], [enemy], [Vector2i(0, 0)])
	var result := _zap_charged(setup, {"a": 1, "b": 1}, Vector2i(0, 0))
	assert_eq(_hp(result, "e1"), 35, "Strike 5 + amplified Strike 10 in one chain")


# --- sunder ---

func test_split_armor_sunder_breaks_armor_and_overflows() -> void:
	assert_eq(ActionZapWand.split_armor(10, 8, 2), Vector2i(0, 3))


func test_split_armor_sunder_partial() -> void:
	assert_eq(ActionZapWand.split_armor(10, 4, 2), Vector2i(2, 0))


func test_split_armor_normal_rate() -> void:
	assert_eq(ActionZapWand.split_armor(3, 5, 1), Vector2i(0, 2))


func test_sunder_zap_strips_double_armor() -> void:
	var strike := _strike_spell()
	strike.damage = 8
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _multi_setup([_wand_slot("su", 0, 0, "s", SpellSunder.create()),
			_wand_slot("s", 1, 0, "tip", strike)], [enemy], [Vector2i(0, 0)])
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).armor = 10
	(state.mages[0] as MageState).slot_charges = {"s": 1, "tip": 1}
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).armor, 0)
	assert_eq(_hp(result, "e1"), 17)


# --- detonate ---

func _target_and_neighbour() -> Array:
	return [[EnemyData.new("e1", "Target", 50, Vector2i(1, 1), Color.RED),
			EnemyData.new("e2", "Near", 50, Vector2i(1, 1), Color.BLUE),
			EnemyData.new("e3", "Far", 50, Vector2i(1, 1), Color.GREEN)],
			[Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 3)]]


func test_detonate_bursts_fire_into_neighbours() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("em", 0, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 1, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"em": 1, "dt": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e1"), 47, "target takes no explosion damage")
	assert_eq(_fire_stacks(result, "e1"), 0, "fire consumed")
	assert_eq(_hp(result, "e2"), 47, "diagonal neighbour takes 3")
	assert_eq(_hp(result, "e3"), 50, "two cells away is untouched")


func test_stacked_detonates_multiply_explosion() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("em", 0, 0, "d1", SpellEmber.create()),
			_wand_slot("d1", 1, 0, "d2", SpellDetonate.create()),
			_wand_slot("d2", 2, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"em": 1, "d1": 1, "d2": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e2"), 38, "3 fire × 2²")


func test_detonate_mid_chain_then_new_fire() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("a", 0, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 1, 0, "b", SpellDetonate.create()),
			_wand_slot("b", 2, 0, "tip", SpellEmber.create())], e[0], e[1])
	var result := _zap_charged(setup, {"a": 1, "dt": 1, "b": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e2"), 47)
	assert_eq(_fire_stacks(result, "e1"), 3, "last Ember re-applies fire")


# Em(A) → Dt → tip
# Em(B) ↗
func test_merged_branches_each_detonate_their_own_fire() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("a", 0, 0, "dt", SpellEmber.create()),
			_wand_slot("b", 0, 1, "dt", SpellEmber.create()),
			_wand_slot("dt", 1, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"a": 1, "b": 1, "dt": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e1"), 44, "two Ember hits")
	assert_eq(_hp(result, "e2"), 44, "Detonate fired once per branch, 3 each")
	assert_eq(_fire_stacks(result, "e1"), 0)


func test_detonate_without_fire_does_nothing() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("dt", 0, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"dt": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e2"), 50)


# --- harmony ---

func test_harmony_zap_applies_combined_blast() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("ha", 0, 0, "em", SpellHarmony.create()),
			_wand_slot("em", 1, 0, "vn", SpellEmber.create()),
			_wand_slot("vn", 2, 0, "tip", SpellVenom.create())], e[0], e[1])
	var result := _zap_charged(setup, {"em": 1, "vn": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e1"), 41, "2·2 + 3 + 2")
	assert_eq(_fire_stacks(result, "e1"), 3)


func test_detonate_damages_neighbouring_obstacle() -> void:
	var target := EnemyData.new("e1", "Target", 50, Vector2i(1, 1), Color.RED)
	var rock := ObstacleData.new("rock_1", "Rock", Vector2i(1, 1), Color.GRAY, 10)
	var setup := _multi_setup([_wand_slot("em", 0, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 1, 0, "tip", SpellDetonate.create())], [target], [Vector2i(2, 3)])
	setup.obstacles.assign([rock])
	setup.obstacle_positions.assign([Vector2i(3, 2)])
	var state := _make_state(setup)
	state.obstacles["rock_1"] = ObstacleState.new()
	(state.obstacles["rock_1"] as ObstacleState).combatant.hp = 10
	(state.mages[0] as MageState).slot_charges = {"em": 1, "dt": 1, "tip": 1}
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(state, setup).state
	assert_eq((result.obstacles["rock_1"] as ObstacleState).combatant.hp, 7)


func test_detonate_kills_weak_neighbour() -> void:
	var e := _target_and_neighbour()
	(e[0][1] as EnemyData).max_hp = 3
	var setup := _multi_setup([_wand_slot("em", 0, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 1, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"em": 1, "dt": 1}, Vector2i(2, 3))
	assert_false(result.enemies.has("e2"), "neighbour killed by the burst")
	assert_true(result.dead_enemies.has("e2"))


# Target is 2 wide at (2,3)-(3,3); a burst reaches cells around both of its cells.
func test_detonate_on_wide_target_reaches_all_sides() -> void:
	var enemies := [EnemyData.new("big", "Big", 50, Vector2i(2, 1), Color.RED),
			EnemyData.new("left", "Left", 50, Vector2i(1, 1), Color.BLUE),
			EnemyData.new("right", "Right", 50, Vector2i(1, 1), Color.BLUE),
			EnemyData.new("far", "Far", 50, Vector2i(1, 1), Color.GREEN)]
	var positions := [Vector2i(2, 3), Vector2i(1, 2), Vector2i(4, 4), Vector2i(5, 3)]
	var setup := _multi_setup([_wand_slot("em", 0, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 1, 0, "tip", SpellDetonate.create())], enemies, positions)
	var result := _zap_charged(setup, {"em": 1, "dt": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "left"), 47)
	assert_eq(_hp(result, "right"), 47)
	assert_eq(_hp(result, "far"), 50)


func test_harmony_blast_with_detonate_bursts_its_fire() -> void:
	var e := _target_and_neighbour()
	var setup := _multi_setup([_wand_slot("ha", 0, 0, "em", SpellHarmony.create()),
			_wand_slot("em", 1, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 2, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"em": 1, "dt": 1}, Vector2i(2, 3))
	assert_eq(_hp(result, "e1"), 43, "2·2 + 3 + 0")
	assert_eq(_hp(result, "e2"), 47, "Ember's 3 fire burst")


func test_harmony_blast_that_kills_does_not_detonate() -> void:
	var e := _target_and_neighbour()
	(e[0][0] as EnemyData).max_hp = 7
	var setup := _multi_setup([_wand_slot("ha", 0, 0, "em", SpellHarmony.create()),
			_wand_slot("em", 1, 0, "dt", SpellEmber.create()),
			_wand_slot("dt", 2, 0, "tip", SpellDetonate.create())], e[0], e[1])
	var result := _zap_charged(setup, {"em": 1, "dt": 1}, Vector2i(2, 3))
	assert_false(result.enemies.has("e1"))
	assert_eq(_hp(result, "e2"), 50, "on-hit effects skip killing blows")
