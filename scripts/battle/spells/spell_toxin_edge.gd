class_name SpellToxinEdge

static func create() -> SpellData:
	var s := SpellData.new("Toxin Edge", "TE", ["toxin_edge"], Color(0.45, 0.80, 0.25), [], "", 0, 0,
			"The next spell deals double damage to poisoned targets.")
	s.spell_id = "toxin_edge"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "status_amp", "status": "poison"}
	return s
