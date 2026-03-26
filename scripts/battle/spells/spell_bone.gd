class_name SpellBone

static func create() -> SpellData:
	var s := SpellData.new("Bone", "Bn", ["death"], Color(0.85, 0.85, 0.75), [], "", 2, 1,
			"Deals necrotic damage with bone shards.")
	s.spell_id = "bone"
	s.spell_type = "projectile"
	return s
