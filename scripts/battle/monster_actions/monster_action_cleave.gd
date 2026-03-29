class_name MonsterActionCleave extends MonsterActionData

var damage: int


func _init(p_name: String, p_damage: int) -> void:
	name = p_name
	target_type = TargetType.ALL_MAGES
	damage = p_damage


func execute(state: BattleState, _setup: BattleSetup,
		enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	var mult: float = new_state.enemy_attack_mult.get(enemy_id, 1.0)
	var actual_damage := int(damage * mult)
	for i in new_state.mage_hp.size():
		new_state.mage_hp[i] = max(0, new_state.mage_hp[i] - actual_damage)
	return new_state
