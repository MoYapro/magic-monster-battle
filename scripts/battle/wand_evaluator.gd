class_name WandEvaluator

# Evaluates a wand's body spell sequence at cast time.
#
# Modifiers apply their effect to the immediately next spell.
#
# Alchemy fusion happens at wand-build time (loot screen), not here.
# Catalyst spells that were not fused fire as plain projectiles.
#
# Input:  Array[SpellData] — one chain of charged body spells, root first (no tip spells).
# Output: Array[CastEvent] — resolved events to apply to the battle.


# Splits charged body slots into chains along next_id. A chain starts at a charged
# slot with no charged predecessor and ends at the tip or the first uncharged slot.
# Branches merging into a shared segment each fire that segment as part of their chain.
static func charged_chains(wand: WandData, charged_ids: Dictionary) -> Array[Array]:
	var chains: Array[Array] = []
	for root: SpellSlotData in _chain_roots(wand, charged_ids):
		var chain: Array[SpellData] = []
		var slot := root
		while slot != null and charged_ids.has(slot.id):
			chain.append(slot.spell)
			slot = wand.get_slot(slot.next_id)
		chains.append(chain)
	return chains


static func _chain_roots(wand: WandData, charged_ids: Dictionary) -> Array[SpellSlotData]:
	var fed: Dictionary = {}
	for slot: SpellSlotData in wand.slots:
		if charged_ids.has(slot.id):
			fed[slot.next_id] = true
	var roots: Array[SpellSlotData] = []
	for slot: SpellSlotData in wand.slots:
		if charged_ids.has(slot.id) and not fed.has(slot.id):
			roots.append(slot)
	roots.sort_custom(func(a: SpellSlotData, b: SpellSlotData) -> bool:
		return a.grid_col < b.grid_col if a.grid_col != b.grid_col else a.grid_row < b.grid_row)
	return roots


static func evaluate_chains(chains: Array[Array], zap_mana_cost: int = 0) -> Array[CastEvent]:
	var events: Array[CastEvent] = []
	for chain: Array in chains:
		var spells: Array[SpellData] = []
		spells.assign(chain)
		events.append_array(evaluate(spells, zap_mana_cost))
	return events


static func evaluate(spells: Array[SpellData], zap_mana_cost: int = 0) -> Array[CastEvent]:
	var events: Array[CastEvent] = []
	var pending_mods: Array[Dictionary] = []
	var last_spell: SpellData = null
	var last_count := 0
	var last_pre_mods: Array[Dictionary] = []
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
			last_spell = spell
			last_count = count
			last_pre_mods = pending_mods.duplicate()
			events.append(_make_projectile(spell, pending_mods, count, zap_mana_cost))
			pending_mods = []
			i += count
	# Trailing modifiers (after the last spell group) apply back to that group
	if not pending_mods.is_empty() and last_spell != null:
		var combined: Array[Dictionary] = last_pre_mods + pending_mods
		events[events.size() - 1] = _make_projectile(last_spell, combined, last_count, zap_mana_cost)
	return events


static func _make_projectile(spell: SpellData, mods: Array[Dictionary], count: int = 1, zap_mana_cost: int = 0) -> CastEvent:
	var ev := CastEvent.new()
	ev.type = CastEvent.Type.PROJECTILE
	ev.spell = spell
	ev.total_damage = stack_amount(spell.damage, count)
	ev.on_hit_effects = spell.on_hit_effects.duplicate(true)
	ev.on_kill_effects = spell.on_kill_effects.duplicate(true)
	ev.mana_refund = 0
	ev.zap_mana_cost = zap_mana_cost
	for mod in mods:
		_apply_mod(ev, mod)
	var resolved_effects: Array[Dictionary] = []
	for effect: Dictionary in ev.on_hit_effects:
		var effect_type: String = effect.get("type", "")
		if effect.has("distance_per_cast"):
			if ev.corrupted:
				pass  # push consumed; no damage since collision damage is unknown at this stage
			else:
				effect["distance"] = count * effect.get("distance_per_cast", 1)
				effect["damage"] = ev.total_damage
				effect.erase("distance_per_cast")
				resolved_effects.append(effect)
		elif effect_type == "bounce":
			var per_cast: int = effect.get("per_cast", 1)
			if ev.corrupted:
				ev.total_damage += per_cast * count * ev.total_damage
			else:
				ev.bounces += per_cast * count
		elif effect_type == "push":
			if ev.corrupted:
				ev.total_damage += effect.get("damage", 0)
			else:
				resolved_effects.append(effect)
		elif effect_type == "shield" and count > 1:
			effect["amount"] = stack_amount(effect.get("amount", 10), count)
			resolved_effects.append(effect)
		else:
			resolved_effects.append(effect)
	ev.on_hit_effects = resolved_effects
	return ev


# Consecutive identical spells scale quadratically: base * count².
static func stack_amount(base: int, count: int) -> int:
	return base * count * count


static func _apply_mod(ev: CastEvent, mod: Dictionary) -> void:
	match mod.get("type", ""):
		"damage_mult":
			ev.total_damage = roundi(ev.total_damage * float(mod.get("factor", 1.0)))
		"add_on_hit":
			ev.on_hit_effects.append(mod.get("effect", {}))
		"mana_refund":
			ev.mana_refund += mod.get("amount", 0)
		"reactive":
			ev.reactive = true
		"distillation":
			var bonus := ev.total_damage
			for effect: Dictionary in ev.on_hit_effects:
				if effect.get("stacks_from_damage", false):
					effect["stacks"] = bonus * 2
					effect.erase("stacks_from_damage")
				elif effect.has("stacks"):
					effect["stacks"] = effect.get("stacks", 0) + bonus
				elif effect.get("type", "") == "bounce":
					effect["per_cast"] = effect.get("per_cast", 1) + bonus
				elif effect.has("distance_per_cast"):
					effect["distance_per_cast"] = effect.get("distance_per_cast", 1) + bonus
			ev.total_damage = 0
		"corrupted":
			ev.corrupted = true
			var bonus := 0
			var kept: Array[Dictionary] = []
			for effect: Dictionary in ev.on_hit_effects:
				if effect.get("stacks_from_damage", false):
					bonus += ev.total_damage
				elif effect.has("stacks"):
					bonus += effect.get("stacks", 0)
				else:
					kept.append(effect)
			ev.total_damage += bonus
			ev.on_hit_effects = kept
