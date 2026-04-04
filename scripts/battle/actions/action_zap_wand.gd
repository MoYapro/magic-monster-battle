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
	if new_state.mage_mana_spent[mage_index] > setup.mages[mage_index].mana_allowance:
		return new_state
	var wand := setup.wands[mage_index]
	var pattern := _get_hit_pattern(wand, new_state)
	var zap_mana_cost := _sum_slot_charges(wand, new_state)
	var cast_events := WandEvaluator.evaluate(_get_charged_body_spells(wand, new_state), zap_mana_cost)
	for ev: CastEvent in cast_events:
		match ev.type:
			CastEvent.Type.PROJECTILE:
				if target_mage_index >= 0:
					_apply_projectile_to_mage(new_state, ev, target_mage_index, pattern)
				else:
					var push_dir := pattern[1] if pattern.size() > 1 else Vector2i(1, 0)
					var bounce_dir := pattern[1] if pattern.size() > 1 else Vector2i.ZERO
					_apply_projectile(new_state, setup, ev, pattern, push_dir, bounce_dir)
			CastEvent.Type.BACKFIRE:
				_apply_backfire(new_state, mage_index, ev)
			CastEvent.Type.FIZZLE:
				pass  # mana consumed, nothing fires
	new_state.cast_events = cast_events
	for slot: SpellSlotData in wand.slots:
		new_state.slot_charges.erase("%d/%s" % [mage_index, slot.id])
	return new_state


func _get_hit_pattern(wand: WandData, state: BattleState) -> Array[Vector2i]:
	var tip_slot := wand.get_tip_slot()
	if tip_slot == null or tip_slot.spell == null:
		return [Vector2i(0, 0)]
	var tip_key := "%d/%s" % [mage_index, tip_slot.id]
	var tip_charges: int = state.slot_charges.get(tip_key, 0)
	if tip_charges >= tip_slot.spell.mana_cost and not tip_slot.spell.hit_pattern.is_empty():
		return tip_slot.spell.hit_pattern
	return [Vector2i(0, 0)]


func _get_charged_body_spells(wand: WandData, state: BattleState) -> Array[SpellData]:
	var body_slots: Array[SpellSlotData] = []
	for slot: SpellSlotData in wand.slots:
		if slot.is_tip or slot.spell == null:
			continue
		var key := "%d/%s" % [mage_index, slot.id]
		if state.webbed_slots.has(key) or state.slot_charges.get(key, 0) < slot.spell.mana_cost:
			continue
		body_slots.append(slot)
	body_slots.sort_custom(func(a: SpellSlotData, b: SpellSlotData) -> bool:
		return a.grid_col < b.grid_col if a.grid_col != b.grid_col else a.grid_row < b.grid_row)
	var spells: Array[SpellData] = []
	for slot: SpellSlotData in body_slots:
		spells.append(slot.spell)
	return spells


func _sum_slot_charges(wand: WandData, state: BattleState) -> int:
	var total := 0
	for slot: SpellSlotData in wand.slots:
		total += state.slot_charges.get("%d/%s" % [mage_index, slot.id], 0)
	return total


func _apply_on_kill_effects(state: BattleState, ev: CastEvent) -> void:
	for effect: Dictionary in ev.on_kill_effects:
		match effect.get("type", ""):
			"refund_zap_mana":
				state.mana += ev.zap_mana_cost
				state.mage_mana_spent[mage_index] -= ev.zap_mana_cost


func _apply_projectile(
		state: BattleState, setup: BattleSetup, ev: CastEvent, pattern: Array[Vector2i],
		push_dir: Vector2i = Vector2i(1, 0), bounce_dir: Vector2i = Vector2i.ZERO) -> void:
	var hit_ids: Dictionary = {}
	var hit_cells: Array[Vector2i] = []
	if ev.corrupted and pattern.size() > 1:
		hit_cells.append(target_cell)
	else:
		hit_cells = EnemyGrid.get_hit_cells(target_cell, pattern)
	for cell: Vector2i in hit_cells:
		var eid: String = setup.get_occupant_at(cell, state)
		if eid.is_empty() or hit_ids.has(eid):
			continue
		if state.obstacle_hp.has(eid):
			_apply_damage_to_obstacle(state, setup, eid, ev, push_dir)
			hit_ids[eid] = true
			continue
		if not state.enemy_hp.has(eid):
			continue
		hit_ids[eid] = true
		if _try_consume_block(state, eid):
			continue
		_apply_damage_to_enemy(state, setup, eid, ev, push_dir)
	if ev.bounces > 0:
		_apply_bounces(state, setup, ev, hit_ids, push_dir, bounce_dir)


