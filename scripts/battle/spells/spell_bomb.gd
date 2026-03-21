class_name SpellBomb

static func create() -> SpellData:
	return SpellData.new("Bomb", "", ["tip", "aoe"], Color(0.25, 0.25, 0.28),
			[Vector2i(-1,-1), Vector2i(-1, 0), Vector2i(-1, 1),
			 Vector2i( 0,-1), Vector2i( 0, 0), Vector2i( 0, 1),
			 Vector2i( 1,-1), Vector2i( 1, 0), Vector2i( 1, 1)], "bomb", 3, 3)
