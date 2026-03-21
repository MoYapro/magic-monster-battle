class_name FrostMage extends EnemyData

func _init() -> void:
	super("frost_mage_1", "Frost Mage", 55, Vector2i(1, 1), Color(0.55, 0.80, 0.95))
	main_role = MonsterRole.Type.MAGE
	difficulty_rating = 28
	drop_pool = [SpellFrost.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Ice Bolt", 8),
		MonsterActionAttack.new("Blizzard", 6),
		MonsterActionAttack.new("Frost Nova", 10),
	]
