class_name MageStatusFrozen extends MageStatusData


func _init() -> void:
	display_name = "FROZEN"
	display_color = Color(0.55, 0.80, 0.95)


func blocks_zap() -> bool:
	return true


func on_add_status(state: BattleState, mage_index: int, incoming: MageStatusData) -> void:
	if incoming is MageStatusFire:
		incoming.stacks = 0  # frozen absorbs all incoming fire, then melts
		state.mage_statuses[mage_index].erase(self)


