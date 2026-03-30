class_name MageStatusFire extends MageStatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "FIRE"
	display_color = Color(0.95, 0.42, 0.05)


func get_label() -> String:
	return "FIRE %d" % stacks


func on_add_status(state: BattleState, mage_index: int, incoming: MageStatusData) -> void:
	if incoming is MageStatusFire:
		# Merge into existing
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is MageStatusWet:
		# Fire is doused by incoming wet
		var absorbed := mini(stacks, incoming.stacks)
		stacks -= absorbed
		incoming.stacks -= absorbed
		if stacks <= 0:
			state.mage_statuses[mage_index].erase(self)


func on_turn_end(state: BattleState, _setup: BattleSetup, mage_index: int) -> BattleState:
	state.mage_hp[mage_index] = max(0, state.mage_hp[mage_index] - stacks)
	stacks /= 2
	if stacks <= 0:
		state.mage_statuses[mage_index].erase(self)
	return state


func get_turn_damage() -> int:
	return stacks
