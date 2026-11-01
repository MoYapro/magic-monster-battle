class_name SpellConductor

static func create() -> SpellData:
	var s := SpellData.new("Conductor", "Cd", ["conductor"], Color(0.35, 0.70, 0.95), [], "", 0, 0,
			"The next spell deals double damage to wet targets.")
	s.spell_id = "conductor"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "status_amp", "status": "wet"}
	return s
