class_name MonsterStatusWet extends MonsterStatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "WET"
	display_color = Color(0.25, 0.55, 0.90)


func get_label() -> String:
	return "WET %d" % stacks


func on_add_status(state: BattleState, enemy_id: String, incoming: MonsterStatusData) -> void:
	if incoming is MonsterStatusWet:
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is MonsterStatusFire:
		var absorbed := mini(stacks, incoming.stacks)
		stacks -= absorbed
		incoming.stacks -= absorbed
		if stacks <= 0:
			(state.enemy_statuses[enemy_id] as Array).erase(self)


func on_turn_end(state: BattleState, _setup: BattleSetup, enemy_id: String) -> BattleState:
	stacks -= 1
	if stacks <= 0:
		(state.enemy_statuses[enemy_id] as Array).erase(self)
	return state
