class_name StatusLeech extends StatusData


func _init(enemy_id: String) -> void:
	source_enemy_id = enemy_id
	display_name = "LEECH"
	display_color = Color(0.55, 0.10, 0.30)


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	target.remove_status(self)


func on_mana_spent(target: StatusTarget, setup: BattleSetup) -> void:
	var state := target.get_state()
	if not state.enemy_hp.has(source_enemy_id):
		return
	var leecher := setup.get_enemy(source_enemy_id)
	if leecher != null:
		state.enemy_hp[source_enemy_id] = mini(
				state.enemy_hp[source_enemy_id] + 1, leecher.max_hp)
