class_name SpellFrost

static func create() -> SpellData:
	var s := SpellData.new("Frost", "Fr", ["water", "frost"], Color(0.25, 0.65, 1.00), [], "", 2, 1,
			"Chills enemies with icy cold.")
	s.spell_id = "frost"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "wet", "stacks": 2}]
	return s
