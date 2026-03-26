class_name SpellForcePush

static func create() -> SpellData:
	var s := SpellData.new("Force Push", "FP", ["force"], Color(0.90, 0.80, 0.20), [], "", 3, 1,
			"Smashes reagents together, or pushes enemies with blunt force.")
	s.spell_id = "force_push"
	s.spell_type = "catalyst"
	return s
