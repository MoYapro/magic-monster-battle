class_name ActionZapWand extends BattleAction

var mage_index: int
var target_cell: Vector2i


func _init(p_mage_index: int, p_target_cell: Vector2i) -> void:
	mage_index = p_mage_index
	target_cell = p_target_cell


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	if new_state.mage_frozen[mage_index]:
		return new_state
	if new_state.mage_vine_snare.has(mage_index):
		var snarer_id: String = new_state.mage_vine_snare[mage_index]
		var penalty := ceili(new_state.mage_hp[mage_index] / 2.0)
		new_state.mage_hp[mage_index] = maxi(0, new_state.mage_hp[mage_index] - penalty)
		if new_state.enemy_hp.has(snarer_id):
			var snarer := setup.get_enemy(snarer_id)
			if snarer != null:
				new_state.enemy_hp[snarer_id] = mini(new_state.enemy_hp[snarer_id] + penalty, snarer.max_hp)
		new_state.mage_vine_snare.erase(mage_index)
	if new_state.mage_mana_spent[mage_index] >= setup.mages[mage_index].mana_allowance:
		return new_state
	var wand := setup.wands[mage_index]

	# Hit pattern from the charged tip slot
	var pattern: Array[Vector2i] = [Vector2i(0, 0)]
	var tip_slot := wand.get_tip_slot()
	if tip_slot != null and tip_slot.spell != null:
		var tip_key := "%d/%s" % [mage_index, tip_slot.id]
		var tip_charges: int = new_state.slot_charges.get(tip_key, 0)
		if tip_charges >= tip_slot.spell.mana_cost and not tip_slot.spell.hit_pattern.is_empty():
			pattern = tip_slot.spell.hit_pattern

	# Collect charged body spells sorted left-to-right (col, then row)
	var body_slots: Array[SpellSlotData] = []
	for slot: SpellSlotData in wand.slots:
		if slot.is_tip or slot.spell == null:
			continue
		var key := "%d/%s" % [mage_index, slot.id]
		if new_state.webbed_slots.has(key):
			continue
		if new_state.slot_charges.get(key, 0) < slot.spell.mana_cost:
			continue
		body_slots.append(slot)
	body_slots.sort_custom(func(a: SpellSlotData, b: SpellSlotData) -> bool:
		return a.grid_col < b.grid_col if a.grid_col != b.grid_col else a.grid_row < b.grid_row)

	var body_spells: Array[SpellData] = []
	for slot: SpellSlotData in body_slots:
		body_spells.append(slot.spell)

	# Two-pass alchemy + modifier resolution
	var cast_events := WandEvaluator.evaluate(body_spells)

	for ev: CastEvent in cast_events:
		match ev.type:
			CastEvent.Type.PROJECTILE:
				_apply_projectile(new_state, setup, ev, pattern)
			CastEvent.Type.BACKFIRE:
				_apply_backfire(new_state, mage_index, ev)
			CastEvent.Type.FIZZLE:
				pass  # mana consumed, nothing fires

	new_state.cast_events = cast_events

	for slot: SpellSlotData in wand.slots:
		new_state.slot_charges.erase("%d/%s" % [mage_index, slot.id])

	return new_state


func _apply_projectile(
		state: BattleState, setup: BattleSetup, ev: CastEvent, pattern: Array[Vector2i]) -> void:
	var blocked_this_zap: Dictionary = {}
	for cell: Vector2i in EnemyGrid.get_hit_cells(target_cell, pattern):
		var eid: String = setup.get_occupant_at(cell, state)
		if eid.is_empty() or not state.enemy_hp.has(eid):
			continue
		if blocked_this_zap.has(eid):
			continue
		if state.enemy_block.get(eid, 0) > 0:
			state.enemy_block[eid] -= 1
			if state.enemy_block[eid] <= 0:
				state.enemy_block.erase(eid)
			blocked_this_zap[eid] = true
			continue
		var remaining := ev.total_damage
		if state.enemy_armor.has(eid):
			var absorbed := mini(state.enemy_armor[eid], remaining)
			state.enemy_armor[eid] -= absorbed
			remaining -= absorbed
			if state.enemy_armor[eid] <= 0:
				state.enemy_armor.erase(eid)
		state.enemy_hp[eid] -= remaining
		if state.enemy_hp[eid] <= 0:
			state.kill_enemy(eid)
		else:
			_apply_on_hit_effects(state, setup, eid, ev.on_hit_effects)


func _apply_on_hit_effects(
		state: BattleState, setup: BattleSetup, eid: String, effects: Array[Dictionary]) -> void:
	for effect: Dictionary in effects:
		match effect.get("type", ""):
			"fire":
				state.add_fire_stacks_to_enemy(eid, effect.get("stacks", 1))
			"wet":
				state.enemy_wet[eid] = (state.enemy_wet.get(eid, 0) as int) + effect.get("stacks", 1)
			"poison":
				var enemy := setup.get_enemy(eid)
				var immune := enemy != null and enemy.traits.any(
						func(t: MonsterTraitData) -> bool: return t is MonsterTraitPoisonImmunity)
				if not immune:
					state.enemy_poison[eid] = (state.enemy_poison.get(eid, 0) as int) \
							+ effect.get("stacks", 1)
			"freeze":
				state.enemy_frozen[eid] = true
			"stun":
				state.enemy_stunned[eid] = effect.get("turns", 1)
			"blind":
				state.enemy_blind[eid] = effect.get("turns", 1)
			"cleanse_poison":
				state.enemy_poison.erase(eid)


func _apply_backfire(state: BattleState, mage_idx: int, ev: CastEvent) -> void:
	state.mage_hp[mage_idx] = max(0, state.mage_hp[mage_idx] - ev.backfire_damage)
	for effect: Dictionary in ev.backfire_effects:
		match effect.get("type", ""):
			"stun":
				state.mage_frozen[mage_idx] = true
			"fire":
				state.add_fire_stacks_to_mage(mage_idx, effect.get("stacks", 1))
			"poison":
				state.mage_poison[mage_idx] += effect.get("stacks", 1)
