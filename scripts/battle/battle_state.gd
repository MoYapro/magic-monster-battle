class_name BattleState

# enemy_id -> current_hp  (absent = dead / not yet placed)
var enemy_hp: Dictionary = {}
# enemy_id -> current armor hp (absent = no armor)
var enemy_armor: Dictionary = {}
# obstacle_id -> current_hp (absent = destroyed)
var obstacle_hp: Dictionary = {}
var mage_hp: Array[int] = []
var mage_poison: Array[int] = []   # stacks per mage; each stack deals 1 dmg then decrements
var enemy_poison: Dictionary = {}  # enemy_id -> stacks
var mage_fire: Array[int] = []     # fire stacks per mage; deal stacks dmg then halve each round
var enemy_fire: Dictionary = {}    # enemy_id -> fire stacks
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
	s.enemy_armor = enemy_armor.duplicate()
	s.obstacle_hp = obstacle_hp.duplicate()
	for hp: int in mage_hp:
		s.mage_hp.append(hp)
	for v: int in mage_poison:
		s.mage_poison.append(v)
	s.enemy_poison = enemy_poison.duplicate()
	for v: int in mage_fire:
		s.mage_fire.append(v)
	s.enemy_fire = enemy_fire.duplicate()
	s.mana = mana
	s.slot_charges = slot_charges.duplicate()
	for v: int in mage_mana_spent:
		s.mage_mana_spent.append(v)
	s.monster_intents = monster_intents.duplicate(true)
	return s
