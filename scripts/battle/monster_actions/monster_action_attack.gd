class_name MonsterActionAttack extends MonsterActionData

var damage: int
var wet_stacks: int
var applies_frozen: bool
var applies_web: bool


func _init(p_name: String, p_damage: int, p_wet_stacks: int = 0,
		p_frozen: bool = false, p_web: bool = false) -> void:
	name = p_name
	target_type = TargetType.MAGE
	damage = p_damage
	wet_stacks = p_wet_stacks
	applies_frozen = p_frozen
	applies_web = p_web


func execute(state: BattleState, setup: BattleSetup,
		enemy_id: String, target: int) -> BattleState:
	var new_state := state.duplicate()
	if target >= 0 and target < new_state.mage_hp.size():
		new_state.mage_hp[target] = max(0, new_state.mage_hp[target] - damage)
		var enemy := setup.get_enemy(enemy_id)
		if enemy != null:
			for t: MonsterTraitData in enemy.traits:
				new_state = t.apply_on_hit(new_state, setup, enemy_id, target, damage) as BattleState
		if wet_stacks > 0:
			new_state.mage_wet[target] += wet_stacks
		if applies_frozen:
			new_state.mage_frozen[target] = true
	return new_state
