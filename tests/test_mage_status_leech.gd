extends GutTest

const LEECHER_ID := "leecher"
const LEECHER_MAX_HP := 40


func _make_state() -> BattleState:
	var s := BattleState.new()
	s.mage_hp.append(30)
	s.mage_mana_spent.append(0)
	s.mage_statuses.append([])
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


func _make_setup_with_leecher() -> BattleSetup:
	var leecher := EnemyData.new(LEECHER_ID, "Leecher", LEECHER_MAX_HP, Vector2i(0, 0), Color.RED)
	return BattleSetup.new([leecher], [Vector2i(0, 0)], [], [], 10)


# --- on_mana_spent ---

func test_leech_heals_source_by_one_per_mana_spent() -> void:
	var state := _make_state()
	state.enemy_hp[LEECHER_ID] = 20
	var leech := MageStatusLeech.new(LEECHER_ID)
	leech.on_mana_spent(state, _make_setup_with_leecher(), 0)
	assert_eq(state.enemy_hp[LEECHER_ID], 21)


func test_leech_does_not_heal_beyond_max_hp() -> void:
	var state := _make_state()
	state.enemy_hp[LEECHER_ID] = LEECHER_MAX_HP
	var leech := MageStatusLeech.new(LEECHER_ID)
	leech.on_mana_spent(state, _make_setup_with_leecher(), 0)
	assert_eq(state.enemy_hp[LEECHER_ID], LEECHER_MAX_HP)


func test_leech_no_crash_when_source_is_dead() -> void:
	var state := _make_state()  # leecher not in enemy_hp
	var leech := MageStatusLeech.new(LEECHER_ID)
	leech.on_mana_spent(state, _make_setup_with_leecher(), 0)
	assert_false(state.enemy_hp.has(LEECHER_ID))


# --- on_turn_end ---

func test_leech_self_removes_on_turn_end() -> void:
	var state := _make_state()
	var leech := MageStatusLeech.new(LEECHER_ID)
	state.mage_statuses[0].append(leech)
	leech.on_turn_end(state, _make_setup(), 0)
	assert_eq(state.mage_statuses[0].size(), 0)
