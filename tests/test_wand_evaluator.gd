extends GutTest


# --- helpers ---

func _projectile(id: String, damage: int, effects: Array[Dictionary] = []) -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", damage, 1)
	s.spell_id = id
	s.spell_type = "projectile"
	s.on_hit_effects = effects
	return s


func _catalyst(id: String, damage: int = 1) -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", damage, 1)
	s.spell_id = id
	s.spell_type = "catalyst"
	return s


func _modifier(effect: Dictionary) -> SpellData:
	var s := SpellData.new("mod", "M", [], Color.WHITE, [], "", 0, 1)
	s.spell_id = "mod"
	s.spell_type = "modifier"
	s.modifier_effect = effect
	return s


# --- basic firing ---

func test_single_projectile_emits_one_projectile_event() -> void:
	var events := WandEvaluator.evaluate([_projectile("p", 5)])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[0] as CastEvent).total_damage, 5)


func test_two_projectiles_emit_two_events() -> void:
	var events := WandEvaluator.evaluate([_projectile("a", 3), _projectile("b", 4)])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[1] as CastEvent).type, CastEvent.Type.PROJECTILE)


func test_solo_catalyst_fires_as_projectile() -> void:
	var events := WandEvaluator.evaluate([_catalyst("cat", 3)])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[0] as CastEvent).total_damage, 3)


func test_catalyst_with_reactants_fires_all_individually() -> void:
	# Fusion happens at loot-screen time, not at cast time.
	# A catalyst sitting next to reactants in the wand fires as three separate projectiles.
	var events := WandEvaluator.evaluate([
		_catalyst("force_push", 3), _projectile("frost", 2), _projectile("fire", 2)
	])
	assert_eq(events.size(), 3)
	for ev in events:
		assert_eq((ev as CastEvent).type, CastEvent.Type.PROJECTILE)


# --- modifiers ---

func test_modifier_doubles_damage_of_next_projectile() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}), _projectile("p", 5)
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 10)


func test_modifier_adds_on_hit_effect_to_next_projectile() -> void:
	var extra := {"type": "fire", "stacks": 3}
	var events := WandEvaluator.evaluate([
		_modifier({"type": "add_on_hit", "effect": extra}), _projectile("p", 5)
	])
	assert_eq(events.size(), 1)
	assert_true((events[0] as CastEvent).on_hit_effects.has(extra))


func test_modifier_only_affects_next_spell_not_all() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 3}),
		_projectile("a", 4),
		_projectile("b", 4),
	])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).total_damage, 12)
	assert_eq((events[1] as CastEvent).total_damage, 4)


func test_modifier_applies_to_catalyst_firing_as_projectile() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}), _catalyst("cat", 3)
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 6)


# --- multi-cast (consecutive identical spells) ---

func test_two_identical_spells_merge_into_one_event() -> void:
	# 5 * 2² = 20
	var events := WandEvaluator.evaluate([_projectile("frost", 5), _projectile("frost", 5)])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 20)


func test_three_identical_spells_scale_quadratically() -> void:
	# 3 * 3² = 27
	var events := WandEvaluator.evaluate([
		_projectile("frost", 3), _projectile("frost", 3), _projectile("frost", 3)
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 27)


func test_five_identical_spells_scale_quadratically() -> void:
	# 4 * 5² = 100
	var spells: Array[SpellData] = []
	for _i in 5:
		spells.append(_projectile("bone", 4))
	var events := WandEvaluator.evaluate(spells)
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 100)


func test_different_spells_do_not_merge() -> void:
	var events := WandEvaluator.evaluate([_projectile("frost", 5), _projectile("fire", 5)])
	assert_eq(events.size(), 2)


func test_modifier_applies_once_to_merged_multi_cast() -> void:
	# 3 * 3² = 27, then damage_mult x2 → 54
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}),
		_projectile("frost", 3), _projectile("frost", 3), _projectile("frost", 3),
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 54)


func test_two_shields_multiply_amount() -> void:
	var shield := SpellShield.create()
	var events := WandEvaluator.evaluate([shield, shield])
	assert_eq(events.size(), 1)
	var amount: int = (events[0] as CastEvent).on_hit_effects[0].get("amount", 0)
	assert_eq(amount, 40)  # 10 * 2²


func test_three_shields_scale_amount_quadratically() -> void:
	var shield := SpellShield.create()
	var events := WandEvaluator.evaluate([shield, shield, shield])
	assert_eq(events.size(), 1)
	var amount: int = (events[0] as CastEvent).on_hit_effects[0].get("amount", 0)
	assert_eq(amount, 90)  # 10 * 3²


func test_single_shield_amount_unchanged() -> void:
	var shield := SpellShield.create()
	var events := WandEvaluator.evaluate([shield])
	assert_eq(events.size(), 1)
	var amount: int = (events[0] as CastEvent).on_hit_effects[0].get("amount", 0)
	assert_eq(amount, 10)


