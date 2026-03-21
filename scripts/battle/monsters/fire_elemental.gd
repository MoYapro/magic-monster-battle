class_name FireElemental extends EnemyData

func _init() -> void:
	super("fire_elemental_1", "Fire Elemental", 60, Vector2i(1, 1), Color(0.95, 0.40, 0.05))
	main_role = MonsterRole.Type.MAGE
	difficulty_rating = 32
	traits = [MonsterTraitFire.new()]
	drop_pool = [SpellEmber.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Fire Blast", 9),
		MonsterActionAttack.new("Ignite", 5),
		MonsterActionAttack.new("Flame Wave", 7),
	]
