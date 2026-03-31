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

func test_poison_deals_one_damage_per_turn() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(3)
	state.mage_statuses[0].append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(state.mage_hp[0], 29)


func test_poison_damage_is_always_one_regardless_of_stacks() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(5)
	state.mage_statuses[0].append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(state.mage_hp[0], 29)


func test_poison_decrements_stacks_each_turn() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(3)
	state.mage_statuses[0].append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(poison.stacks, 2)


func test_poison_is_removed_when_stacks_reach_zero() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(1)
	state.mage_statuses[0].append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(state.mage_statuses[0].size(), 0)


func test_poison_persists_while_stacks_remain() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(3)
	state.mage_statuses[0].append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(state.mage_statuses[0].size(), 1)


# --- add_mage_status (same type) ---

func test_adding_poison_when_none_exists_creates_one_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusPoison.new(2))
	assert_eq(state.mage_statuses[0].size(), 1)


func test_adding_poison_when_poison_exists_merges_stacks() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusPoison.new(2))
	state.add_mage_status(0, StatusPoison.new(3))
	assert_eq((state.mage_statuses[0][0] as StatusPoison).stacks, 5)


func test_adding_poison_again_does_not_create_second_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusPoison.new(2))
	state.add_mage_status(0, StatusPoison.new(3))
	assert_eq(state.mage_statuses[0].size(), 1)
