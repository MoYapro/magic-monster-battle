extends GutTest

const SNARER_ID := "snarer"
const SNARER_MAX_HP := 50


func _make_state() -> BattleState:
	var s := BattleState.new()
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


func _make_setup_with_snarer() -> BattleSetup:
	var snarer := EnemyData.new(SNARER_ID, "Snarer", SNARER_MAX_HP, Vector2i(0, 0), Color.GREEN)
	return BattleSetup.new([snarer], [Vector2i(0, 0)], [], [], 10)


func _state_with_live_snarer() -> BattleState:
	var state := _make_state()
	state.enemy_hp[SNARER_ID] = 20
	return state


# --- on_zap ---

func test_vine_snare_applies_half_hp_penalty_on_zap() -> void:
	var state := _state_with_live_snarer()
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_zap(state, _make_setup_with_snarer(), 0)
	assert_eq(state.mage_hp[0], 15)  # ceil(30/2) = 15 penalty


func test_vine_snare_heals_snarer_by_penalty_amount() -> void:
	var state := _state_with_live_snarer()
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_zap(state, _make_setup_with_snarer(), 0)
	assert_eq(state.enemy_hp[SNARER_ID], 35)  # 20 + 15


func test_vine_snare_heal_does_not_exceed_snarer_max_hp() -> void:
	var state := _make_state()
	state.enemy_hp[SNARER_ID] = 45  # close to max
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_zap(state, _make_setup_with_snarer(), 0)
	assert_eq(state.enemy_hp[SNARER_ID], SNARER_MAX_HP)


func test_vine_snare_self_removes_after_zap() -> void:
	var state := _state_with_live_snarer()
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_zap(state, _make_setup_with_snarer(), 0)
	assert_eq(state.mage_statuses[0].size(), 0)


func test_vine_snare_still_applies_penalty_when_snarer_is_dead() -> void:
	var state := _make_state()  # snarer not in enemy_hp
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_zap(state, _make_setup(), 0)
	assert_eq(state.mage_hp[0], 15)


func test_vine_snare_no_heal_when_snarer_is_dead() -> void:
	var state := _make_state()
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_zap(state, _make_setup(), 0)
	assert_false(state.enemy_hp.has(SNARER_ID))


# --- on_turn_end ---

func test_vine_snare_self_removes_on_turn_end_without_zapping() -> void:
	var state := _make_state()
	var snare := MageStatusVineSnare.new(SNARER_ID)
	state.mage_statuses[0].append(snare)
	snare.on_turn_end(state, _make_setup(), 0)
	assert_eq(state.mage_statuses[0].size(), 0)
