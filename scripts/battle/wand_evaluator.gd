class_name WandEvaluator

# Evaluates a wand's body spell sequence at cast time.
#
# Modifiers apply their effect to the immediately next spell.
#
# Alchemy fusion happens at wand-build time (loot screen), not here.
# Catalyst spells that were not fused fire as plain projectiles.
#
# Input:  Array[SpellData] — charged body spells in column order (no tip spells).
# Output: Array[CastEvent] — resolved events to apply to the battle.


static func evaluate(spells: Array[SpellData]) -> Array[CastEvent]:
	var events: Array[CastEvent] = []
	var pending_mods: Array[Dictionary] = []
	for spell: SpellData in spells:
		if spell.spell_type == "modifier":
			pending_mods.append(spell.modifier_effect)
		else:
			events.append(_make_projectile(spell, pending_mods))
			pending_mods = []
	return events


static func _make_projectile(spell: SpellData, mods: Array[Dictionary]) -> CastEvent:
	var ev := CastEvent.new()
	ev.type = CastEvent.Type.PROJECTILE
	ev.spell = spell
	ev.total_damage = spell.damage
	ev.on_hit_effects = spell.on_hit_effects.duplicate()
	ev.mana_refund = 0
	for mod in mods:
		_apply_mod(ev, mod)
	return ev


static func _apply_mod(ev: CastEvent, mod: Dictionary) -> void:
	match mod.get("type", ""):
		"damage_mult":
			ev.total_damage = roundi(ev.total_damage * float(mod.get("factor", 1.0)))
		"add_on_hit":
			ev.on_hit_effects.append(mod.get("effect", {}))
		"mana_refund":
			ev.mana_refund += mod.get("amount", 0)
