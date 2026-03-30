class_name MageStatusVineSnare extends MageStatusData


func _init(enemy_id: String) -> void:
	source_enemy_id = enemy_id
	display_name = "VINE SNARE"
	display_color = Color(0.20, 0.55, 0.15)


func on_zap(state: BattleState, setup: BattleSetup, mage_index: int) -> BattleState:
	var penalty := ceili(state.mage_hp[mage_index] / 2.0)
	state.mage_hp[mage_index] = maxi(0, state.mage_hp[mage_index] - penalty)
	if state.enemy_hp.has(source_enemy_id):
		var snarer := setup.get_enemy(source_enemy_id)
		if snarer != null:
			state.enemy_hp[source_enemy_id] = mini(
					state.enemy_hp[source_enemy_id] + penalty, snarer.max_hp)
	state.mage_statuses[mage_index].erase(self)
	return state


func on_turn_end(state: BattleState, _setup: BattleSetup, mage_index: int) -> BattleState:
	state.mage_statuses[mage_index].erase(self)
	return state
