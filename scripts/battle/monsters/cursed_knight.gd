class_name CursedKnight extends EnemyData

func _init() -> void:
	super("cursed_knight_1", "Cursed Knight", 250, Vector2i(1, 1), Color(0.28, 0.22, 0.40))
	main_role = MonsterRole.Type.BATTLEMAGE
	off_role = MonsterRole.Type.TANK
	difficulty_rating = 48
	traits = [MonsterTraitArmor.new(20)]
	drop_pool = [SpellEmber.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Curse Strike", 14),
		MonsterActionAttack.new("Dark Slash", 12),
		MonsterActionHeal.new("Dark Mend", 25),
	]
