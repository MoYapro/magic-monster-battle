class_name MonsterTraitArmor extends MonsterTraitData

var armor_amount: int


func _init(p_amount: int) -> void:
	super("Armor %d" % p_amount)
	armor_amount = p_amount


func apply_end_of_round(state: BattleState, _setup: BattleSetup, enemy_id: String) -> BattleState:
	var new_state := state.duplicate()
	if not new_state.enemy_hp.has(enemy_id):
		return new_state
	new_state.enemy_armor[enemy_id] = armor_amount
	return new_state
