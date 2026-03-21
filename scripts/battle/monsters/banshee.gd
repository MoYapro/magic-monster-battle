class_name Banshee extends EnemyData

func _init() -> void:
	super("banshee_1", "Banshee", 40, Vector2i(1, 1), Color(0.75, 0.85, 0.95))
	main_role = MonsterRole.Type.DEBUFFER
	difficulty_rating = 28

	traits = [MonsterTraitFire.new()]
	drop_pool = [SpellEmber.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Wail", 9),
		MonsterActionAttack.new("Soul Drain", 12),
	]
