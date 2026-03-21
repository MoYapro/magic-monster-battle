class_name ActionRemoveMana extends BattleAction

var mage_index: int
var slot_id: String


func _init(p_mage_index: int, p_slot_id: String) -> void:
	mage_index = p_mage_index
	slot_id = p_slot_id


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	var key := "%d/%s" % [mage_index, slot_id]
	var current: int = new_state.slot_charges.get(key, 0)
	if current <= 0:
		return new_state
	new_state.slot_charges[key] = current - 1
	new_state.mana += 1
	new_state.mage_mana_spent[mage_index] -= 1
	return new_state
