extends GutTest


func _make_wand() -> WandData:
	var s0 := SpellSlotData.new("s0", 0, 0, "s1")
	var s1 := SpellSlotData.new("s1", 1, 0, "tip")
	var tip := SpellSlotData.new("tip", 2, 0)
	s0.spell = SpellData.new("Ember", "Em", ["fire"], Color.RED, [], "", 3)
	s1.spell = SpellData.new("Frost", "Fr", ["water"], Color.BLUE, [], "", 2)
	tip.spell = SpellData.new("Single", "·", ["tip"], Color.WHITE, [Vector2i(0, 0)], "", 6)
	return WandData.new([s0, s1, tip])


func test_get_tip_slot_returns_slot_with_no_next_id() -> void:
	var wand := _make_wand()
	var tip := wand.get_tip_slot()
	assert_not_null(tip)
	assert_true(tip.is_tip)


func test_get_tip_slot_returns_null_when_no_tip() -> void:
	var s0 := SpellSlotData.new("s0", 0, 0, "s1")
	var wand := WandData.new([s0])
	assert_null(wand.get_tip_slot())


func test_get_slot_finds_by_id() -> void:
	var wand := _make_wand()
	var slot := wand.get_slot("s1")
	assert_not_null(slot)
	assert_eq(slot.id, "s1")


func test_get_slot_returns_null_for_missing_id() -> void:
	var wand := _make_wand()
	assert_null(wand.get_slot("nonexistent"))


func test_get_total_damage_sums_all_slot_spells() -> void:
	var wand := _make_wand()
	# Ember=3, Frost=2, Single=6 → 11
	assert_eq(wand.get_total_damage(), 11)


func test_get_total_damage_zero_when_no_spells() -> void:
	var s0 := SpellSlotData.new("s0", 0, 0, "tip")
	var tip := SpellSlotData.new("tip", 1, 0)
	var wand := WandData.new([s0, tip])
	assert_eq(wand.get_total_damage(), 0)
