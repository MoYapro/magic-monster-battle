class_name MonsterTraitData

# Difficulty tiers: 1 = minor, 2 = moderate, 3 = hard
var label: String  # shown in the enemy cell
var tier: int = 1


func _init(p_label: String, p_tier: int = 1) -> void:
	label = p_label
	tier = p_tier


func apply_end_of_round(state: BattleState, _setup: BattleSetup, _enemy_id: String) -> BattleState:
	return state
