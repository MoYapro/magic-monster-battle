class_name MonsterTraitFire extends MonsterTraitData


func _init() -> void:
	super("Fire", 2)


func apply_on_hit(state: BattleState, _setup: BattleSetup, _enemy_id: String, target_mage: int, damage: int) -> BattleState:
	if target_mage < 0 or target_mage >= state.mage_fire.size():
		return state
	var new_state := state.duplicate()
	new_state.mage_fire[target_mage] += max(0, damage - 1)
	return new_state
