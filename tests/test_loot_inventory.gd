extends GutTest

const GameStateScript := preload("res://scripts/game_state.gd")

var _run: Node
var _inv: LootInventory


func before_each() -> void:
	_run = autofree(GameStateScript.new())
	_inv = LootInventory.new(_run)


func _spell(id: String, tags: Array[String] = []) -> SpellData:
	var s := SpellData.new(id, id, tags, Color.WHITE, [], "", 0, 0, "")
	s.spell_id = id
	s.spell_type = "projectile"
	return s


func _catalyst(id: String) -> SpellData:
	var s := _spell(id)
	s.spell_type = "catalyst"
	return s


func _tip_spell() -> SpellData:
	return _spell("single", ["tip"] as Array[String])


func _wand() -> WandData:
	var s0 := SpellSlotData.new("s0", 0, 0, "s1")
	var s1 := SpellSlotData.new("s1", 1, 0, "s2")
	var s2 := SpellSlotData.new("s2", 2, 0, "tip")
	return WandData.new([s0, s1, s2, SpellSlotData.new("tip", 3, 0)])


func _fill_backpack(count: int) -> void:
	for i in count:
		_run.backpack.append(_spell("b%d" % i))


func _add_mage(max_hp: int = 30, mana: int = 5) -> MageData:
	var m := MageData.new("M", max_hp, mana)
	_run.mages.append(m)
	return m


# --- model is backed by the run ---

func test_reads_and_writes_go_to_the_run() -> void:
	var s := _spell("x")
	_inv.pending_loot.append(s)
	assert_eq(_run.pending_loot, [s])


# --- taking loot ---

func test_take_loot_removes_and_returns_spell() -> void:
	var a := _spell("a")
	var b := _spell("b")
	_run.pending_loot.append_array([a, b])
	assert_eq(_inv.take_loot(0), a)
	assert_eq(_run.pending_loot, [b])


func test_take_loot_respects_pick_limit() -> void:
	for i in LootRoller.MAX_PICKS + 1:
		var d := _spell("d%d" % i)
		_run.battle_drops.append(d)
		_run.pending_loot.append(d)
	for i in LootRoller.MAX_PICKS:
		assert_not_null(_inv.take_loot(0))
	assert_false(_inv.can_take_loot(0))
	assert_null(_inv.take_loot(0))
	assert_eq(_run.pending_loot.size(), 1, "blocked drop stays in loot")
	assert_eq(_inv.picks_used(), LootRoller.MAX_PICKS)


func test_non_drop_loot_ignores_pick_limit() -> void:
	for i in LootRoller.MAX_PICKS:
		_run.battle_drops.append(_spell("d%d" % i))
	var extra := _spell("extra")
	_run.pending_loot.append(extra)
	assert_true(_inv.can_take_loot(0))
	assert_eq(_inv.take_loot(0), extra)


func test_returning_a_drop_frees_the_pick() -> void:
	var d := _spell("d")
	_run.battle_drops.append(d)
	_run.pending_loot.append(d)
	_inv.take_loot(0)
	assert_eq(_inv.picks_used(), 1)
	_inv.drop_spell(d, LootInventory.Area.LOOT, LootInventory.Area.LOOT)
	assert_eq(_inv.picks_used(), 0)


func test_take_backpack() -> void:
	_fill_backpack(2)
	var first: SpellData = _run.backpack[0]
	assert_eq(_inv.take_backpack(0), first)
	assert_eq(_run.backpack.size(), 1)


func test_take_from_slot_empties_slot() -> void:
	var slot := SpellSlotData.new("s0", 0, 0, "tip")
	var s := _spell("a")
	slot.spell = s
	assert_eq(LootInventory.take_from_slot(slot), s)
	assert_null(slot.spell)


# --- drop destinations ---

func test_drop_on_loot_panel_goes_to_loot() -> void:
	var s := _spell("a")
	_inv.drop_spell(s, LootInventory.Area.LOOT, LootInventory.Area.BACKPACK)
	assert_eq(_run.pending_loot, [s])