func test_modifier_between_identical_spells_breaks_merge() -> void:
	# frost, modifier, frost → two separate events; modifier applies only to second frost
	var events := WandEvaluator.evaluate([
		_projectile("frost", 5),
		_modifier({"type": "damage_mult", "factor": 3}),
		_projectile("frost", 5),
	])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).total_damage, 5)
	assert_eq((events[1] as CastEvent).total_damage, 15)


# --- charged chains (stacking follows next_id, parallel slots don't stack) ---

func _slot(id: String, col: int, row: int, next_id: String, spell: SpellData) -> SpellSlotData:
	var s := SpellSlotData.new(id, col, row, next_id)
	s.spell = spell
	return s


func _charged(ids: Array) -> Dictionary:
	var d: Dictionary = {}
	for id: String in ids:
		d[id] = true
	return d


func _total_damage(events: Array[CastEvent]) -> int:
	var total := 0
	for ev: CastEvent in events:
		total += ev.total_damage
	return total


# Em → Em ↘
# Em → Em → tip
func _two_parallel_ember_pairs() -> WandData:
	return WandData.new([
		_slot("a0", 0, 0, "a1", SpellEmber.create()),
		_slot("b0", 0, 1, "b1", SpellEmber.create()),
		_slot("a1", 1, 0, "tip", SpellEmber.create()),
		_slot("b1", 1, 1, "tip", SpellEmber.create()),
		_slot("tip", 2, 1, "", SpellSingle.create()),
	])


# Vn → Vn → tip
# Lt ↗
# __ ↗
func _venom_lightning_merge() -> WandData:
	return WandData.new([
		_slot("vn0", 0, 0, "vn1", SpellVenom.create()),
		_slot("lt", 0, 1, "vn1", SpellLightning.create()),
		_slot("empty", 0, 2, "vn1", null),
		_slot("vn1", 1, 0, "tip", SpellVenom.create()),
		_slot("tip", 2, 0, "", null),
	])


# Amp → Fr → Fr → tip
# Fr  ↗
func _frost_merge() -> WandData:
	return WandData.new([
		_slot("amp", 0, 0, "fa", SpellAmplify.create()),
		_slot("fc", 0, 1, "fa", SpellFrost.create()),
		_slot("fa", 1, 0, "fb", SpellFrost.create()),
		_slot("fb", 2, 0, "tip", SpellFrost.create()),
		_slot("tip", 3, 1, "", SpellBoltSW.create()),
	])


func test_parallel_pairs_stack_only_within_their_chain() -> void:
	var chains := WandEvaluator.charged_chains(_two_parallel_ember_pairs(), _charged(["a0", "b0", "a1", "b1"]))
	assert_eq(chains.size(), 2)
	var events := WandEvaluator.evaluate_chains(chains)
	assert_eq(events.size(), 2)
	assert_eq(_total_damage(events), 24)  # 2 × (3 · 2²)


func test_merging_branch_with_same_spell_stacks() -> void:
	var events := WandEvaluator.evaluate_chains(
			WandEvaluator.charged_chains(_venom_lightning_merge(), _charged(["vn0", "vn1"])))
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 8)  # 2 · 2²


func test_alternate_branch_swaps_element() -> void:
	var events := WandEvaluator.evaluate_chains(
			WandEvaluator.charged_chains(_venom_lightning_merge(), _charged(["lt", "vn1"])))
	assert_eq(events.size(), 2)
	assert_eq(events[0].spell.spell_id, "lightning")
	assert_eq(events[1].spell.spell_id, "venom")


func test_both_branches_fire_shared_segment_each() -> void:
	var chains := WandEvaluator.charged_chains(_venom_lightning_merge(), _charged(["vn0", "lt", "vn1"]))
	assert_eq(chains.size(), 2)
	assert_eq(_total_damage(WandEvaluator.evaluate_chains(chains)), 12)  # Vn×2 = 8, Lt 2 + Vn 2


func test_three_frosts_in_chain_stack() -> void:
	var events := WandEvaluator.evaluate_chains(
			WandEvaluator.charged_chains(_frost_merge(), _charged(["fc", "fa", "fb"])))
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 18)  # 2 · 3²


func test_amp_branch_amplifies_frost_pair() -> void:
	var events := WandEvaluator.evaluate_chains(
			WandEvaluator.charged_chains(_frost_merge(), _charged(["amp", "fa", "fb"])))
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 16)  # (2 · 2²) × 2


func test_all_frost_branches_charged_fire_both_paths() -> void:
	var events := WandEvaluator.evaluate_chains(
			WandEvaluator.charged_chains(_frost_merge(), _charged(["amp", "fc", "fa", "fb"])))
	assert_eq(_total_damage(events), 34)  # 16 + 18


func test_uncharged_slot_breaks_stack() -> void:
	var chains := WandEvaluator.charged_chains(_frost_merge(), _charged(["fc", "fb"]))
	assert_eq(chains.size(), 2)
	assert_eq(_total_damage(WandEvaluator.evaluate_chains(chains)), 4)  # 2 + 2


