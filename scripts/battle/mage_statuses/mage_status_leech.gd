class_name MageStatusLeech extends MageStatusData


func _init(enemy_id: String) -> void:
	source_enemy_id = enemy_id
	display_name = "LEECH"
	display_color = Color(0.55, 0.10, 0.30)


func on_turn_end(state: BattleState, _setup: BattleSetup, mage_index: int) -> BattleState:
	state.mage_statuses[mage_index].erase(self)
	return state


func on_mana_spent(state: BattleState, setup: BattleSetup, _mage_index: int) -> BattleState:
	if not state.enemy_hp.has(source_enemy_id):
		return state
	var leecher := setup.get_enemy(source_enemy_id)
	if leecher != null:
		state.enemy_hp[source_enemy_id] = mini(
				state.enemy_hp[source_enemy_id] + 1, leecher.max_hp)
	return state
