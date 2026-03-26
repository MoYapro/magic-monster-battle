class_name WandEvaluator

# Two-pass evaluation of a wand's body spell sequence at cast time.
#
# Pass 1 — Alchemy Fusion (left-to-right):
#   A catalyst spell followed by two projectile/catalyst spells forms a trio.
#   The trio is replaced by the AlchemyTable result. Scanning continues after.
#   If the catalyst is not in the leading position the three spells fire individually.
#
# Pass 2 — Modifier Application (left-to-right):
#   Each modifier applies its effect to the immediately next spell/result.
#   Modifier before fizzle → converts to backfire.
#   Modifier before backfire → amplifies it.
#
# Input:  Array[SpellData] — charged body spells in column order (no tip spells).
# Output: Array[CastEvent] — resolved events to apply to the battle.


static func evaluate(spells: Array[SpellData]) -> Array[CastEvent]:
	var fused := _pass1_fuse(spells)
	return _pass2_modifiers(fused)


# --- Pass 1 ---

static func _pass1_fuse(spells: Array[SpellData]) -> Array:
	var result: Array = []
	var i := 0
	while i < spells.size():
		var spell: SpellData = spells[i]
		if spell.spell_type == "catalyst" \
				and i + 2 < spells.size() \
				and _is_projectile_like(spells[i + 1]) \
				and _is_projectile_like(spells[i + 2]):
			var alchemy_result := AlchemyTable.lookup(spell, spells[i + 1], spells[i + 2])
			if alchemy_result != null:
				result.append(alchemy_result)
				i += 3
			else:
				# No recipe — all three fire individually
				result.append(spell)
				result.append(spells[i + 1])
				result.append(spells[i + 2])
				i += 3
		else:
			result.append(spell)
			i += 1
	return result


static func _is_projectile_like(spell: SpellData) -> bool:
	return spell.spell_type == "projectile" or spell.spell_type == "catalyst"


# --- Pass 2 ---

static func _pass2_modifiers(items: Array) -> Array[CastEvent]:
	var events: Array[CastEvent] = []
	var pending_mods: Array[Dictionary] = []
	for item in items:
		if item is SpellData:
			var spell := item as SpellData
			if spell.spell_type == "modifier":
				pending_mods.append(spell.modifier_effect)
			else:
				# projectile or catalyst firing as standalone
				events.append(_make_projectile(spell, pending_mods))
				pending_mods = []
		elif item is AlchemyResult:
			var result := item as AlchemyResult
			match result.outcome:
				AlchemyResult.Outcome.FIZZLE:
					if pending_mods.is_empty():
						events.append(_make_fizzle())
					else:
						# modifier wasted on a fizzle → backfire instead
						events.append(_make_backfire(2, [], pending_mods))
					pending_mods = []
				AlchemyResult.Outcome.BACKFIRE:
					events.append(_make_backfire(
							result.backfire_damage, result.backfire_effects, pending_mods))
					pending_mods = []
				AlchemyResult.Outcome.SUCCESS:
					events.append(_make_projectile(result.spell, pending_mods))
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
		_apply_mod_to_projectile(ev, mod)
	return ev


static func _apply_mod_to_projectile(ev: CastEvent, mod: Dictionary) -> void:
	match mod.get("type", ""):
		"damage_mult":
			ev.total_damage = roundi(ev.total_damage * float(mod.get("factor", 1.0)))
		"add_on_hit":
			ev.on_hit_effects.append(mod.get("effect", {}))
		"mana_refund":
			ev.mana_refund += mod.get("amount", 0)


static func _make_fizzle() -> CastEvent:
	var ev := CastEvent.new()
	ev.type = CastEvent.Type.FIZZLE
	return ev


static func _make_backfire(
		base_dmg: int, base_effects: Array[Dictionary], mods: Array[Dictionary]) -> CastEvent:
	var ev := CastEvent.new()
	ev.type = CastEvent.Type.BACKFIRE
	ev.backfire_damage = base_dmg
	ev.backfire_effects = base_effects.duplicate()
	for mod in mods:
		match mod.get("type", ""):
			"damage_mult":
				ev.backfire_damage = roundi(ev.backfire_damage * float(mod.get("factor", 1.0)))
			"add_on_hit":
				ev.backfire_effects.append(mod.get("effect", {}))
	return ev
