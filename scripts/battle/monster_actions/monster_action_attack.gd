class_name MonsterActionAttack extends MonsterActionData

var damage: int


func _init(p_name: String, p_damage: int) -> void:
	name = p_name
	target_type = TargetType.MAGE
	damage = p_damage


func execute(state: BattleState, _setup: BattleSetup,
		_enemy_id: String, target: int) -> BattleState:
	var new_state := state.duplicate()
	if target >= 0 and target < new_state.mage_hp.size():
		new_state.mage_hp[target] = max(0, new_state.mage_hp[target] - damage)
	return new_state
