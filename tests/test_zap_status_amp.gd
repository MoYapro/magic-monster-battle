extends GutTest


func _slot(id: String, col: int, row: int, next_id: String, spell: SpellData) -> SpellSlotData:
	var s := SpellSlotData.new(id, col, row, next_id)
	s.spell = spell
	return s


func _strike() -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


func _setup(slots: Array) -> BattleSetup:
	var wand_slots: Array[SpellSlotData] = []
	wand_slots.assign(slots + [_slot("tip", 9, 0, "", SpellSingle.create())])
	return BattleSetup.new([EnemyData.new("e1", "Target", 50, Vector2i(1, 1), Color.RED)] as Array[EnemyData],
			[Vector2i(2, 3)] as Array[Vector2i], [MageData.new("Mage", 30)] as Array[MageData],
			[WandData.new(wand_slots)] as Array[WandData], 10)


func _zap(slots: Array, statuses: Array = [], armor: int = 0) -> int:
	var setup := _setup(slots)
	var state := BattleState.new()
	var es := EnemyState.new()
	es.combatant.hp = 50
	es.armor = armor
	es.combatant.statuses.assign(statuses)
	state.enemies["e1"] = es
	var ms := MageState.new()
	ms.combatant.hp = 30
	for slot: SpellSlotData in setup.wands[0].slots:
		ms.slot_charges[slot.id] = 1
	state.mages.append(ms)
	state.mana = 10
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(state, setup).state
	return (result.enemies["e1"] as EnemyState).combatant.hp


# --- pure helper ---

func test_amp_mult_without_matching_status_is_one() -> void:
	assert_eq(ActionZapWand.status_amp_mult([StatusWet.new(2)], ["fire"] as Array[String]), 1)


func test_amp_mult_with_matching_status_doubles() -> void:
	assert_eq(ActionZapWand.status_amp_mult([StatusFire.new(2)], ["fire"] as Array[String]), 2)


func test_amp_mult_two_matching_amps_quadruple() -> void:
	var statuses := [StatusFire.new(1), StatusPoison.new(1)]
	assert_eq(ActionZapWand.status_amp_mult(statuses, ["fire", "poison", "wet"] as Array[String]), 4)


# --- zap ---

func test_scorch_mark_on_non_burning_target_is_normal() -> void:
	assert_eq(_zap([_slot("sm", 0, 0, "em", SpellScorchMark.create()),
			_slot("em", 1, 0, "tip", SpellEmber.create())]), 47, "Ember's own fire does not amplify it")


func test_scorch_mark_doubles_against_burning_target() -> void:
	assert_eq(_zap([_slot("sm", 0, 0, "em", SpellScorchMark.create()),
			_slot("em", 1, 0, "tip", SpellEmber.create())], [StatusFire.new(1)]), 44)


func test_ember_then_scorch_mark_ember_doubles_second_hit() -> void:
	assert_eq(_zap([_slot("a", 0, 0, "sm", SpellEmber.create()),
			_slot("sm", 1, 0, "b", SpellScorchMark.create()),
			_slot("b", 2, 0, "tip", SpellEmber.create())]), 41, "3 + 3·2")


func test_conductor_doubles_against_wet_target() -> void:
	assert_eq(_zap([_slot("cd", 0, 0, "s", SpellConductor.create()),
			_slot("s", 1, 0, "tip", _strike())], [StatusWet.new(1)]), 40)


func test_toxin_edge_doubles_against_poisoned_target() -> void:
	assert_eq(_zap([_slot("te", 0, 0, "s", SpellToxinEdge.create()),
			_slot("s", 1, 0, "tip", _strike())], [StatusPoison.new(1)]), 40)


func test_two_matching_amps_quadruple() -> void:
	assert_eq(_zap([_slot("sm", 0, 0, "te", SpellScorchMark.create()),
			_slot("te", 1, 0, "s", SpellToxinEdge.create()),
			_slot("s", 2, 0, "tip", _strike())], [StatusFire.new(1), StatusPoison.new(1)]), 30)


func test_duplicate_amp_does_not_multiply_further() -> void:
	assert_eq(_zap([_slot("a", 0, 0, "b", SpellScorchMark.create()),
			_slot("b", 1, 0, "s", SpellScorchMark.create()),
			_slot("s", 2, 0, "tip", _strike())], [StatusFire.new(1)]), 40)


func test_amp_doubles_before_armor() -> void:
	assert_eq(_zap([_slot("sm", 0, 0, "s", SpellScorchMark.create()),
			_slot("s", 1, 0, "tip", _strike())], [StatusFire.new(1)], 4), 44, "10 − 4 armor")


# Em(A) → Strike → tip
# SM(B) ↗
func test_merged_branch_amp_benefits_from_other_branch_fire() -> void:
	assert_eq(_zap([_slot("em", 0, 0, "s", SpellEmber.create()),
			_slot("sm", 0, 1, "s", SpellScorchMark.create()),
			_slot("s", 1, 0, "tip", _strike())]), 32, "Em 3, Strike 5, amplified Strike 10")
