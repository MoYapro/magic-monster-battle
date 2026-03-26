class_name SpellFireCatalyst

static func create() -> SpellData:
	var s := SpellData.new("Fire", "Fi", ["fire"], Color(1.00, 0.25, 0.00), [], "", 2, 1,
			"Channels fire to catalyze reactions, or burns on its own.")
	s.spell_id = "fire_catalyst"
	s.spell_type = "catalyst"
	s.on_hit_effects = [{"type": "fire", "stacks": 1}]
	return s
