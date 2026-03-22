class_name StoneGiant extends EnemyData

func _init() -> void:
	super("stone_giant_1", "Stone Giant", 1000, Vector2i(2, 2), Color(0.50, 0.48, 0.44))
	main_role = MonsterRole.Type.DRAIN_TANK
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 70
	traits = [MonsterTraitArmor.new(50)]
	drop_pool = [SpellShield.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Crush", 28),
		MonsterActionAttack.new("Boulder Throw", 20),
		MonsterActionHeal.new("Mend Stone", 60),
	]
