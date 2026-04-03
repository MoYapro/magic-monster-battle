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
	var i := 0
	while i < spells.size():
		var spell: SpellData = spells[i]
		if spell.spell_type == "modifier":
			pending_mods.append(spell.modifier_effect)
			i += 1
		else:
			var count := 1
			while i + count < spells.size() and spells[i + count].spell_id == spell.spell_id:
				count += 1
			events.append(_make_projectile(spell, pending_mods, count))
			pending_mods = []
			i += count
	return events


static func _make_projectile(spell: SpellData, mods: Array[Dictionary], count: int = 1) -> CastEvent:
	var ev := CastEvent.new()
	ev.type = CastEvent.Type.PROJECTILE
	ev.spell = spell
	var total := 1
	for _k in count:
		total *= spell.damage
	ev.total_damage = total
	ev.on_hit_effects = spell.on_hit_effects.duplicate(true)
	ev.mana_refund = 0
	for mod in mods:
		_apply_mod(ev, mod)
	var resolved_effects: Array[Dictionary] = []
	for effect: Dictionary in ev.on_hit_effects:
		var effect_type: String = effect.get("type", "")
		if effect.has("distance_per_cast"):
			effect["distance"] = count * effect.get("distance_per_cast", 1)
			effect["damage"] = ev.total_damage
			effect.erase("distance_per_cast")
			resolved_effects.append(effect)
		elif effect_type == "bounce":
			var per_cast: int = effect.get("per_cast", 1)
			ev.bounces += per_cast * count
		else:
			resolved_effects.append(effect)
	ev.on_hit_effects = resolved_effects
	return ev


static func _apply_mod(ev: CastEvent, mod: Dictionary) -> void:
	match mod.get("type", ""):
		"damage_mult":
			ev.total_damage = roundi(ev.total_damage * float(mod.get("factor", 1.0)))
		"add_on_hit":
			ev.on_hit_effects.append(mod.get("effect", {}))
		"mana_refund":
			ev.mana_refund += mod.get("amount", 0)
