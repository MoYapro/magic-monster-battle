class_name Troll extends EnemyData

func _init() -> void:
	super("troll_1", "Troll", 80, Vector2i(1, 2), Color(0.3, 0.5, 0.2))
	main_role = MonsterRole.Type.SUSTAINER
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 35
	traits = [MonsterTraitRegen.new(15)]
	drop_pool = [SpellVenom.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Smash", 7),
		MonsterActionHeal.new("Regenerate", 20),
		MonsterActionAttack.new("Throw", 4),
	]
