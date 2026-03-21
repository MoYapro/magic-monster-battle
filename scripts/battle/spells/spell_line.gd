class_name SpellLine

static func create() -> SpellData:
	return SpellData.new("Line", "|||", ["tip", "line"], Color(0.30, 0.80, 0.95),
			[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)], "", 4, 2)
