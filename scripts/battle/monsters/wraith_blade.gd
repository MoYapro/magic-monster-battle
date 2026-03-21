class_name WraithBlade extends EnemyData

func _init() -> void:
	super("wraith_blade_1", "Wraith Blade", 30, Vector2i(1, 1), Color(0.25, 0.15, 0.35))
	main_role = MonsterRole.Type.ASSASSIN
	difficulty_rating = 22
	traits = [MonsterTraitBlock.new(1)]
	drop_pool = [SpellPierce.create(), SpellSingle.create()]
	action_pool = [
		MonsterActionAttack.new("Shadow Strike", 10),
		MonsterActionAttack.new("Backstab", 14),
	]
