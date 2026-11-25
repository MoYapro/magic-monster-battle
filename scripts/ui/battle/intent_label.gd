class_name IntentLabel
extends RefCounted
## Short text for a monster's intent chip: "⚔ 5", "⚔ 4 all", "+ 30", or the action's name.


static func text_for(enemy: EnemyData, intent: Dictionary) -> String:
	var index: int = intent.get("action_index", -1)
	if enemy == null or index < 0 or index >= enemy.action_pool.size():
		return intent.get("action_name", "")
	var action := enemy.action_pool[index]
	var all := " all" if intent.get("all_mages", false) else ""
	if action is MonsterActionAttack:
		return "⚔ %d%s" % [(action as MonsterActionAttack).damage, all]
	if action is MonsterActionCleave:
		return "⚔ %d%s" % [(action as MonsterActionCleave).damage, all]
	if action is MonsterActionHeal:
		return "+ %d" % (action as MonsterActionHeal).amount
	return action.name