func _try_consume_block(state: BattleState, eid: String) -> bool:
	if state.enemy_block.get(eid, 0) <= 0:
		return false
	state.enemy_block[eid] -= 1
	if state.enemy_block[eid] <= 0:
		state.enemy_block.erase(eid)
	return true


func _apply_damage_to_obstacle(
		state: BattleState, setup: BattleSetup, eid: String,
		ev: CastEvent, push_dir: Vector2i) -> void:
	state.obstacle_hp[eid] -= ev.total_damage
	if state.obstacle_hp[eid] <= 0:
		state.obstacle_hp.erase(eid)
		return
	for effect: Dictionary in ev.on_hit_effects:
		if effect.get("type", "") == "push":
			_push_occupant(state, setup, eid,
					effect.get("distance", 1), effect.get("damage", 0), push_dir)


func _consume_status_stacks(state: BattleState, eid: String) -> int:
	if not state.enemy_statuses.has(eid):
		return 0
	var bonus := 0
	var kept: Array[StatusData] = []
	for status: StatusData in state.enemy_statuses[eid]:
		if (status is StatusFire or status is StatusPoison or status is StatusWet) and status.stacks > 0:
			bonus += status.stacks
		else:
			kept.append(status)
	state.enemy_statuses[eid] = kept
	return bonus


func _resolve_reactive(state: BattleState, eid: String, ev: CastEvent) -> Dictionary:
	match ev.spell.spell_id:
		"ember":
			for status: StatusData in state.enemy_statuses.get(eid, []):
				if status is StatusFire:
					return {"bonus": status.stacks, "effects": ev.on_hit_effects}
		"frost":
			for status: StatusData in state.enemy_statuses.get(eid, []):
				if status is StatusWet:
					return {"bonus": status.stacks, "effects": ev.on_hit_effects}
		"venom":
			for status: StatusData in state.enemy_statuses.get(eid, []):
				if status is StatusPoison:
					var burst := status.stacks
					var kept_s: Array[StatusData] = []
					for s: StatusData in state.enemy_statuses[eid]:
						if not (s is StatusPoison):
							kept_s.append(s)
					state.enemy_statuses[eid] = kept_s
					var kept_e: Array[Dictionary] = []
					for e: Dictionary in ev.on_hit_effects:
						if e.get("type", "") != "poison":
							kept_e.append(e)
					return {"bonus": burst, "effects": kept_e}
	return {"bonus": 0, "effects": ev.on_hit_effects}


func _apply_damage_to_enemy(
		state: BattleState, setup: BattleSetup, eid: String,
		ev: CastEvent, push_dir: Vector2i) -> void:
	var corruption_bonus := _consume_status_stacks(state, eid) if ev.corrupted else 0
	var reactive_result := _resolve_reactive(state, eid, ev) if ev.reactive else {"bonus": 0, "effects": ev.on_hit_effects}
	var total := ev.total_damage + corruption_bonus + reactive_result.get("bonus", 0) as int
	var remaining := _absorb_armor(state, eid, total)
	remaining = _absorb_enemy_shield(state, eid, remaining)
	state.enemy_hp[eid] -= remaining
	if state.enemy_hp[eid] <= 0:
		state.kill_enemy(eid)
		_apply_on_kill_effects(state, ev)
	else:
		var effects: Array[Dictionary] = reactive_result.get("effects", ev.on_hit_effects)
		_apply_on_hit_effects(state, setup, eid, effects, total, push_dir)


func _score_bounce_candidate(target: Vector2i, from: Vector2i, bounce_dir: Vector2i) -> int:
	var diff := target - from
	if bounce_dir == Vector2i.ZERO:
		return -(abs(diff.x) + abs(diff.y))
	return diff.x * bounce_dir.x + diff.y * bounce_dir.y


