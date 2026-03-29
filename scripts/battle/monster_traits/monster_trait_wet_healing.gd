class_name MonsterTraitWetHealing extends MonsterTraitData


func _init() -> void:
	super("Wet Heal", 2)


func apply_end_of_round(state: BattleState, setup: BattleSetup, enemy_id: String) -> BattleState:
	var wet := state.enemy_wet.get(enemy_id, 0) as int
	if wet <= 0:
		return state
	var new_state := state.duplicate()
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	new_state.enemy_hp[enemy_id] = mini(new_state.enemy_hp[enemy_id] + wet, enemy.max_hp)
	return new_state
