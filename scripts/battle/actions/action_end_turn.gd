class_name ActionEndTurn extends BattleAction

var _rng_seed: int


func _init(rng_seed: int) -> void:
	_rng_seed = rng_seed


func apply(state: BattleState, setup: BattleSetup) -> BattleState:
	var new_state := state.duplicate()

	# Resolve each monster's queued intent
	for enemy_id: String in new_state.monster_intents:
		if not new_state.enemy_hp.has(enemy_id):
			continue
		var enemy := setup.get_enemy(enemy_id)
		if enemy == null or enemy.action_pool.is_empty():
			continue
		if new_state.enemy_frozen.has(enemy_id):
			continue
		var intent: Dictionary = new_state.monster_intents[enemy_id]
		var action_index: int = intent.get("action_index", 0)
		var target: int = intent.get("target", -1)
		var action: MonsterActionData = enemy.action_pool[action_index]
		var execute_id: String = intent.get("target_enemy_id", enemy_id)
		new_state = action.execute(new_state, setup, execute_id, target)
		var webbed_slot_id: String = intent.get("webbed_slot_id", "")
		if not webbed_slot_id.is_empty() and target >= 0:
			new_state.webbed_slots["%d/%s" % [target, webbed_slot_id]] = true

	# Apply end-of-round traits (regen, armor refresh, etc.)
	for enemy: EnemyData in setup.enemies:
		if not new_state.enemy_hp.has(enemy.id):
			continue
		for t: MonsterTraitData in enemy.traits:
			new_state = t.apply_end_of_round(new_state, setup, enemy.id) as BattleState

	# Status effects: poison, fire, wet
	new_state.tick_poison()
	new_state.tick_fire()
	new_state.tick_wet()

	# Reset turn resources
	new_state.enemy_attack_mult.clear()
	new_state.webbed_slots.clear()
	new_state.mana = setup.max_mana
	for i in new_state.mage_mana_spent.size():
		new_state.mage_mana_spent[i] = 0

	# Roll next round intents from post-resolution state
	var rng := RandomNumberGenerator.new()
	rng.seed = _rng_seed
	new_state.monster_intents = setup.roll_intents(new_state, rng)

	return new_state
