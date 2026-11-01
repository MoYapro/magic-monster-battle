class_name SpellDetonate

static func create() -> SpellData:
	var s := SpellData.new("Detonate", "Dt", ["fire"], Color(0.80, 0.20, 0.05), [], "", 0, 1,
			"Ignites the fire on its target: all fire stacks burst into the eight surrounding cells.")
	s.spell_id = "detonate"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "detonate", "mult": 1}]
	return s
