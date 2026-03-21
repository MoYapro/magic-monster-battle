class_name BoneCaller extends EnemyData

func _init() -> void:
	super("bone_caller_1", "Bone Caller", 60, Vector2i(1, 1), Color(0.75, 0.72, 0.65))
	main_role = MonsterRole.Type.SUMMONER
	difficulty_rating = 38
	drop_pool = [SpellVenom.create(), SpellPierce.create()]
	action_pool = [
		MonsterActionAttack.new("Dark Bolt", 9),
		MonsterActionAttack.new("Bone Spike", 15),
	]
