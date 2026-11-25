extends GutTest


func test_every_registered_spell_has_a_drawable_rune() -> void:
	for spell in SpellRegistry.all_body_spells() + SpellRegistry.all_tip_spells():
		var letters := SpellRunes.letters(spell.spell_id)
		assert_false(RuneGeometry.normalize(letters).is_empty(), "no rune for %s" % spell.spell_id)


func test_every_alchemy_result_has_three_drawable_parts() -> void:
	for id in SpellRunes.ALCHEMY:
		var parts := SpellRunes.alchemy(id)
		assert_eq(parts.size(), 3, id)
		for p in parts:
			assert_false(RuneGeometry.normalize(p).is_empty(), "%s part %s" % [id, p])


func test_bolts_share_one_rune() -> void:
	assert_eq(SpellRunes.letters("bolt_ne"), "BT")
	assert_true(SpellRunes.is_bolt("bolt_sw"))


func test_unknown_spell_has_no_rune() -> void:
	assert_eq(SpellRunes.letters("nope"), "")
	assert_true(SpellRunes.alchemy("ember").is_empty())
