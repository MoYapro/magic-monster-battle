class_name MonsterTraitRegen extends MonsterTraitData

var amount: int


func _init(p_amount: int) -> void:
	super("Regen %d" % p_amount)
	amount = p_amount


func apply_end_of_round(state: BattleState, setup: BattleSetup, enemy_id: String) -> BattleState:
	var new_state := state.duplicate()
	if not new_state.enemy_hp.has(enemy_id):
		return new_state
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	new_state.enemy_hp[enemy_id] = mini(new_state.enemy_hp[enemy_id] + amount, enemy.max_hp)
	return new_state
