class_name SpellBoltW

static func create() -> SpellData:
	return SpellData.new("Bolt ←", "←", ["tip", "bolt"], Color(0.95, 0.85, 0.20),
			[Vector2i(0, 0), Vector2i(-1, 0)], "", 5, 1, "Strikes the target and the enemy to its left.")
