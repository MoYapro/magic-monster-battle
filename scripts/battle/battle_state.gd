class_name BattleState

# enemy_id -> current_hp  (absent = dead / not yet placed)
var enemy_hp: Dictionary = {}
# enemy_id -> current armor hp (absent = no armor)
var enemy_armor: Dictionary = {}
# enemy_id -> block charges remaining (absent = no block)
var enemy_block: Dictionary = {}
# obstacle_id -> current_hp (absent = destroyed)
var obstacle_hp: Dictionary = {}
var mage_hp: Array[int] = []
var mage_shield: Array[int] = []  # extra HP buffer depleted before mage_hp
var enemy_statuses: Dictionary = {}  # enemy_id -> Array[StatusData]
var webbed_slots: Dictionary = {}  # "mage_index/slot_id" -> true; slot unusable this turn
var mage_statuses: Array = []          # index = mage_index, value = Array[StatusData]
var mana: int = 0
# "mage_index/slot_id" -> charges placed on that slot
var slot_charges: Dictionary = {}
# per-mage mana spent on wand slots this turn
var mage_mana_spent: Array[int] = []
# enemy_id -> { action_index, action_name, target, target_name }
var monster_intents: Dictionary = {}
var enemy_attack_mult: Dictionary = {}  # enemy_id -> float multiplier for this round
var enemy_positions: Dictionary = {}   # enemy_id -> Vector2i; overrides setup position when set
var obstacle_positions: Dictionary = {}  # obstacle_id -> Vector2i; overrides setup position when set
var enemy_stunned: Dictionary = {}     # enemy_id -> turns remaining; skips attack
var enemy_blind: Dictionary = {}       # enemy_id -> turns remaining; 50% miss / random target
var cast_events: Array = []            # CastEvents from the most recent zap action
var ground: Dictionary = {}           # Vector2i -> GroundType.Type


func duplicate() -> BattleState:
	var s := BattleState.new()
	for prop: Dictionary in get_property_list():
		if not (prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var prop_name: String = prop["name"]
		var val: Variant = get(prop_name)
		if val is Dictionary:
			s.set(prop_name, (val as Dictionary).duplicate(true))
		elif val is Array:
			s.set(prop_name, (val as Array).duplicate(true))
		else:
			s.set(prop_name, val)
	return s


func add_enemy_status(enemy_id: String, new_status: StatusData) -> void:
	if not enemy_hp.has(enemy_id):
		return
	if not enemy_statuses.has(enemy_id):
		enemy_statuses[enemy_id] = []
	_add_status(StatusTarget.for_enemy(self, enemy_id), new_status)


func add_mage_status(mage_index: int, new_status: StatusData) -> void:
	_add_status(StatusTarget.for_mage(self, mage_index), new_status)


func _add_status(target: StatusTarget, new_status: StatusData) -> void:
	for status: StatusData in target.get_statuses().duplicate():
		status.on_add_status(target, new_status)
	if new_status.stacks != 0:
		target.get_statuses().append(new_status)


func kill_enemy(enemy_id: String) -> void:
	enemy_hp.erase(enemy_id)
	enemy_armor.erase(enemy_id)
	enemy_block.erase(enemy_id)
	enemy_statuses.erase(enemy_id)
	enemy_stunned.erase(enemy_id)
	enemy_blind.erase(enemy_id)
	enemy_attack_mult.erase(enemy_id)
	enemy_positions.erase(enemy_id)
	for statuses: Array in mage_statuses:
		statuses.assign(statuses.filter(
				func(s: StatusData) -> bool: return s.source_enemy_id != enemy_id))
