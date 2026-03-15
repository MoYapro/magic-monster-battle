class_name MonsterActionHeal extends MonsterActionData

var amount: int


func _init(p_name: String, p_amount: int) -> void:
	name = p_name
	target_type = TargetType.SELF
	amount = p_amount


func execute(state: BattleState, setup: BattleSetup,
		enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	if not new_state.enemy_hp.has(enemy_id):
		return new_state
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	new_state.enemy_hp[enemy_id] = min(enemy.max_hp, new_state.enemy_hp[enemy_id] + amount)
	return new_state
