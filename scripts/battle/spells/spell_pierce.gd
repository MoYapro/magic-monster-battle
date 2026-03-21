class_name SpellPierce

static func create() -> SpellData:
	return SpellData.new("Pierce", "→→", ["tip", "pierce"], Color(0.95, 0.55, 0.20),
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "", 4, 2)
