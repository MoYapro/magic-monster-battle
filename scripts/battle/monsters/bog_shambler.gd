class_name BogShambler extends EnemyData

func _init() -> void:
	super("bog_shambler_1", "Bog Shambler", 70, Vector2i(1, 1), Color(0.22, 0.35, 0.18))
	main_role = MonsterRole.Type.CROWD_CONTROLLER
	difficulty_rating = 22
	drop_pool = [SpellVenom.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Mudslap", 5),
		MonsterActionAttack.new("Entangle", 4),
		MonsterActionAttack.new("Bog Slam", 7),
	]
