class_name MageThreats
extends RefCounted
## Monster intents aimed at one mage: [{enemy, action, damage}], strongest first.


static func for_mage(state: BattleState, setup: BattleSetup, mage_index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in state.enemies:
		var es := state.enemies[id] as EnemyState
		var enemy := setup.get_enemy(id)
		var index: int = es.intent.get("action_index", -1)
		if enemy == null or index < 0 or index >= enemy.action_pool.size():
			continue
		if es.intent.get("target", -1) != mage_index and not es.intent.get("all_mages", false):
			continue
		var action := enemy.action_pool[index]
		out.append({"enemy": enemy.display_name, "action": action, "damage": ActionText.damage(action)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["damage"] > b["damage"])
	return out
