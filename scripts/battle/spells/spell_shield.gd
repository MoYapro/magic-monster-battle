class_name SpellShield

static func create() -> SpellData:
	return SpellData.new("Shield", "Sh", ["shield"], Color(0.65, 0.75, 0.90), [], "", 0, 2,
			"Raises a barrier to absorb damage.")
