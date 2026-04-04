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
	s.add_enemy_status("e1", StatusFire.new(3))
	var fire: StatusFire = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFire)[0]
	assert_eq(fire.stacks, 3)


func test_poison_stacks_accumulate_when_applied_twice() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusPoison.new(3))
	s.add_enemy_status("e1", StatusPoison.new(2))
	var poisons: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusPoison)
	assert_eq(poisons.size(), 1, "should merge into one poison entry")
	assert_eq((poisons[0] as StatusPoison).stacks, 5, "stacks should accumulate (3+2=5)")


func test_poison_stacks_accumulate_on_duplicate_state() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusPoison.new(3))
	var d := s.duplicate()
	d.add_enemy_status("e1", StatusPoison.new(2))
	var poisons: Array = (d.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusPoison)
	assert_eq(poisons.size(), 1, "should merge into one poison entry after duplicate")
	assert_eq((poisons[0] as StatusPoison).stacks, 5, "stacks should accumulate on duplicate (3+2=5)")


func _frozen_stacks_after(wet: int, incoming_frozen: int) -> int:
	var s := _make_state()
	s.add_enemy_status("e1", StatusWet.new(wet))
	s.add_enemy_status("e1", StatusFrozen.new(incoming_frozen))
	var frozen: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFrozen)
	return (frozen[0] as StatusFrozen).stacks if frozen.size() > 0 else 0


func test_3_wet_plus_1_frozen_gives_1_frozen() -> void:
	assert_eq(_frozen_stacks_after(3, 1), 1)


func test_12_wet_plus_1_frozen_gives_2_frozen() -> void:
	assert_eq(_frozen_stacks_after(12, 1), 2)


func test_29_wet_plus_1_frozen_gives_3_frozen() -> void:
	assert_eq(_frozen_stacks_after(29, 1), 3)


func test_3_wet_plus_2_frozen_gives_2_frozen() -> void:
	assert_eq(_frozen_stacks_after(3, 2), 2)


func test_wet_is_removed_when_frozen_applied() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusWet.new(15))
	s.add_enemy_status("e1", StatusFrozen.new())
	var wets: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusWet)
	assert_eq(wets.size(), 0)


func test_wet_absorbs_incoming_fire_on_enemy() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusWet.new(2))
	s.add_enemy_status("e1", StatusFire.new(5))
	var fires: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFire)
	var wets: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusWet)
	assert_eq((fires[0] as StatusFire).stacks, 3)
	assert_eq(wets.size(), 0)


func test_frozen_enemy_thaws_on_fire_and_no_fire_added() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusFrozen.new())
	s.add_enemy_status("e1", StatusFire.new(3))
	var frozen: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFrozen)
	var fires: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFire)
	assert_eq(frozen.size(), 0)
	assert_eq(fires.size(), 0)


func test_frost_on_burning_extinguishes_fire() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusFire.new(4))
	s.add_enemy_status("e1", StatusFrozen.new())
	var fires: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFire)
	assert_eq(fires.size(), 0)


func test_frost_on_burning_applies_no_frozen() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusFire.new(4))
	s.add_enemy_status("e1", StatusFrozen.new())
	var frozen: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFrozen)
	assert_eq(frozen.size(), 0)


func test_frost_on_burning_applies_2_wet() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusFire.new(4))
	s.add_enemy_status("e1", StatusFrozen.new())
	var wets: Array = (s.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusWet)
	assert_eq(wets.size(), 1)
	assert_eq((wets[0] as StatusWet).stacks, 2)


# --- kill_enemy ---

func test_kill_enemy_removes_it_from_hp_tracking() -> void:
	var s := _make_state()
	s.kill_enemy("e1")
	assert_false(s.enemy_hp.has("e1"))


func test_kill_enemy_clears_all_status_effects() -> void:
	var s := _make_state()
	s.add_enemy_status("e1", StatusFire.new(3))
	s.add_enemy_status("e1", StatusPoison.new(2))
	s.add_enemy_status("e1", StatusWet.new(1))
	s.add_enemy_status("e1", StatusFrozen.new())
	s.enemy_armor["e1"] = 5
	s.kill_enemy("e1")
	assert_false(s.enemy_statuses.has("e1"))
	assert_false(s.enemy_armor.has("e1"))


func test_kill_enemy_removes_mage_statuses_linked_to_that_enemy() -> void:
	var s := _make_state()
	s.mage_statuses[0].append(StatusVineSnare.new("e1"))
	s.kill_enemy("e1")
	assert_eq(s.mage_statuses[0].size(), 0)


func test_kill_enemy_does_not_remove_statuses_from_other_enemies() -> void:
	var s := _make_state()
	s.enemy_hp["e2"] = 10
	s.mage_statuses[0].append(StatusVineSnare.new("e2"))
	s.kill_enemy("e1")
	assert_eq(s.mage_statuses[0].size(), 1)


func test_kill_enemy_does_not_remove_statuses_without_source() -> void:
	var s := _make_state()
	s.mage_statuses[0].append(StatusFrozen.new())
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
	s.add_enemy_status("e1", StatusFire.new(4))
	s.mage_hp[0] = 15
	var d := s.duplicate()
	assert_eq(d.mana, 7)
	var fires: Array = (d.enemy_statuses["e1"] as Array).filter(
			func(x: StatusData) -> bool: return x is StatusFire)
	assert_eq((fires[0] as StatusFire).stacks, 4)
	assert_eq(d.mage_hp[0], 15)