func test_drop_on_backpack_with_room_goes_to_backpack() -> void:
	var s := _spell("a")
	_inv.drop_spell(s, LootInventory.Area.BACKPACK, LootInventory.Area.LOOT)
	assert_eq(_run.backpack, [s])


func test_drop_on_full_backpack_returns_to_loot_source() -> void:
	_fill_backpack(LootInventory.BACKPACK_SLOTS)
	var s := _spell("a")
	_inv.drop_spell(s, LootInventory.Area.BACKPACK, LootInventory.Area.LOOT)
	assert_eq(_run.pending_loot, [s])
	assert_eq(_run.backpack.size(), LootInventory.BACKPACK_SLOTS)


func test_drop_on_full_backpack_from_backpack_still_goes_to_backpack() -> void:
	_fill_backpack(LootInventory.BACKPACK_SLOTS)
	var s := _spell("a")
	_inv.drop_spell(s, LootInventory.Area.BACKPACK, LootInventory.Area.BACKPACK)
	assert_eq(_run.backpack.size(), LootInventory.BACKPACK_SLOTS + 1)


func test_drop_elsewhere_returns_to_source() -> void:
	var a := _spell("a")
	var b := _spell("b")
	_inv.drop_spell(a, LootInventory.Area.NONE, LootInventory.Area.LOOT)
	_inv.drop_spell(b, LootInventory.Area.NONE, LootInventory.Area.BACKPACK)
	assert_eq(_run.pending_loot, [a])
	assert_eq(_run.backpack, [b])


# --- slots ---

func test_fits_slot_requires_tip_tag_match() -> void:
	var body := SpellSlotData.new("s0", 0, 0, "tip")
	var tip := SpellSlotData.new("tip", 1, 0)
	assert_true(LootInventory.fits_slot(body, _spell("a")))
	assert_false(LootInventory.fits_slot(body, _tip_spell()))
	assert_true(LootInventory.fits_slot(tip, _tip_spell()))
	assert_false(LootInventory.fits_slot(tip, _spell("a")))


func test_place_puts_spell_in_slot() -> void:
	var wand := _wand()
	_run.wands.append(wand)
	_add_mage()
	var s := _spell("a")
	assert_null(_inv.place_in_slot(0, wand.get_slot("s0"), s))
	assert_eq(wand.get_slot("s0").spell, s)


func test_displaced_spell_goes_to_backpack() -> void:
	var wand := _wand()
	_run.wands.append(wand)
	_add_mage()
	var old := _spell("old")
	wand.get_slot("s0").spell = old
	_inv.place_in_slot(0, wand.get_slot("s0"), _spell("new"))
	assert_eq(_run.backpack, [old])


func test_displaced_spell_goes_to_loot_when_backpack_full() -> void:
	var wand := _wand()
	_run.wands.append(wand)
	_add_mage()
	_fill_backpack(LootInventory.BACKPACK_SLOTS)
	var old := _spell("old")
	wand.get_slot("s0").spell = old
	_inv.place_in_slot(0, wand.get_slot("s0"), _spell("new"))
	assert_eq(_run.pending_loot, [old])


func test_displaced_tip_goes_to_backpack() -> void:
	var wand := _wand()
	_run.wands.append(wand)
	_add_mage()
	var old := _tip_spell()
	wand.get_slot("tip").spell = old
	_inv.place_in_slot(0, wand.get_slot("tip"), _tip_spell())
	assert_eq(_run.backpack, [old])


# --- fusion costs ---

func _fuse_with(cat: String, r1: String, r2: String) -> Dictionary:
	var wand := _wand()
	_run.wands.append(wand)
	var mage := _add_mage(31, 4)
	wand.get_slot("s0").spell = _catalyst(cat)
	wand.get_slot("s1").spell = _spell(r1)
	var result := _inv.place_in_slot(0, wand.get_slot("s2"), _spell(r2))
	return {"result": result, "mage": mage}


func test_fizzle_sets_mana_debt() -> void:
	var r := _fuse_with("fire_catalyst", "frost", "venom")
	assert_eq((r.result as AlchemyResult).outcome, AlchemyResult.Outcome.FIZZLE)
	assert_eq((r.mage as MageData).mana_debt, 4)
	assert_eq((r.mage as MageData).hp_penalty, 0)


