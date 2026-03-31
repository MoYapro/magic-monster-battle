extends GutTest


func _make_state() -> BattleState:
	var s := BattleState.new()
	s.enemy_hp["e1"] = 20
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	return s


# --- add_enemy_status ---

func test_fire_stacks_applied_to_enemy() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", MonsterStatusFire.new(3))
	var fire: MonsterStatusFire = (s.enemy_statuses["e1"] as Array).filter(
			func(x: MonsterStatusData) -> bool: return x is MonsterStatusFire)[0]
	assert_eq(fire.stacks, 3)


func test_wet_absorbs_incoming_fire_on_enemy() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", MonsterStatusWet.new(2))
	s.add_enemy_status("e1", MonsterStatusFire.new(5))
	var fires: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: MonsterStatusData) -> bool: return x is MonsterStatusFire)
	var wets: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: MonsterStatusData) -> bool: return x is MonsterStatusWet)
	assert_eq((fires[0] as MonsterStatusFire).stacks, 3)
	assert_eq(wets.size(), 0)


func test_frozen_enemy_thaws_on_fire_and_no_fire_added() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", MonsterStatusFrozen.new())
	s.add_enemy_status("e1", MonsterStatusFire.new(3))
	var frozen: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: MonsterStatusData) -> bool: return x is MonsterStatusFrozen)
	var fires: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: MonsterStatusData) -> bool: return x is MonsterStatusFire)
	assert_eq(frozen.size(), 0)
	assert_eq(fires.size(), 0)


# --- kill_enemy ---

func test_kill_enemy_removes_it_from_hp_tracking() -> void:
	var s := _make_state()
	s.kill_enemy("e1")
	assert_false(s.enemy_hp.has("e1"))


func test_kill_enemy_clears_all_status_effects() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", MonsterStatusFire.new(3))
	s.add_enemy_status("e1", MonsterStatusPoison.new(2))
	s.add_enemy_status("e1", MonsterStatusWet.new(1))
	s.add_enemy_status("e1", MonsterStatusFrozen.new())
	s.enemy_armor["e1"] = 5
	s.kill_enemy("e1")
	assert_false(s.enemy_statuses.has("e1"))
	assert_false(s.enemy_armor.has("e1"))


func test_kill_enemy_removes_mage_statuses_linked_to_that_enemy() -> void:
	var s := _make_state()
	s.mage_statuses[0].append(MageStatusVineSnare.new("e1"))
	s.kill_enemy("e1")
	assert_eq(s.mage_statuses[0].size(), 0)


func test_kill_enemy_does_not_remove_statuses_from_other_enemies() -> void:
	var s := _make_state()
	s.enemy_hp["e2"] = 10
	s.mage_statuses[0].append(MageStatusVineSnare.new("e2"))
	s.kill_enemy("e1")
	assert_eq(s.mage_statuses[0].size(), 1)


func test_kill_enemy_does_not_remove_statuses_without_source() -> void:
	var s := _make_state()
	s.mage_statuses[0].append(MageStatusFrozen.new())
	s.kill_enemy("e1")
	assert_eq(s.mage_statuses[0].size(), 1)


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
	s.add_enemy_status("e1", MonsterStatusFire.new(4))
	s.mage_hp[0] = 15
	var d := s.duplicate()
	assert_eq(d.mana, 7)
	var fires: Array = (d.enemy_statuses["e1"] as Array).filter(
			func(x: MonsterStatusData) -> bool: return x is MonsterStatusFire)
	assert_eq((fires[0] as MonsterStatusFire).stacks, 4)
	assert_eq(d.mage_hp[0], 15)
