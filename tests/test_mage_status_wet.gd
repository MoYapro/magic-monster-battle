extends GutTest


func _make_state() -> BattleState:
	var s := BattleState.new()
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


# --- on_turn_end ---

func test_wet_decays_by_one_per_turn() -> void:
	var state := _make_state()
	var wet := MageStatusWet.new(3)
	state.mage_statuses[0].append(wet)
	wet.on_turn_end(state, _make_setup(), 0)
	assert_eq(wet.stacks, 2)


func test_wet_is_removed_when_depleted() -> void:
	var state := _make_state()
	var wet := MageStatusWet.new(1)
	state.mage_statuses[0].append(wet)
	wet.on_turn_end(state, _make_setup(), 0)
	assert_eq(state.mage_statuses[0].size(), 0)


func test_wet_deals_no_damage() -> void:
	var state := _make_state()
	var wet := MageStatusWet.new(3)
	state.mage_statuses[0].append(wet)
	wet.on_turn_end(state, _make_setup(), 0)
	assert_eq(state.mage_hp[0], 30)


# --- add_mage_status (same type) ---

func test_adding_wet_when_none_exists_creates_one_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusWet.new(3))
	assert_eq(state.mage_statuses[0].size(), 1)


func test_adding_wet_when_wet_exists_merges_stacks() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusWet.new(3))
	state.add_mage_status(0, MageStatusWet.new(2))
	assert_eq((state.mage_statuses[0][0] as MageStatusWet).stacks, 5)


func test_adding_wet_again_does_not_create_second_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusWet.new(3))
	state.add_mage_status(0, MageStatusWet.new(2))
	assert_eq(state.mage_statuses[0].size(), 1)


# --- interaction with fire ---

func test_existing_wet_is_reduced_by_incoming_fire() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusWet.new(5))
	state.add_mage_status(0, MageStatusFire.new(3))
	assert_eq((state.mage_statuses[0][0] as MageStatusWet).stacks, 2)


func test_existing_wet_is_removed_when_fire_fully_absorbs_it() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusWet.new(3))
	state.add_mage_status(0, MageStatusFire.new(5))
	assert_false(state.mage_statuses[0].any(func(s: MageStatusData) -> bool: return s is MageStatusWet))


func test_fire_remainder_is_added_when_it_outlasts_wet() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusWet.new(2))
	state.add_mage_status(0, MageStatusFire.new(5))
	var fire: Array = state.mage_statuses[0].filter(func(s: MageStatusData) -> bool: return s is MageStatusFire)
	assert_eq((fire[0] as MageStatusFire).stacks, 3)


func test_incoming_wet_fully_absorbed_by_fire_is_not_added() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusFire.new(5))
	state.add_mage_status(0, MageStatusWet.new(3))
	assert_false(state.mage_statuses[0].any(func(s: MageStatusData) -> bool: return s is MageStatusWet))
