class_name MageStatusPoison extends MageStatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "POISON"
	display_color = Color(0.50, 0.20, 0.65)


func get_label() -> String:
	return "POI %d" % stacks


func on_add_status(_state: BattleState, _mage_index: int, incoming: MageStatusData) -> void:
	if incoming is MageStatusPoison:
		stacks += incoming.stacks
		incoming.stacks = 0


func on_turn_end(state: BattleState, _setup: BattleSetup, mage_index: int) -> BattleState:
	state.mage_hp[mage_index] = max(0, state.mage_hp[mage_index] - 1)
	stacks -= 1
	if stacks <= 0:
		state.mage_statuses[mage_index].erase(self)
	return state


func get_turn_damage() -> int:
	return 1
