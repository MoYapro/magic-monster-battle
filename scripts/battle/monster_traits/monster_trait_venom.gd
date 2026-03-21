class_name MonsterTraitVenom extends MonsterTraitData

var stacks: int


func _init(p_stacks: int) -> void:
	super("Venom %d" % p_stacks, 2)
	stacks = p_stacks


func apply_on_hit(state: BattleState, _setup: BattleSetup, _enemy_id: String, target_mage: int, _damage: int) -> BattleState:
	if target_mage < 0 or target_mage >= state.mage_poison.size():
		return state
	var new_state := state.duplicate()
	new_state.mage_poison[target_mage] += stacks
	return new_state
