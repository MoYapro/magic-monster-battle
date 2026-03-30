extends GutTest


func _make_state() -> BattleState:
	var s := BattleState.new()
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


# --- blocks_zap ---

func test_frozen_reports_blocks_zap() -> void:
	assert_true(MageStatusFrozen.new().blocks_zap())


# --- on_add_status (fire interaction) ---

func test_frozen_absorbs_all_incoming_fire() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusFrozen.new())
	state.add_mage_status(0, MageStatusFire.new(5))
	assert_false(state.mage_statuses[0].any(func(s: MageStatusData) -> bool: return s is MageStatusFire))


func test_frozen_is_removed_when_fire_is_applied() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusFrozen.new())
	state.add_mage_status(0, MageStatusFire.new(5))
	assert_false(state.mage_statuses[0].any(func(s: MageStatusData) -> bool: return s is MageStatusFrozen))


func test_frozen_absorbs_fire_regardless_of_stack_count() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusFrozen.new())
	state.add_mage_status(0, MageStatusFire.new(99))
	assert_eq(state.mage_statuses[0].size(), 0)


# --- persistence ---

func test_frozen_persists_without_fire() -> void:
	var state := _make_state()
	var frozen := MageStatusFrozen.new()
	state.mage_statuses[0].append(frozen)
	frozen.on_turn_end(state, _make_setup(), 0)
	assert_eq(state.mage_statuses[0].size(), 1)


func test_frozen_unaffected_by_wet() -> void:
	var state := _make_state()
	state.add_mage_status(0, MageStatusFrozen.new())
	state.add_mage_status(0, MageStatusWet.new(3))
	assert_true(state.mage_statuses[0].any(func(s: MageStatusData) -> bool: return s is MageStatusFrozen))
