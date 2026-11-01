class_name SpellSunder

static func create() -> SpellData:
	var s := SpellData.new("Sunder", "Su", ["sunder"], Color(0.55, 0.60, 0.68), [], "", 0, 0,
			"The next spell tears through armor: each point of damage strips two points of armor.")
	s.spell_id = "sunder"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "sunder"}
	return s
