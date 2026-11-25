class_name BattleRules

# Pure battle-scene rules: incoming damage preview, outcome, tip-click decision.

enum Outcome { ONGOING, WON, LOST }
enum TipClick { NONE, TARGET, ADD_MANA }


static func is_mage_dead(state: BattleState, mage_index: int) -> bool:
	return (state.mages[mage_index] as MageState).combatant.hp <= 0


static func incoming_attack(state: BattleState, setup: BattleSetup, mage_index: int) -> int:
	var total := 0
	for enemy_id: String in state.enemies:
		total += _intent_damage(state.enemies[enemy_id] as EnemyState, setup.get_enemy(enemy_id), mage_index)
	return total


static func _intent_damage(es: EnemyState, enemy: EnemyData, mage_index: int) -> int:
	if es.intent.is_empty() or enemy == null:
		return 0
	var targets_mage: bool = es.intent.get("target", -1) == mage_index or es.intent.get("all_mages", false)
	if not targets_mage:
		return 0
	if es.combatant.statuses.any(func(s: StatusData) -> bool: return s.blocks_action()):
		return 0
	var action_index: int = es.intent.get("action_index", 0)
	if action_index >= enemy.action_pool.size():
		return 0
	return _action_damage(enemy.action_pool[action_index])


static func _action_damage(action: MonsterActionData) -> int:
	if action is MonsterActionAttack:
		return (action as MonsterActionAttack).damage
	if action is MonsterActionCleave:
		return (action as MonsterActionCleave).damage
	return 0


# has_actions: whether any action was taken (BattleHistory.can_undo()).
static func outcome(state: BattleState, has_actions: bool) -> Outcome:
	if state.mages.all(func(ms: MageState) -> bool: return ms.combatant.hp <= 0):
		return Outcome.LOST
	if has_actions and state.enemies.is_empty():
		return Outcome.WON
	return Outcome.ONGOING


static func tip_click(state: BattleState, setup: BattleSetup, mage_index: int) -> TipClick:
	if is_mage_dead(state, mage_index):
		return TipClick.NONE
	var tip := setup.wands[mage_index].get_tip_slot()
	if tip == null or tip.spell == null:
		return TipClick.TARGET
	var ms := state.mages[mage_index] as MageState
	if ms.slot_charges.get(tip.id, 0) < tip.spell.mana_cost:
		return TipClick.ADD_MANA
	if ms.mana_spent < setup.mages[mage_index].mana_allowance:
		return TipClick.TARGET
	return TipClick.NONE


# Copies live HP from the state onto MageData / EnemyData, which displays and tooltips read.
static func sync_current_hp(state: BattleState, setup: BattleSetup) -> void:
	for i in setup.mages.size():
		setup.mages[i].current_hp = (state.mages[i] as MageState).combatant.hp
	for enemy: EnemyData in setup.enemies:
		if state.enemies.has(enemy.id):
			enemy.current_hp = (state.enemies[enemy.id] as EnemyState).combatant.hp


static func occupied_cells(positions: Array[Vector2i], sizes: Array[Vector2i]) -> Dictionary:
	var occupied: Dictionary = {}
	for i in positions.size():
		for c: Vector2i in footprint(positions[i], sizes[i]):
			occupied[c] = true
	return occupied


static func footprint(cell: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(size.x):
		for dy in range(size.y):
			cells.append(cell + Vector2i(dx, dy))
	return cells


static func can_place(cell: Vector2i, size: Vector2i, occupied: Dictionary) -> bool:
	for c: Vector2i in footprint(cell, size):
		if c.x >= EnemyGrid.COLS or c.y >= EnemyGrid.ROWS or occupied.has(c):
			return false
	return true
