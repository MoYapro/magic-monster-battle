class_name ActionZapWand extends BattleAction

var mage_index: int
var target_cell: Vector2i
var target_mage_index: int = -1  # >= 0 when targeting a mage instead of an enemy cell


func _init(p_mage_index: int, p_target_cell: Vector2i, p_target_mage: int = -1) -> void:
	mage_index = p_mage_index
	target_cell = p_target_cell
	target_mage_index = p_target_mage


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	if new_state.mage_statuses[mage_index].any(func(s: StatusData) -> bool: return s.blocks_action()):
		return new_state
	var zap_target := StatusTarget.for_mage(new_state, mage_index)
	for status: StatusData in new_state.mage_statuses[mage_index].duplicate():
		status.on_zap(zap_target, setup)
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
				if target_mage_index >= 0:
					_apply_projectile_to_mage(new_state, ev, target_mage_index, pattern)
				else:
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
			_apply_on_hit_effects(state, setup, eid, ev.on_hit_effects, ev.total_damage)


func _apply_on_hit_effects(
		state: BattleState, setup: BattleSetup, eid: String,
		effects: Array[Dictionary], total_damage: int) -> void:
	for effect: Dictionary in effects:
		var stacks: int = total_damage if effect.get("stacks_from_damage", false) \
				else effect.get("stacks", 1)
		match effect.get("type", ""):
			"fire":
				state.add_enemy_status(eid, StatusFire.new(stacks))
			"wet":
				state.add_enemy_status(eid, StatusWet.new(stacks))
			"poison":
				var enemy := setup.get_enemy(eid)
				var immune := enemy != null and enemy.traits.any(
						func(t: MonsterTraitData) -> bool: return t is MonsterTraitPoisonImmunity)
				if not immune:
					state.add_enemy_status(eid, StatusPoison.new(stacks))
			"freeze":
				state.add_enemy_status(eid, StatusFrozen.new())
			"stun":
				state.enemy_stunned[eid] = effect.get("turns", 1)
			"blind":
				state.enemy_blind[eid] = effect.get("turns", 1)
			"push":
				_push_enemy(state, setup, eid,
						effect.get("distance", 1), effect.get("damage", 0))
			"cleanse_poison":
				if state.enemy_statuses.has(eid):
					(state.enemy_statuses[eid] as Array).assign(
						(state.enemy_statuses[eid] as Array).filter(
							func(s: StatusData) -> bool: return not (s is StatusPoison)))


func _apply_projectile_to_mage(
		state: BattleState, ev: CastEvent, target_idx: int,
		pattern: Array[Vector2i] = [Vector2i(0, 0)]) -> void:
	var hit_indices: Dictionary = {}
	for offset: Vector2i in pattern:
		hit_indices[target_idx + offset.y] = true
	for idx: int in hit_indices:
		if idx < 0 or idx >= state.mage_hp.size() or state.mage_hp[idx] <= 0:
			continue
		var remaining := ev.total_damage
		if remaining > 0 and state.mage_shield[idx] > 0:
			var absorbed := mini(state.mage_shield[idx], remaining)
			state.mage_shield[idx] -= absorbed
			remaining -= absorbed
		if remaining > 0:
			state.mage_hp[idx] = max(0, state.mage_hp[idx] - remaining)
		if state.mage_hp[idx] > 0:
			_apply_on_hit_effects_to_mage(state, idx, ev.on_hit_effects, ev.total_damage)


func _apply_on_hit_effects_to_mage(
		state: BattleState, target_idx: int,
		effects: Array[Dictionary], total_damage: int) -> void:
	for effect: Dictionary in effects:
		var stacks: int = total_damage if effect.get("stacks_from_damage", false) \
				else effect.get("stacks", 1)
		match effect.get("type", ""):
			"fire":
				state.add_mage_status(target_idx, StatusFire.new(stacks))
			"wet":
				state.add_mage_status(target_idx, StatusWet.new(stacks))
			"poison":
				state.add_mage_status(target_idx, StatusPoison.new(stacks))
			"freeze":
				state.add_mage_status(target_idx, StatusFrozen.new())
			"stun":
				state.add_mage_status(target_idx, StatusFrozen.new())
			"shield":
				state.mage_shield[target_idx] += effect.get("amount", 10)
			"blind":
				pass  # blind has no mage equivalent
			"cleanse_poison":
				state.mage_statuses[target_idx].assign(
					(state.mage_statuses[target_idx] as Array).filter(
						func(s: StatusData) -> bool: return not (s is StatusPoison)))


func _push_enemy(
		state: BattleState, setup: BattleSetup, eid: String,
		distance: int, collision_damage: int) -> void:
	var enemy := setup.get_enemy(eid)
	if enemy == null:
		return
	var idx := -1
	for i in setup.enemies.size():
		if setup.enemies[i].id == eid:
			idx = i
			break
	if idx < 0:
		return
	var pos := setup.get_enemy_pos(idx, state)
	var push_dir := Vector2i(1, 0)  # back = increasing column (away from mages)
	for _step in distance:
		var new_pos := pos + push_dir
		if not EnemyGrid.is_within_bounds(new_pos, enemy.grid_size):
			break
		var blocker_id := ""
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(new_pos, enemy.grid_size):
			var occupant := setup.get_occupant_at(cell, state)
			if occupant != "" and occupant != eid:
				blocker_id = occupant
				break
		if blocker_id != "":
			_deal_collision_damage(state, eid, collision_damage)
			_deal_collision_damage(state, blocker_id, collision_damage)
			break
		pos = new_pos
		state.enemy_positions[eid] = pos


func _deal_collision_damage(state: BattleState, target_id: String, damage: int) -> void:
	if state.enemy_hp.has(target_id):
		state.enemy_hp[target_id] -= damage
		if state.enemy_hp[target_id] <= 0:
			state.kill_enemy(target_id)
	elif state.obstacle_hp.has(target_id):
		state.obstacle_hp[target_id] -= damage
		if state.obstacle_hp[target_id] <= 0:
			state.obstacle_hp.erase(target_id)


func _apply_backfire(state: BattleState, mage_idx: int, ev: CastEvent) -> void:
	state.mage_hp[mage_idx] = max(0, state.mage_hp[mage_idx] - ev.backfire_damage)
	for effect: Dictionary in ev.backfire_effects:
		match effect.get("type", ""):
			"stun":
				state.add_mage_status(mage_idx, StatusFrozen.new())
			"fire":
				state.add_mage_status(mage_idx, StatusFire.new(effect.get("stacks", 1)))
			"poison":
				state.add_mage_status(mage_idx, StatusPoison.new(effect.get("stacks", 1)))
