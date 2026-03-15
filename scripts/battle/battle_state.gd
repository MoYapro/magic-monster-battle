class_name BattleState

# enemy_id -> current_hp  (absent = dead / not yet placed)
var enemy_hp: Dictionary = {}
var mage_hp: Array[int] = []
var mana: int = 0
# "mage_index/slot_id" -> mana placed on that slot
var slot_charges: Dictionary = {}


func duplicate() -> BattleState:
	var s := BattleState.new()
	s.enemy_hp = enemy_hp.duplicate()
	for hp: int in mage_hp:
		s.mage_hp.append(hp)
	s.mana = mana
	s.slot_charges = slot_charges.duplicate()
	return s
