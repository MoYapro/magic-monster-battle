class_name SpellShield

static func create() -> SpellData:
	var s := SpellData.new("Shield", "Sh", ["shield"], Color(0.65, 0.75, 0.90), [], "", 0, 2,
			"Adds a shield on-hit that absorbs damage for the caster.")
	s.spell_id = "shield"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "add_on_hit", "effect": {"type": "self_shield", "amount": 3}}
	return s
