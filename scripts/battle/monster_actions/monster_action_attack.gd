class_name MonsterActionAttack extends MonsterActionData

var damage: int


func _init(p_name: String, p_damage: int) -> void:
	name = p_name
	target_type = TargetType.MAGE
	damage = p_damage


func execute(state: BattleState, setup: BattleSetup,
		enemy_id: String, target: int) -> BattleState:
	var new_state := state.duplicate()
	if target >= 0 and target < new_state.mage_hp.size():
		new_state.mage_hp[target] = max(0, new_state.mage_hp[target] - damage)
		var enemy := setup.get_enemy(enemy_id)
		if enemy != null:
			for t: MonsterTraitData in enemy.traits:
				new_state = t.apply_on_hit(new_state, setup, enemy_id, target, damage) as BattleState
	return new_state
