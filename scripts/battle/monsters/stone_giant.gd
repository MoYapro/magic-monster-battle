class_name StoneGiant extends EnemyData

func _init() -> void:
	super("stone_giant_1", "Stone Giant", 180, Vector2i(1, 2), Color(0.50, 0.48, 0.44))
	main_role = MonsterRole.Type.DRAIN_TANK
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 52
	traits = [MonsterTraitArmor.new(50)]
	drop_pool = [SpellShield.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Crush", 15),
		MonsterActionAttack.new("Boulder Throw", 10),
		MonsterActionHeal.new("Mend Stone", 30),
	]
