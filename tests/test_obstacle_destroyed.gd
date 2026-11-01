extends GutTest


class RecordingObstacle extends ObstacleData:
	var destroyed_with: Array = []

	func _init(p_hp: int) -> void:
		super("rec_1", "Recorder", Vector2i(1, 1), Color.GRAY, p_hp)

	func on_destroyed(_state: BattleState, _setup: BattleSetup, ev: CastEvent) -> void:
		destroyed_with.append(ev)


func _make_setup(body: Array[SpellSlotData], enemy_pos: Vector2i,
		obstacle: ObstacleData, obstacle_pos: Vector2i) -> BattleSetup:
	var tip := SpellSlotData.new("tip", 9, 0)
	tip.spell = SpellSingle.create()
	var slots: Array[SpellSlotData] = body.duplicate()
	slots.append(tip)
	var enemies: Array[EnemyData] = [EnemyData.new("e1", "Target", 50, Vector2i(1, 1), Color.RED)]
	var mages: Array[MageData] = [MageData.new("Mage", 30)]
	var wands: Array[WandData] = [WandData.new(slots)]
	var obstacles: Array[ObstacleData] = [obstacle]
	return BattleSetup.new(enemies, [enemy_pos] as Array[Vector2i], mages, wands, 10,
			obstacles, [obstacle_pos] as Array[Vector2i])


func _slot(id: String, col: int, next_id: String, spell: SpellData) -> SpellSlotData:
	var s := SpellSlotData.new(id, col, 0, next_id)
	s.spell = spell
	return s


func _zap(setup: BattleSetup, charges: Dictionary, target: Vector2i) -> BattleState:
	var s := BattleState.new()
	var es := EnemyState.new()
	es.combatant.hp = 50
	s.enemies["e1"] = es
	for o: ObstacleData in setup.obstacles:
		var os := ObstacleState.new()
		os.combatant.hp = o.max_hp
		s.obstacles[o.id] = os
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges = charges.merged({"tip": 1})
	s.mages.append(ms)
	s.mana = 10
	return ActionZapWand.new(0, target).apply(s, setup).state


func test_destroy_obstacle_removes_and_notifies() -> void:
	var rec := RecordingObstacle.new(5)
	var setup := _make_setup([_slot("s", 0, "tip", SpellEmber.create())], Vector2i(4, 4), rec, Vector2i(2, 2))
	var state := BattleState.new()
	state.obstacles["rec_1"] = ObstacleState.new()
	state.destroy_obstacle("rec_1", setup)
	assert_false(state.obstacles.has("rec_1"))
	assert_eq(rec.destroyed_with, [null])


func test_destroy_missing_obstacle_does_not_notify() -> void:
	var rec := RecordingObstacle.new(5)
	var setup := _make_setup([_slot("s", 0, "tip", SpellEmber.create())], Vector2i(4, 4), rec, Vector2i(2, 2))
	BattleState.new().destroy_obstacle("rec_1", setup)
	assert_eq(rec.destroyed_with.size(), 0)


func test_direct_hit_destroy_passes_cast_event() -> void:
	var rec := RecordingObstacle.new(2)
	var setup := _make_setup([_slot("s", 0, "tip", SpellEmber.create())], Vector2i(4, 4), rec, Vector2i(2, 2))
	var result := _zap(setup, {"s": 1}, Vector2i(2, 2))
	assert_false(result.obstacles.has("rec_1"))
	assert_eq(rec.destroyed_with.size(), 1)
	assert_not_null(rec.destroyed_with[0])


func test_push_collision_destroy_notifies() -> void:
	var rec := RecordingObstacle.new(1)
	var setup := _make_setup([_slot("fp", 0, "tip", SpellForcePush.create())], Vector2i(1, 2), rec, Vector2i(2, 2))
	var result := _zap(setup, {"fp": 1}, Vector2i(1, 2))
	assert_false(result.obstacles.has("rec_1"))
	assert_eq(rec.destroyed_with, [null])


func test_detonate_destroy_notifies() -> void:
	var rec := RecordingObstacle.new(3)
	var setup := _make_setup([_slot("em", 0, "dt", SpellEmber.create()),
			_slot("dt", 1, "tip", SpellDetonate.create())], Vector2i(2, 3), rec, Vector2i(3, 2))
	var result := _zap(setup, {"em": 1, "dt": 1}, Vector2i(2, 3))
	assert_false(result.obstacles.has("rec_1"))
	assert_eq(rec.destroyed_with, [null])