# --- modifier-only chains ---

func test_chain_of_only_modifiers_yields_no_event() -> void:
	var events := WandEvaluator.evaluate([SpellAmplify.create(), SpellSunder.create()] as Array[SpellData])
	assert_eq(events.size(), 0)


# --- sunder ---

func test_sunder_flags_next_projectile() -> void:
	var events := WandEvaluator.evaluate([SpellSunder.create(), SpellEmber.create()] as Array[SpellData])
	assert_true(events[0].sunder)


# --- harmony ---

func _eval(spells: Array) -> Array[CastEvent]:
	var chain: Array[SpellData] = []
	chain.assign(spells)
	return WandEvaluator.evaluate(chain)


func _effect_stacks(ev: CastEvent, type: String) -> int:
	for effect: Dictionary in ev.on_hit_effects:
		if effect.get("type", "") == type:
			return effect.get("stacks", 0)
	return -1


func test_harmony_counts_different_spells() -> void:
	var events := _eval([SpellHarmony.create(), SpellEmber.create(), SpellVenom.create(), SpellLightning.create()])
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 13)  # 2·3 + (3 + 2 + 2)
	assert_eq(events[0].spell.spell_id, "harmony")


func test_harmony_effects_use_single_cast_values() -> void:
	var ev: CastEvent = _eval([SpellHarmony.create(), SpellEmber.create(), SpellVenom.create(), SpellLightning.create()])[0]
	assert_eq(_effect_stacks(ev, "fire"), 3)
	assert_eq(_effect_stacks(ev, "poison"), 2)
	assert_eq(ev.bounces, 1)


func test_harmony_ignores_duplicates() -> void:
	var events := _eval([SpellHarmony.create(), SpellEmber.create(), SpellEmber.create()])
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 5)  # 2·1 + 3, no stacking
	assert_eq(_effect_stacks(events[0], "fire"), 3)


func test_modifier_before_harmony_applies_to_blast() -> void:
	var events := _eval([SpellAmplify.create(), SpellHarmony.create(), SpellEmber.create(), SpellVenom.create()])
	assert_eq(events[0].total_damage, 18)  # (2·2 + 5) × 2


func test_modifier_after_harmony_applies_to_blast() -> void:
	var events := _eval([SpellHarmony.create(), SpellEmber.create(), SpellAmplify.create(), SpellVenom.create()])
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 18)


func test_harmony_keeps_spells_before_it_separate() -> void:
	var events := _eval([SpellBone.create(), SpellHarmony.create(), SpellEmber.create()])
	assert_eq(events.size(), 2)
	assert_eq(events[0].total_damage, 4)
	assert_eq(events[1].total_damage, 5)


func test_harmony_carries_on_kill_effects_once() -> void:
	var ev: CastEvent = _eval([SpellHarmony.create(), SpellBone.create(), SpellBone.create()])[0]
	assert_eq(ev.on_kill_effects.size(), 1)


func test_harmony_without_projectile_after_does_nothing() -> void:
	assert_eq(_eval([SpellHarmony.create()]).size(), 0)
	assert_eq(_eval([SpellHarmony.create(), SpellAmplify.create()]).size(), 0)


func test_trailing_harmony_lets_trailing_mods_apply_back() -> void:
	var events := _eval([SpellEmber.create(), SpellHarmony.create(), SpellAmplify.create()])
	assert_eq(events.size(), 1)
	assert_eq(events[0].total_damage, 6)


# --- detonate ---

func _detonate_mult(ev: CastEvent) -> int:
	for effect: Dictionary in ev.on_hit_effects:
		if effect.get("type", "") == "detonate":
			return effect.get("mult", 0)
	return 0


func test_single_detonate_has_mult_one() -> void:
	assert_eq(_detonate_mult(_eval([SpellDetonate.create()])[0]), 1)


func test_stacked_detonates_scale_quadratically() -> void:
	assert_eq(_detonate_mult(_eval([SpellDetonate.create(), SpellDetonate.create()])[0]), 4)


# Ha → Vn → Em → tip
#      Ha ↗
func test_harmony_in_each_branch_counts_its_own_spells() -> void:
	var wand := WandData.new([
		_slot("ha1", 0, 0, "vn", SpellHarmony.create()),
		_slot("vn", 1, 0, "em", SpellVenom.create()),
		_slot("ha2", 1, 1, "em", SpellHarmony.create()),
		_slot("em", 2, 0, "tip", SpellEmber.create()),
		_slot("tip", 3, 0, "", SpellSingle.create()),
	])
	var events := WandEvaluator.evaluate_chains(
			WandEvaluator.charged_chains(wand, _charged(["ha1", "vn", "ha2", "em"])))
	assert_eq(events.size(), 2)
	assert_eq(events[0].total_damage, 9)  # 2·2 + (2 + 3)
	assert_eq(events[1].total_damage, 5)  # 2·1 + 3
