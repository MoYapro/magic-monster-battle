class_name Treant extends EnemyData

func _init() -> void:
	super("treant_1", "Treant", 130, Vector2i(1, 2), Color(0.30, 0.22, 0.10))
	main_role = MonsterRole.Type.TANK
	off_role = MonsterRole.Type.SUSTAINER
	difficulty_rating = 45
	traits = [MonsterTraitRegen.new(10)]
	drop_pool = [SpellShield.create(), SpellVenom.create()]
	action_pool = [
		MonsterActionAttack.new("Bash", 11),
		MonsterActionAttack.new("Root", 5),
		MonsterActionHeal.new("Regrow", 20),
	]
