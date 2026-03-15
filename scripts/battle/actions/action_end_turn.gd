class_name ActionEndTurn extends BattleAction

func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()
	new_state.mana = setup.max_mana
	for i in new_state.mage_mana_spent.size():
		new_state.mage_mana_spent[i] = 0
	return new_state
