class_name WarDrummer extends EnemyData

func _init() -> void:
	super("war_drummer_1", "War Drummer", 65, Vector2i(1, 1), Color(0.70, 0.35, 0.15))
	description = "A battle drummer whose war cry emboldens nearby enemies to fight harder."
	main_role = MonsterRole.Type.BUFFER
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 30
	drop_pool = [SpellAmplify.create(), SpellEmber.create()]
	action_pool = [
		MonsterActionDrumsOfWar.new(),
		MonsterActionHeal.new("War Cry", 20),
	]
