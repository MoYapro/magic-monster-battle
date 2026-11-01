class_name SpellHarmony

static func create() -> SpellData:
	var s := SpellData.new("Harmony", "Ha", ["harmony"], Color(0.92, 0.85, 0.95), [], "", 2, 0,
			"Weaves the spells after it into one blast: 2 damage per different spell, plus each spell's own damage and effects.")
	s.spell_id = "harmony"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "harmony"}
	return s
