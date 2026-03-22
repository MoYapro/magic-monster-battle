class_name SpellSingle

static func create() -> SpellData:
	return SpellData.new("Single", "·", ["tip", "single"], Color(0.90, 0.90, 0.90),
			[Vector2i(0, 0)], "", 6, 1, "Strikes a single target with focused force.")
