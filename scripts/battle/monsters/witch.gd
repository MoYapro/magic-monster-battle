class_name Witch extends EnemyData

func _init() -> void:
	super("witch_1", "Witch", 45, Vector2i(1, 1), Color(0.55, 0.1, 0.7))
	main_role = MonsterRole.Type.MAGE
	off_role = MonsterRole.Type.HEALER
	difficulty_rating = 30
	drop_pool = [SpellVenom.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Curse", 4),
		MonsterActionAttack.new("Hex", 9),
		MonsterActionHeal.new("Brew", 18),
	]
