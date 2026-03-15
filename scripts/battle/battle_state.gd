class_name BattleState

# enemy_id -> current_hp  (absent = dead / not yet placed)
var enemy_hp: Dictionary = {}
var mage_hp: Array[int] = []
var mana: int = 0
# "mage_index/slot_id" -> charges placed on that slot
var slot_charges: Dictionary = {}
# per-mage mana spent on wand slots this turn
var mage_mana_spent: Array[int] = []
# enemy_id -> { action_index, action_name, target, target_name }
var monster_intents: Dictionary = {}


func duplicate() -> BattleState:
	var s := BattleState.new()
	s.enemy_hp = enemy_hp.duplicate()
	for hp: int in mage_hp:
		s.mage_hp.append(hp)
	s.mana = mana
	s.slot_charges = slot_charges.duplicate()
	for v: int in mage_mana_spent:
		s.mage_mana_spent.append(v)
	s.monster_intents = monster_intents.duplicate(true)
	return s
