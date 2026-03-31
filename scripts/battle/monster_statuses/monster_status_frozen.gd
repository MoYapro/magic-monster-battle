class_name MonsterStatusFrozen extends MonsterStatusData


func _init() -> void:
	display_name = "FROZEN"
	display_color = Color(0.55, 0.80, 0.95)


func blocks_action() -> bool:
	return true


func on_add_status(state: BattleState, enemy_id: String, incoming: MonsterStatusData) -> void:
	if incoming is MonsterStatusFire:
		incoming.stacks = 0
		(state.enemy_statuses[enemy_id] as Array).erase(self)
