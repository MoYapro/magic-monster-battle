class_name Scorpion extends EnemyData

func _init() -> void:
	super("scorpion_1", "Scorpion", 45, Vector2i(1, 1), Color(0.70, 0.55, 0.20))
	main_role = MonsterRole.Type.DAMAGE
	difficulty_rating = 20
	traits = [MonsterTraitVenom.new(5)]
	drop_pool = [SpellVenom.create(), SpellEmber.create()]
	action_pool = [
		MonsterActionAttack.new("Sting", 7),
		MonsterActionAttack.new("Claw", 4),
		MonsterActionAttack.new("Venom Sting", 5),
	]
