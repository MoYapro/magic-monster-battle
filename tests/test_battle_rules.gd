extends GutTest


func _enemy(id: String, actions: Array[MonsterActionData]) -> EnemyData:
	var e := EnemyData.new(id, id, 20, Vector2i(1, 1), Color.WHITE)
	e.action_pool = actions
	return e


func _setup_with(enemies: Array[EnemyData], tip_spell: SpellData = null, allowance: int = 5) -> BattleSetup:
	var body := SpellSlotData.new("s0", 0, 0, "tip")
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = tip_spell
	var wands: Array[WandData] = [WandData.new([body, tip])]
	var mages: Array[MageData] = [MageData.new("A", 30, allowance), MageData.new("B", 30, allowance)]
	wands.append(WandData.new([SpellSlotData.new("tip", 0, 0)]))
	var positions: Array[Vector2i] = []
	for i in enemies.size():
		positions.append(Vector2i(i, 0))
	return BattleSetup.new(enemies, positions, mages, wands, 10)


func _state(mage_hps: Array = [30, 30]) -> BattleState:
	var s := BattleState.new()
	for hp: int in mage_hps:
		var ms := MageState.new()
		ms.combatant.hp = hp
		s.mages.append(ms)
	return s


func _add_enemy(s: BattleState, id: String, intent: Dictionary) -> EnemyState:
	var es := EnemyState.new()
	es.combatant.hp = 10
	es.intent = intent
	s.enemies[id] = es
	return es


# --- incoming attack ---

func _attack_setup() -> BattleSetup:
	var a: Array[MonsterActionData] = [MonsterActionAttack.new("Hit", 4), MonsterActionCleave.new("Cleave", 3)]
	var b: Array[MonsterActionData] = [MonsterActionAttack.new("Hit", 7)]
	return _setup_with([_enemy("a", a), _enemy("b", b)] as Array[EnemyData])


func test_incoming_attack_sums_targeting_enemies() -> void:
	var s := _state()
	_add_enemy(s, "a", {"target": 0, "action_index": 0})
	_add_enemy(s, "b", {"target": 0, "action_index": 0})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 11)


func test_incoming_attack_ignores_other_target() -> void:
	var s := _state()
	_add_enemy(s, "a", {"target": 1, "action_index": 0})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 0)
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 1), 4)


func test_incoming_attack_counts_all_mages_intent() -> void:
	var s := _state()
	_add_enemy(s, "a", {"all_mages": true, "action_index": 1})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 3)
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 1), 3)


func test_incoming_attack_skips_empty_intent() -> void:
	var s := _state()
	_add_enemy(s, "a", {})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 0)


func test_incoming_attack_skips_blocked_enemy() -> void:
	var s := _state()
	var es := _add_enemy(s, "a", {"target": 0, "action_index": 0})
	es.combatant.statuses.append(StatusFrozen.new(1))
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 0)


func test_incoming_attack_skips_out_of_range_action() -> void:
	var s := _state()
	_add_enemy(s, "b", {"target": 0, "action_index": 1})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 0)


func test_incoming_attack_defaults_action_index_zero() -> void:
	var s := _state()
	_add_enemy(s, "b", {"target": 0})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 7)


func test_incoming_attack_skips_unknown_enemy() -> void:
	var s := _state()
	_add_enemy(s, "ghost", {"target": 0, "action_index": 0})
	assert_eq(BattleRules.incoming_attack(s, _attack_setup(), 0), 0)


func test_incoming_attack_ignores_non_damage_actions() -> void:
	var acts: Array[MonsterActionData] = [MonsterActionTakeCover.new()]
	var setup := _setup_with([_enemy("a", acts)] as Array[EnemyData])
	var s := _state()
	_add_enemy(s, "a", {"target": 0, "action_index": 0})
	assert_eq(BattleRules.incoming_attack(s, setup, 0), 0)


# --- outcome ---

func test_outcome_lost_when_all_mages_dead() -> void:
	var s := _state([0, -3])
	_add_enemy(s, "a", {})
	assert_eq(BattleRules.outcome(s, true), BattleRules.Outcome.LOST)


func test_outcome_lost_takes_priority_over_won() -> void:
	assert_eq(BattleRules.outcome(_state([0, 0]), true), BattleRules.Outcome.LOST)


func test_outcome_won_when_enemies_gone_after_action() -> void:
	assert_eq(BattleRules.outcome(_state([0, 5]), true), BattleRules.Outcome.WON)


func test_outcome_not_won_without_any_action() -> void:
	assert_eq(BattleRules.outcome(_state(), false), BattleRules.Outcome.ONGOING)


