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


func test_catalyst_not_first_fires_all_three_individually() -> void:
	var events := WandEvaluator.evaluate([
		_projectile("a", 2), _catalyst("fire_catalyst", 1), _projectile("b", 3)
	])
	assert_eq(events.size(), 3)
	for ev in events:
		assert_eq((ev as CastEvent).type, CastEvent.Type.PROJECTILE)


# --- alchemy fusion ---

func test_valid_trio_emits_alchemy_spell() -> void:
	# force_push + frost + frost → Ice Cube
	var events := WandEvaluator.evaluate([
		SpellForcePush.create(), SpellFrost.create(), SpellFrost.create()
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[0] as CastEvent).spell.spell_id, "ice_cube")


func test_fizzle_trio_emits_fizzle_event() -> void:
	# fire_catalyst + frost + venom → Fizzle
	var events := WandEvaluator.evaluate([
		SpellFireCatalyst.create(), SpellFrost.create(), SpellVenom.create()
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.FIZZLE)


func test_backfire_trio_emits_backfire_event() -> void:
	# force_push + lightning + ember → Backfire
	var events := WandEvaluator.evaluate([
		SpellForcePush.create(), SpellLightning.create(), SpellEmber.create()
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.BACKFIRE)
	assert_gt((events[0] as CastEvent).backfire_damage, 0)


func test_unknown_trio_fires_individually() -> void:
	# catalyst with no matching recipe — all three fire as normal projectiles
	var events := WandEvaluator.evaluate([
		_catalyst("fire_catalyst"), _projectile("bone", 2), _projectile("lightning", 4)
	])
	assert_eq(events.size(), 3)
	for ev in events:
		assert_eq((ev as CastEvent).type, CastEvent.Type.PROJECTILE)


func test_four_projectiles_first_three_fuse_fourth_fires_alone() -> void:
	# force_push + frost + frost → Ice Cube, then ember fires alone
	var events := WandEvaluator.evaluate([
		SpellForcePush.create(), SpellFrost.create(), SpellFrost.create(), SpellEmber.create()
	])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).spell.spell_id, "ice_cube")
	assert_eq((events[1] as CastEvent).type, CastEvent.Type.PROJECTILE)


func test_reactant_order_does_not_matter() -> void:
	var events_ab := WandEvaluator.evaluate([
		SpellForcePush.create(), SpellFrost.create(), SpellFrost.create()
	])
	var events_ba := WandEvaluator.evaluate([
		SpellForcePush.create(), SpellFrost.create(), SpellFrost.create()
	])
	assert_eq((events_ab[0] as CastEvent).spell.spell_id,
			(events_ba[0] as CastEvent).spell.spell_id)


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


func test_modifier_before_fizzle_produces_backfire() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}),
		SpellFireCatalyst.create(), SpellFrost.create(), SpellVenom.create()
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.BACKFIRE)


func test_modifier_amplifies_backfire_damage() -> void:
	var base := WandEvaluator.evaluate([
		SpellForcePush.create(), SpellLightning.create(), SpellEmber.create()
	])
	var amplified := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}),
		SpellForcePush.create(), SpellLightning.create(), SpellEmber.create()
	])
	assert_gt((amplified[0] as CastEvent).backfire_damage,
			(base[0] as CastEvent).backfire_damage)


func test_modifier_only_affects_next_spell_not_all() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 3}),
		_projectile("a", 4),
		_projectile("b", 4),
	])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).total_damage, 12)
	assert_eq((events[1] as CastEvent).total_damage, 4)
