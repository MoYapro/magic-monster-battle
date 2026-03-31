class_name MonsterStatusFire extends MonsterStatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "FIRE"
	display_color = Color(0.95, 0.42, 0.05)


func get_label() -> String:
	return "FIRE %d" % stacks


func on_add_status(state: BattleState, enemy_id: String, incoming: MonsterStatusData) -> void:
	if incoming is MonsterStatusFire:
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is MonsterStatusWet:
		var absorbed := mini(stacks, incoming.stacks)
		stacks -= absorbed
		incoming.stacks -= absorbed
		if stacks <= 0:
			(state.enemy_statuses[enemy_id] as Array).erase(self)


func on_turn_end(state: BattleState, _setup: BattleSetup, enemy_id: String) -> BattleState:
	if not state.enemy_hp.has(enemy_id):
		return state
	state.enemy_hp[enemy_id] = max(0, state.enemy_hp[enemy_id] - stacks)
	stacks /= 2
	if stacks <= 0:
		(state.enemy_statuses[enemy_id] as Array).erase(self)
	if state.enemy_hp[enemy_id] <= 0:
		state.kill_enemy(enemy_id)
	return state


func get_turn_damage() -> int:
	return stacks
