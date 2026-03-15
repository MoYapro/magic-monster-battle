class_name ActionAddMana extends BattleAction

var mage_index: int
var slot_id: String


func _init(p_mage_index: int, p_slot_id: String) -> void:
	mage_index = p_mage_index
	slot_id = p_slot_id


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	if new_state.mana <= 0:
		return new_state
	var key := "%d/%s" % [mage_index, slot_id]
	new_state.slot_charges[key] = new_state.slot_charges.get(key, 0) + 1
	new_state.mana -= 1
	return new_state
