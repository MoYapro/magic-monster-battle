class_name StatusVineSnare extends StatusData


func _init(enemy_id: String) -> void:
	source_enemy_id = enemy_id
	display_name = "VINE SNARE"
	display_color = Color(0.20, 0.55, 0.15)


func on_zap(target: StatusTarget, setup: BattleSetup) -> void:
	var penalty := ceili(target.get_hp() / 2.0)
	target.set_hp(maxi(0, target.get_hp() - penalty))
	var state := target.get_state()
	if state.enemy_hp.has(source_enemy_id):
		var snarer := setup.get_enemy(source_enemy_id)
		if snarer != null:
			state.enemy_hp[source_enemy_id] = mini(
					state.enemy_hp[source_enemy_id] + penalty, snarer.max_hp)
	target.remove_status(self)


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	target.remove_status(self)
