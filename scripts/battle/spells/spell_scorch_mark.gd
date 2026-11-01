class_name SpellScorchMark

static func create() -> SpellData:
	var s := SpellData.new("Scorch Mark", "SM", ["scorch_mark"], Color(0.85, 0.35, 0.12), [], "", 0, 0,
			"The next spell deals double damage to burning targets.")
	s.spell_id = "scorch_mark"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "status_amp", "status": "fire"}
	return s
