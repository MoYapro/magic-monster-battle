class_name MonsterTraitWetHealing extends MonsterTraitData

var amount: int


func _init(p_amount: int) -> void:
	super("Wet Heal %d" % p_amount, 2)
	amount = p_amount


func apply_end_of_round(state: BattleState, setup: BattleSetup, enemy_id: String) -> BattleState:
	var wet_status: MonsterStatusWet = null
	for s: MonsterStatusData in (state.enemy_statuses.get(enemy_id, []) as Array):
		if s is MonsterStatusWet:
			wet_status = s
			break
	if wet_status == null or wet_status.stacks <= 0:
		return state
	var wet := wet_status.stacks
	var new_state := state.duplicate()
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	new_state.enemy_hp[enemy_id] = mini(new_state.enemy_hp[enemy_id] + wet * amount, enemy.max_hp)
	return new_state
