class_name MonsterTraitData

var label: String  # shown in the enemy cell


func _init(p_label: String) -> void:
	label = p_label


func apply_end_of_round(state: BattleState, _setup: BattleSetup, _enemy_id: String) -> BattleState:
	return state
