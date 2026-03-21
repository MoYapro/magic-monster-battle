class_name CaveSpider extends EnemyData

func _init() -> void:
	super("cave_spider_1", "Cave Spider", 35, Vector2i(1, 1), Color(0.18, 0.15, 0.22))
	main_role = MonsterRole.Type.TRAPPER
	difficulty_rating = 18
	traits = [MonsterTraitVenom.new(3)]
	drop_pool = [SpellVenom.create(), SpellShield.create()]
	action_pool = [
		MonsterActionAttack.new("Bite", 6),
		MonsterActionAttack.new("Web Shot", 3),
		MonsterActionAttack.new("Venom Bite", 8),
	]