func test_backfire_sets_half_max_hp_penalty() -> void:
	var r := _fuse_with("force_push", "lightning", "frost")
	assert_eq((r.result as AlchemyResult).outcome, AlchemyResult.Outcome.BACKFIRE)
	assert_eq((r.mage as MageData).hp_penalty, 15)
	assert_eq((r.mage as MageData).mana_debt, 0)


func test_success_costs_nothing() -> void:
	var r := _fuse_with("fire_catalyst", "ember", "ember")
	assert_eq((r.result as AlchemyResult).outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq((r.mage as MageData).hp_penalty, 0)
	assert_eq((r.mage as MageData).mana_debt, 0)


func test_fuse_without_equipped_wand_returns_null() -> void:
	_add_mage()
	assert_null(_inv.try_fuse_wand(0))
	_run.wands.append(null)
	assert_null(_inv.try_fuse_wand(0))


# --- wands ---

func test_equip_pads_wands_with_null() -> void:
	var w := _wand()
	assert_null(_inv.equip_wand(2, w))
	assert_eq(_run.wands.size(), 3)
	assert_null(_run.wands[0])
	assert_eq(_run.wands[2], w)


func test_equip_returns_old_wand_to_loot() -> void:
	var old := _wand()
	var new := _wand()
	_inv.equip_wand(0, old)
	assert_eq(_inv.equip_wand(0, new), old)
	assert_eq(_run.pending_loot_wands, [old])
	assert_eq(_inv.equipped_wand(0), new)


func test_take_and_return_loot_wand() -> void:
	var a := _wand()
	var b := _wand()
	_run.pending_loot_wands.append_array([a, b])
	assert_eq(_inv.take_loot_wand(0), a)
	_inv.return_loot_wand(a)
	assert_eq(_run.pending_loot_wands, [b, a])


func test_auto_assign_in_order() -> void:
	for i in 3:
		_add_mage()
	var wands: Array[WandData] = [_wand(), _wand(), _wand(), _wand()]
	_run.pending_loot_wands.append_array(wands)
	_inv.auto_assign()
	assert_eq(_run.wands, [wands[0], wands[1], wands[2]])
	assert_eq(_run.pending_loot_wands, [wands[3]])


func test_auto_assign_stops_when_out_of_wands() -> void:
	for i in 3:
		_add_mage()
	var w := _wand()
	_run.pending_loot_wands.append(w)
	_inv.auto_assign()
	assert_eq(_inv.equipped_wand(0), w)
	assert_null(_inv.equipped_wand(1))


func test_auto_assign_replaces_equipped_and_cycles_old_wand() -> void:
	_add_mage()
	_add_mage()
	var old := _wand()
	var w := _wand()
	_inv.equip_wand(0, old)
	_run.pending_loot_wands.append(w)
	_inv.auto_assign()
	assert_eq(_inv.equipped_wand(0), w)
	assert_eq(_inv.equipped_wand(1), old, "displaced wand is handed to the next mage")


# --- continue ---

func test_can_continue_outside_initial_setup() -> void:
	_run.is_initial_setup = false
	_add_mage()
	assert_true(_inv.can_continue())


func test_initial_setup_needs_every_mage_armed() -> void:
	_run.is_initial_setup = true
	_add_mage()
	_add_mage()
	assert_false(_inv.can_continue())
	_inv.equip_wand(0, _wand())
	assert_false(_inv.can_continue())
	_inv.equip_wand(1, _wand())
	assert_true(_inv.can_continue())


func test_finish_clears_loot_and_ends_setup() -> void:
	_run.is_initial_setup = true
	_run.pending_loot.append(_spell("a"))
	_run.battle_drops.append(_spell("b"))
	_run.pending_loot_wands.append(_wand())
	_fill_backpack(2)
	_inv.finish()
	assert_true(_run.pending_loot.is_empty())
	assert_true(_run.battle_drops.is_empty())
	assert_true(_run.pending_loot_wands.is_empty())
	assert_false(_run.is_initial_setup)
	assert_eq(_run.backpack.size(), 2, "backpack is kept")
