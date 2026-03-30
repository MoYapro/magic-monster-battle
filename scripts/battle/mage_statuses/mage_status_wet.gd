class_name MageStatusWet extends MageStatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "WET"
	display_color = Color(0.20, 0.45, 0.80)


func get_label() -> String:
	return "WET %d" % stacks


func on_add_status(state: BattleState, mage_index: int, incoming: MageStatusData) -> void:
	if incoming is MageStatusWet:
		# Merge into existing
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is MageStatusFire:
		# Wet absorbs incoming fire
		var absorbed := mini(stacks, incoming.stacks)
		stacks -= absorbed
		incoming.stacks -= absorbed
		if stacks <= 0:
			state.mage_statuses[mage_index].erase(self)


func on_turn_end(state: BattleState, _setup: BattleSetup, mage_index: int) -> BattleState:
	stacks = maxi(0, stacks - 1)
	if stacks <= 0:
		state.mage_statuses[mage_index].erase(self)
	return state
