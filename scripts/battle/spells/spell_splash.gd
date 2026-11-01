class_name SpellSplash

static func create() -> SpellData:
	var s := SpellData.new("Splash", "Sp", ["splash"], Color(0.50, 0.80, 0.85), [], "", 0, 0,
			"The next spell splashes into neighbouring cells for half damage.")
	s.spell_id = "splash"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "splash"}
	return s
