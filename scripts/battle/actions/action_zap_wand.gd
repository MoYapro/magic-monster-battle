class_name ActionZapWand extends BattleAction

var mage_index: int
var target_cell: Vector2i


func _init(p_mage_index: int, p_target_cell: Vector2i) -> void:
	mage_index = p_mage_index
	target_cell = p_target_cell


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	var wand := setup.wands[mage_index]
	var tip := wand.get_tip_slot()
	var pattern: Array[Vector2i] = [Vector2i(0, 0)]
	if tip != null and tip.spell != null and not tip.spell.hit_pattern.is_empty():
		pattern = tip.spell.hit_pattern
	var damage := wand.get_total_damage()
	for cell: Vector2i in EnemyGrid.get_hit_cells(target_cell, pattern):
		var eid: String = setup.get_enemy_id_at(cell)
		if eid.is_empty() or not new_state.enemy_hp.has(eid):
			continue
		new_state.enemy_hp[eid] -= damage
		if new_state.enemy_hp[eid] <= 0:
			new_state.enemy_hp.erase(eid)
	return new_state
