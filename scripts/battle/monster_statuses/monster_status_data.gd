class_name MonsterStatusData extends RefCounted

# -1 = non-stacked (always added); positive = stacked; 0 = absorbed (skip add)
var stacks: int = -1
var display_name: String = ""
var display_color: Color = Color.WHITE


func get_label() -> String:
	return display_name


func blocks_action() -> bool:
	return false


func on_add_status(_state: BattleState, _enemy_id: String, _incoming: MonsterStatusData) -> void:
	pass


func on_turn_end(state: BattleState, _setup: BattleSetup, _enemy_id: String) -> BattleState:
	return state


func get_turn_damage() -> int:
	return 0
