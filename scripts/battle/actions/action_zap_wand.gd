class_name ActionZapWand extends BattleAction

var mage_index: int
var target_cell: Vector2i


func _init(p_mage_index: int, p_target_cell: Vector2i) -> void:
	mage_index = p_mage_index
	target_cell = p_target_cell


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	if new_state.mage_mana_spent[mage_index] >= setup.mages[mage_index].mana_allowance:
		return new_state
	var wand := setup.wands[mage_index]

	var damage := 0
	var fire_damage := 0
	var pattern: Array[Vector2i] = [Vector2i(0, 0)]

	for slot: SpellSlotData in wand.slots:
		if slot.spell == null:
			continue
		var key := "%d/%s" % [mage_index, slot.id]
		var charges: int = new_state.slot_charges.get(key, 0)
		if charges < slot.spell.mana_cost:
			continue  # inactive — skip
		damage += slot.spell.damage
		if slot.spell.tags.has("fire"):
			fire_damage += slot.spell.damage
		if slot.is_tip and not slot.spell.hit_pattern.is_empty():
			pattern = slot.spell.hit_pattern

	var fire_stacks: int = maxi(0, fire_damage - 1)

	var blocked_this_zap: Dictionary = {}
	for cell: Vector2i in EnemyGrid.get_hit_cells(target_cell, pattern):
		var eid: String = setup.get_enemy_id_at(cell)
		if eid.is_empty() or not new_state.enemy_hp.has(eid):
			continue
		if blocked_this_zap.has(eid):
			continue
		if new_state.enemy_block.get(eid, 0) > 0:
			new_state.enemy_block[eid] -= 1
			if new_state.enemy_block[eid] <= 0:
				new_state.enemy_block.erase(eid)
			blocked_this_zap[eid] = true
			continue
		var remaining := damage
		if new_state.enemy_armor.has(eid):
			var absorbed := mini(new_state.enemy_armor[eid], remaining)
			new_state.enemy_armor[eid] -= absorbed
			remaining -= absorbed
			if new_state.enemy_armor[eid] <= 0:
				new_state.enemy_armor.erase(eid)
		new_state.enemy_hp[eid] -= remaining
		if new_state.enemy_hp[eid] <= 0:
			new_state.enemy_hp.erase(eid)
			new_state.enemy_armor.erase(eid)
			new_state.enemy_block.erase(eid)
		elif fire_stacks > 0:
			new_state.enemy_fire[eid] = new_state.enemy_fire.get(eid, 0) + fire_stacks

	for slot: SpellSlotData in wand.slots:
		new_state.slot_charges.erase("%d/%s" % [mage_index, slot.id])

	return new_state
