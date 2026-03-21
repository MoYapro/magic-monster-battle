class_name ShieldOgre extends EnemyData

func _init() -> void:
	super("ogre_1", "Shield Ogre", 100, Vector2i(2, 1), Color(0.65, 0.25, 0.15))
	main_role = MonsterRole.Type.TANK
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 40
	traits = [MonsterTraitArmor.new(30)]
	drop_pool = [SpellShield.create(), SpellEmber.create()]
	action_pool = [
		MonsterActionAttack.new("Punch", 8),
		MonsterActionHeal.new("Shield Up", 25),
	]