func _apply_bounces(
		state: BattleState, setup: BattleSetup, ev: CastEvent,
		hit_ids: Dictionary, push_dir: Vector2i,
		bounce_dir: Vector2i = Vector2i.ZERO) -> void:
	if ev.reactive and ev.spell.spell_id == "lightning":
		for enemy: EnemyData in setup.enemies:
			if not state.enemy_hp.has(enemy.id) or hit_ids.has(enemy.id):
				continue
			var wet := false
			for s: StatusData in state.enemy_statuses.get(enemy.id, []):
				if s is StatusWet:
					wet = true
					break
			if not wet:
				continue
			hit_ids[enemy.id] = true
			if not _try_consume_block(state, enemy.id):
				_apply_damage_to_enemy(state, setup, enemy.id, ev, push_dir)
		return
	var last_pos := target_cell
	for _bounce in range(ev.bounces):
		var candidates: Array[String] = []
		for enemy: EnemyData in setup.enemies:
			if state.enemy_hp.has(enemy.id) and not hit_ids.has(enemy.id):
				candidates.append(enemy.id)
		for obstacle: ObstacleData in setup.obstacles:
			if state.obstacle_hp.has(obstacle.id) and not hit_ids.has(obstacle.id):
				candidates.append(obstacle.id)
		if candidates.is_empty():
			break
		var next_id := candidates[0]
		var next_pos: Vector2i = _get_occupant_push_info(setup, state, next_id)["pos"]
		var best_score: int = _score_bounce_candidate(next_pos, last_pos, bounce_dir)
		for j in range(1, candidates.size()):
			var cid: String = candidates[j]
			var cpos: Vector2i = _get_occupant_push_info(setup, state, cid)["pos"]
			var score: int = _score_bounce_candidate(cpos, last_pos, bounce_dir)
			if score > best_score:
				best_score = score
				next_id = cid
				next_pos = cpos
		last_pos = next_pos
		hit_ids[next_id] = true
		if state.obstacle_hp.has(next_id):
			_apply_damage_to_obstacle(state, setup, next_id, ev, push_dir)
		elif not _try_consume_block(state, next_id):
			_apply_damage_to_enemy(state, setup, next_id, ev, push_dir)


func _absorb_enemy_shield(state: BattleState, eid: String, damage: int) -> int:
	if not state.enemy_shield.has(eid):
		return damage
	var absorbed := mini(state.enemy_shield[eid], damage)
	state.enemy_shield[eid] -= absorbed
	if state.enemy_shield[eid] <= 0:
		state.enemy_shield.erase(eid)
	return damage - absorbed


func _absorb_armor(state: BattleState, eid: String, damage: int) -> int:
	if not state.enemy_armor.has(eid):
		return damage
	var absorbed := mini(state.enemy_armor[eid], damage)
	state.enemy_armor[eid] -= absorbed
	if state.enemy_armor[eid] <= 0:
		state.enemy_armor.erase(eid)
	return damage - absorbed


func _apply_on_hit_effects(
		state: BattleState, setup: BattleSetup, eid: String,
		effects: Array[Dictionary], total_damage: int,
		push_dir: Vector2i = Vector2i(1, 0)) -> void:
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
				_push_occupant(state, setup, eid,
						effect.get("distance", 1), effect.get("damage", 0), push_dir)
			"shield":
				state.enemy_shield[eid] = state.enemy_shield.get(eid, 0) + effect.get("amount", 10)
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


func _get_occupant_push_info(setup: BattleSetup, state: BattleState, id: String) -> Dictionary:
	for i in setup.enemies.size():
		if setup.enemies[i].id == id:
			return {"grid_size": setup.enemies[i].grid_size, "pos": setup.get_enemy_pos(i, state), "is_enemy": true}
	for i in setup.obstacles.size():
		if setup.obstacles[i].id == id:
			return {"grid_size": setup.obstacles[i].grid_size, "pos": setup.get_obstacle_pos(i, state), "is_enemy": false}
	return {}


func _push_occupant(
		state: BattleState, setup: BattleSetup, id: String,
		distance: int, collision_damage: int,
		push_dir: Vector2i = Vector2i(1, 0)) -> void:
	var info := _get_occupant_push_info(setup, state, id)
	if info.is_empty():
		return
	var pos: Vector2i = info["pos"]
	var grid_size: Vector2i = info["grid_size"]
	var is_enemy: bool = info["is_enemy"]
	for _step in distance:
		var new_pos := pos + push_dir
		if not EnemyGrid.is_within_bounds(new_pos, grid_size):
			break
		var blocker_id := ""
		for cell: Vector2i in EnemyGrid.get_cells_for_enemy(new_pos, grid_size):
			var occupant := setup.get_occupant_at(cell, state)
			if occupant != "" and occupant != id:
				blocker_id = occupant
				break
		if blocker_id != "":
			_deal_collision_damage(state, id, collision_damage)
			_deal_collision_damage(state, blocker_id, collision_damage)
			break
		pos = new_pos
		if is_enemy:
			state.enemy_positions[id] = pos
		else:
			state.obstacle_positions[id] = pos


func _deal_collision_damage(state: BattleState, target_id: String, damage: int) -> void:
	if state.enemy_hp.has(target_id):
		var remaining := _absorb_enemy_shield(state, target_id, damage)
		state.enemy_hp[target_id] -= remaining
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
