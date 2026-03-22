extends GutTest


func _make_state() -> BattleState:
	var s := BattleState.new()
	s.enemy_hp["e1"] = 20
	s.mage_hp.append(30)
	s.mage_poison.append(0)
	s.mage_fire.append(0)
	s.mage_wet.append(0)
	s.mage_frozen.append(false)
	return s


# --- tick_poison ---

func test_poison_deals_one_damage_per_stack_to_mage() -> void:
	var s := _make_state()
	s.mage_poison[0] = 3
	s.tick_poison()
	assert_eq(s.mage_hp[0], 29)


func test_poison_decrements_mage_stack_after_tick() -> void:
	var s := _make_state()
	s.mage_poison[0] = 3
	s.tick_poison()
	assert_eq(s.mage_poison[0], 2)


func test_poison_deals_damage_to_enemy() -> void:
	var s := _make_state()
	s.enemy_poison["e1"] = 2
	s.tick_poison()
	assert_eq(s.enemy_hp["e1"], 19)


func test_poison_kills_enemy_at_zero_hp() -> void:
	var s := _make_state()
	s.enemy_hp["e1"] = 1
	s.enemy_poison["e1"] = 1
	s.tick_poison()
	assert_false(s.enemy_hp.has("e1"))


# --- tick_fire ---

func test_fire_deals_stacks_damage_to_mage() -> void:
	var s := _make_state()
	s.mage_fire[0] = 4
	s.tick_fire()
	assert_eq(s.mage_hp[0], 26)


func test_fire_halves_stacks_after_tick() -> void:
	var s := _make_state()
	s.mage_fire[0] = 4
	s.tick_fire()
	assert_eq(s.mage_fire[0], 2)


func test_fire_kills_enemy_when_damage_exceeds_hp() -> void:
	var s := _make_state()
	s.enemy_hp["e1"] = 3
	s.enemy_fire["e1"] = 5
	s.tick_fire()
	assert_false(s.enemy_hp.has("e1"))


# --- tick_wet ---

func test_wet_decays_enemy_stack_by_one_per_tick() -> void:
	var s := _make_state()
	s.enemy_wet["e1"] = 3
	s.tick_wet()
	assert_eq(s.enemy_wet.get("e1", -1), 2)


func test_wet_entry_removed_when_depleted() -> void:
	var s := _make_state()
	s.enemy_wet["e1"] = 1
	s.tick_wet()
	assert_false(s.enemy_wet.has("e1"))


func test_wet_decays_mage_stack_by_one_per_tick() -> void:
	var s := _make_state()
	s.mage_wet[0] = 2
	s.tick_wet()
	assert_eq(s.mage_wet[0], 1)


# --- add_fire_stacks_to_enemy ---

func test_fire_stacks_applied_to_enemy() -> void:
	var s := _make_state()
	s.add_fire_stacks_to_enemy("e1", 3)
	assert_eq(s.enemy_fire.get("e1", 0), 3)


func test_wet_absorbs_incoming_fire_on_enemy() -> void:
	var s := _make_state()
	s.enemy_wet["e1"] = 2
	s.add_fire_stacks_to_enemy("e1", 5)
	assert_eq(s.enemy_fire.get("e1", 0), 3)
	assert_eq(s.enemy_wet.get("e1", 0), 0)


func test_frozen_enemy_thaws_on_fire_and_no_stacks_added() -> void:
	var s := _make_state()
	s.enemy_frozen["e1"] = true
	s.add_fire_stacks_to_enemy("e1", 3)
	assert_false(s.enemy_frozen.has("e1"))
	assert_eq(s.enemy_fire.get("e1", 0), 0)


# --- add_fire_stacks_to_mage ---

func test_fire_stacks_applied_to_mage() -> void:
	var s := _make_state()
	s.add_fire_stacks_to_mage(0, 3)
	assert_eq(s.mage_fire[0], 3)


func test_wet_absorbs_incoming_fire_on_mage() -> void:
	var s := _make_state()
	s.mage_wet[0] = 2
	s.add_fire_stacks_to_mage(0, 5)
	assert_eq(s.mage_fire[0], 3)
	assert_eq(s.mage_wet[0], 0)


func test_frozen_mage_thaws_on_fire_and_no_stacks_added() -> void:
	var s := _make_state()
	s.mage_frozen[0] = true
	s.add_fire_stacks_to_mage(0, 3)
	assert_false(s.mage_frozen[0])
	assert_eq(s.mage_fire[0], 0)


# --- kill_enemy ---

func test_kill_enemy_removes_it_from_hp_tracking() -> void:
	var s := _make_state()
	s.kill_enemy("e1")
	assert_false(s.enemy_hp.has("e1"))


func test_kill_enemy_clears_all_status_effects() -> void:
	var s := _make_state()
	s.enemy_fire["e1"] = 3
	s.enemy_poison["e1"] = 2
	s.enemy_wet["e1"] = 1
	s.enemy_frozen["e1"] = true
	s.enemy_armor["e1"] = 5
	s.kill_enemy("e1")
	assert_false(s.enemy_fire.has("e1"))
	assert_false(s.enemy_poison.has("e1"))
	assert_false(s.enemy_wet.has("e1"))
	assert_false(s.enemy_frozen.has("e1"))
	assert_false(s.enemy_armor.has("e1"))


# --- duplicate ---

func test_duplicate_is_independent_from_original() -> void:
	var s := _make_state()
	var d := s.duplicate()
	d.enemy_hp["e1"] = 1
	d.mage_hp[0] = 1
	assert_eq(s.enemy_hp["e1"], 20)
	assert_eq(s.mage_hp[0], 30)


func test_duplicate_copies_all_values() -> void:
	var s := _make_state()
	s.mana = 7
	s.enemy_fire["e1"] = 4
	s.mage_poison[0] = 2
	var d := s.duplicate()
	assert_eq(d.mana, 7)
	assert_eq(d.enemy_fire.get("e1", 0), 4)
	assert_eq(d.mage_poison[0], 2)
