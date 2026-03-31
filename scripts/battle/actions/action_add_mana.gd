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
	var slot := setup.wands[mage_index].get_slot(slot_id)
	if slot == null or slot.spell == null:
		return new_state
	var key := "%d/%s" % [mage_index, slot_id]
	var current: int = new_state.slot_charges.get(key, 0)
	if current >= slot.spell.mana_cost:
		return new_state
	new_state.slot_charges[key] = current + 1
	new_state.mana -= 1
	new_state.mage_mana_spent[mage_index] += 1
	var mana_target := StatusTarget.for_mage(new_state, mage_index)
	for status: StatusData in new_state.mage_statuses[mage_index].duplicate():
		status.on_mana_spent(mana_target, setup)
	return new_state