func test_outcome_ongoing_with_enemies_alive() -> void:
	var s := _state()
	_add_enemy(s, "a", {})
	assert_eq(BattleRules.outcome(s, true), BattleRules.Outcome.ONGOING)


# --- tip click ---

func _tip_spell(cost: int) -> SpellData:
	return SpellData.new("Tip", "T", ["tip"], Color.WHITE, [], "", 1, cost)


func test_tip_click_dead_mage_does_nothing() -> void:
	var setup := _setup_with([] as Array[EnemyData], _tip_spell(2))
	assert_eq(BattleRules.tip_click(_state([0, 30]), setup, 0), BattleRules.TipClick.NONE)


func test_tip_click_tipless_wand_targets() -> void:
	var setup := _setup_with([] as Array[EnemyData], null)
	assert_eq(BattleRules.tip_click(_state(), setup, 0), BattleRules.TipClick.TARGET)


func test_tip_click_wand_without_tip_slot_targets() -> void:
	var setup := _setup_with([] as Array[EnemyData], _tip_spell(2))
	setup.wands[1] = WandData.new([SpellSlotData.new("s0", 0, 0, "x")])
	assert_eq(BattleRules.tip_click(_state(), setup, 1), BattleRules.TipClick.TARGET)


func test_tip_click_uncharged_tip_adds_mana() -> void:
	var setup := _setup_with([] as Array[EnemyData], _tip_spell(2))
	var s := _state()
	(s.mages[0] as MageState).slot_charges["tip"] = 1
	assert_eq(BattleRules.tip_click(s, setup, 0), BattleRules.TipClick.ADD_MANA)


func test_tip_click_charged_tip_with_allowance_targets() -> void:
	var setup := _setup_with([] as Array[EnemyData], _tip_spell(2), 5)
	var s := _state()
	(s.mages[0] as MageState).slot_charges["tip"] = 2
	(s.mages[0] as MageState).mana_spent = 4
	assert_eq(BattleRules.tip_click(s, setup, 0), BattleRules.TipClick.TARGET)


func test_tip_click_charged_tip_without_allowance_does_nothing() -> void:
	var setup := _setup_with([] as Array[EnemyData], _tip_spell(2), 5)
	var s := _state()
	(s.mages[0] as MageState).slot_charges["tip"] = 2
	(s.mages[0] as MageState).mana_spent = 5
	assert_eq(BattleRules.tip_click(s, setup, 0), BattleRules.TipClick.NONE)


func test_is_mage_dead() -> void:
	var s := _state([0, 1])
	assert_true(BattleRules.is_mage_dead(s, 0))
	assert_false(BattleRules.is_mage_dead(s, 1))


# --- hp sync ---

func test_sync_current_hp_copies_mage_and_living_enemy_hp() -> void:
	var setup := _attack_setup()
	var s := _state([12, 0])
	_add_enemy(s, "a", {}).combatant.hp = 6
	setup.enemies[1].current_hp = 9
	BattleRules.sync_current_hp(s, setup)
	assert_eq(setup.mages[0].current_hp, 12)
	assert_eq(setup.mages[1].current_hp, 0)
	assert_eq(setup.enemies[0].current_hp, 6)
	assert_eq(setup.enemies[1].current_hp, 9, "dead enemies keep their last hp")


# --- debug placement ---

func test_occupied_cells_cover_footprints() -> void:
	var occ := BattleRules.occupied_cells([Vector2i(1, 1)] as Array[Vector2i], [Vector2i(2, 2)] as Array[Vector2i])
	assert_eq(occ.size(), 4)
	assert_true(occ.has(Vector2i(2, 2)))


func test_can_place_on_free_cells() -> void:
	assert_true(BattleRules.can_place(Vector2i(0, 0), Vector2i(2, 2), {}))


func test_cannot_place_overlapping() -> void:
	assert_false(BattleRules.can_place(Vector2i(0, 0), Vector2i(2, 2), {Vector2i(1, 1): true}))


func test_cannot_place_past_grid_edge() -> void:
	assert_false(BattleRules.can_place(Vector2i(EnemyGrid.COLS - 1, 0), Vector2i(2, 1), {}))
	assert_false(BattleRules.can_place(Vector2i(0, EnemyGrid.ROWS - 1), Vector2i(1, 2), {}))
	assert_true(BattleRules.can_place(Vector2i(EnemyGrid.COLS - 1, EnemyGrid.ROWS - 1), Vector2i(1, 1), {}))
