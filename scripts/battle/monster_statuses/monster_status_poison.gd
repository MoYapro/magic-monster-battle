class_name MonsterStatusPoison extends MonsterStatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "POI"
	display_color = Color(0.50, 0.20, 0.65)


func get_label() -> String:
	return "POI %d" % stacks


func on_add_status(_state: BattleState, _enemy_id: String, incoming: MonsterStatusData) -> void:
	if incoming is MonsterStatusPoison:
		stacks += incoming.stacks
		incoming.stacks = 0


func on_turn_end(state: BattleState, _setup: BattleSetup, enemy_id: String) -> BattleState:
	if not state.enemy_hp.has(enemy_id):
		return state
	state.enemy_hp[enemy_id] = max(0, state.enemy_hp[enemy_id] - 1)
	stacks -= 1
	if stacks <= 0:
		(state.enemy_statuses[enemy_id] as Array).erase(self)
	if state.enemy_hp[enemy_id] <= 0:
		state.kill_enemy(enemy_id)
	return state


func get_turn_damage() -> int:
	return 1
