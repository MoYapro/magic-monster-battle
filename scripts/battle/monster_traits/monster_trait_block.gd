class_name MonsterTraitBlock extends MonsterTraitData

var block_charges: int


func _init(p_charges: int) -> void:
	super("Block %d" % p_charges, 2)
	block_charges = p_charges


func apply_end_of_round(state: BattleState, _setup: BattleSetup, enemy_id: String) -> BattleState:
	var new_state := state.duplicate()
	if not new_state.enemy_hp.has(enemy_id):
		return new_state
	new_state.enemy_block[enemy_id] = block_charges
	return new_state
