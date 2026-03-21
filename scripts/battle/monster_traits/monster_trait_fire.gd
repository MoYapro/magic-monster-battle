class_name MonsterTraitFire extends MonsterTraitData


func _init() -> void:
	super("Fire", 2)


func apply_on_hit(state: BattleState, _setup: BattleSetup, _enemy_id: String, target_mage: int, damage: int) -> BattleState:
	if target_mage < 0 or target_mage >= state.mage_fire.size():
		return state
	var fire_to_apply := maxi(0, damage - 1)
	if fire_to_apply == 0:
		return state
	var new_state := state.duplicate()
	if new_state.mage_frozen[target_mage]:
		new_state.mage_frozen[target_mage] = false
		return new_state
	var wet := new_state.mage_wet[target_mage]
	var remaining_fire := fire_to_apply - wet
	if wet > 0:
		new_state.mage_wet[target_mage] = maxi(0, wet - fire_to_apply)
	if remaining_fire > 0:
		new_state.mage_fire[target_mage] += remaining_fire
	return new_state
