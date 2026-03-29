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
var mage_poison: Array[int] = []   # stacks per mage; each stack deals 1 dmg then decrements
var enemy_poison: Dictionary = {}  # enemy_id -> stacks
var mage_fire: Array[int] = []     # fire stacks per mage; deal stacks dmg then halve each round
var enemy_fire: Dictionary = {}    # enemy_id -> fire stacks
var mage_wet: Array[int] = []      # wet stacks per mage; absorb incoming fire, decay 1/turn
var enemy_wet: Dictionary = {}     # enemy_id -> wet stacks
var mage_frozen: Array[bool] = []  # frozen per mage; immune to fire, removed by first fire hit
var enemy_frozen: Dictionary = {}  # enemy_id -> true; skips attack, immune to fire, removed by first fire hit
var webbed_slots: Dictionary = {}  # "mage_index/slot_id" -> true; slot unusable this turn
var mana: int = 0
# "mage_index/slot_id" -> charges placed on that slot
var slot_charges: Dictionary = {}
# per-mage mana spent on wand slots this turn
var mage_mana_spent: Array[int] = []
# enemy_id -> { action_index, action_name, target, target_name }
var monster_intents: Dictionary = {}
var enemy_attack_mult: Dictionary = {}  # enemy_id -> float multiplier for this round
var enemy_positions: Dictionary = {}   # enemy_id -> Vector2i; overrides setup position when set
var enemy_stunned: Dictionary = {}     # enemy_id -> turns remaining; skips attack
var enemy_blind: Dictionary = {}       # enemy_id -> turns remaining; 50% miss / random target
var cast_events: Array = []            # CastEvents from the most recent zap action


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


func add_fire_stacks_to_enemy(enemy_id: String, stacks: int) -> void:
	if stacks <= 0 or not enemy_hp.has(enemy_id):
		return
	if enemy_frozen.has(enemy_id):
		enemy_frozen.erase(enemy_id)
		return
	var wet: int = enemy_wet.get(enemy_id, 0)
	var remaining := stacks - wet
	if wet > 0:
		enemy_wet[enemy_id] = maxi(0, wet - stacks)
		if enemy_wet[enemy_id] == 0:
			enemy_wet.erase(enemy_id)
	if remaining > 0:
		enemy_fire[enemy_id] = (enemy_fire.get(enemy_id, 0) as int) + remaining


func add_fire_stacks_to_mage(mage_idx: int, stacks: int) -> void:
	if stacks <= 0 or mage_idx < 0 or mage_idx >= mage_fire.size():
		return
	if mage_frozen[mage_idx]:
		mage_frozen[mage_idx] = false
		return
	var wet := mage_wet[mage_idx]
	var remaining := stacks - wet
	if wet > 0:
		mage_wet[mage_idx] = maxi(0, wet - stacks)
	if remaining > 0:
		mage_fire[mage_idx] += remaining


func kill_enemy(enemy_id: String) -> void:
	enemy_hp.erase(enemy_id)
	enemy_armor.erase(enemy_id)
	enemy_block.erase(enemy_id)
	enemy_fire.erase(enemy_id)
	enemy_poison.erase(enemy_id)
	enemy_wet.erase(enemy_id)
	enemy_frozen.erase(enemy_id)
	enemy_stunned.erase(enemy_id)
	enemy_blind.erase(enemy_id)
	enemy_attack_mult.erase(enemy_id)
	enemy_positions.erase(enemy_id)


func tick_poison() -> void:
	for i in mage_poison.size():
		if mage_poison[i] > 0:
			mage_hp[i] = max(0, mage_hp[i] - 1)
			mage_poison[i] -= 1
	var to_kill: Array[String] = []
	for enemy_id: String in enemy_poison:
		if enemy_poison[enemy_id] > 0 and enemy_hp.has(enemy_id):
			enemy_hp[enemy_id] = max(0, enemy_hp[enemy_id] - 1)
			enemy_poison[enemy_id] -= 1
			if enemy_hp[enemy_id] <= 0:
				to_kill.append(enemy_id)
	for enemy_id: String in to_kill:
		kill_enemy(enemy_id)


func tick_fire() -> void:
	for i in mage_fire.size():
		if mage_fire[i] > 0:
			mage_hp[i] = max(0, mage_hp[i] - mage_fire[i])
			mage_fire[i] /= 2
	var to_kill: Array[String] = []
	for enemy_id: String in enemy_fire:
		if enemy_fire[enemy_id] > 0 and enemy_hp.has(enemy_id):
			enemy_hp[enemy_id] = max(0, enemy_hp[enemy_id] - enemy_fire[enemy_id])
			enemy_fire[enemy_id] /= 2
			if enemy_hp[enemy_id] <= 0:
				to_kill.append(enemy_id)
	for enemy_id: String in to_kill:
		kill_enemy(enemy_id)


func tick_wet() -> void:
	for i in mage_wet.size():
		mage_wet[i] = maxi(0, mage_wet[i] - 1)
	var to_erase: Array[String] = []
	for enemy_id: String in enemy_wet:
		enemy_wet[enemy_id] -= 1
		if enemy_wet[enemy_id] <= 0:
			to_erase.append(enemy_id)
	for enemy_id: String in to_erase:
		enemy_wet.erase(enemy_id)
