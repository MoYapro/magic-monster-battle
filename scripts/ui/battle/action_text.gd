class_name ActionText
extends RefCounted
## Player-facing text for monster actions, shared by tooltips and the details panel.


static func describe(action: MonsterActionData) -> String:
	if action is MonsterActionAttack:
		var atk := action as MonsterActionAttack
		var extra: Array[String] = []
		if atk.wet_stacks > 0:
			extra.append("Wet %d" % atk.wet_stacks)
		if atk.applies_frozen:
			extra.append("Freeze")
		if atk.applies_web:
			extra.append("Web")
		return "Strikes one mage" + (" · " + ", ".join(extra) if not extra.is_empty() else "")
	if action is MonsterActionCleave:
		return "Strikes every mage"
	if action is MonsterActionHeal:
		return "Heals the weakest ally by %d" % (action as MonsterActionHeal).amount
	if action is MonsterActionDrumsOfWar:
		return "Doubles the attack of adjacent allies"
	if action is MonsterActionVineSnare:
		return "Blocks an attack; breaking free costs half HP and heals the caster"
	if action is MonsterActionLeech:
		return "Each mana you spend heals the caster by 1"
	if action is MonsterActionTakeCover:
		return "Hides behind cover"
	if action is MonsterActionSummonEnemy:
		return "Calls an ally to the field"
	return ""


static func damage(action: MonsterActionData) -> int:
	if action is MonsterActionAttack:
		return (action as MonsterActionAttack).damage
	if action is MonsterActionCleave:
		return (action as MonsterActionCleave).damage
	return 0


## One-line summary used in tooltips: "Strike  5 dmg  Wet 2".
static func summary(action: MonsterActionData) -> String:
	var dmg := damage(action)
	var head := "%s  %d dmg" % [action.name, dmg] if dmg > 0 else action.name
	var text := describe(action)
	return head + ("  —  " + text if text != "" and dmg == 0 else "")
