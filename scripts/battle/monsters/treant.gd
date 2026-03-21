class_name Treant extends EnemyData

func _init() -> void:
	super("treant_1", "Treant", 650, Vector2i(1, 2), Color(0.30, 0.22, 0.10))
	main_role = MonsterRole.Type.TANK
	off_role = MonsterRole.Type.SUSTAINER
	difficulty_rating = 60
	traits = [MonsterTraitRegen.new(10)]
	drop_pool = [SpellShield.create(), SpellVenom.create()]
	action_pool = [
		MonsterActionAttack.new("Bash", 19),
		MonsterActionAttack.new("Root", 8),
		MonsterActionHeal.new("Regrow", 45),
	]
