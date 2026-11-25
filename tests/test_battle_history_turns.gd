extends GutTest


func _history() -> BattleHistory:
	var enemy := EnemyData.new("e1", "Target", 100, Vector2i(1, 1), Color.RED)
	var enemies: Array[EnemyData] = [enemy]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	var mages: Array[MageData] = [MageData.new("Mage", 30)]
	var setup := BattleSetup.new(enemies, positions, mages, [], 10)
	return BattleHistory.new(setup.make_initial_state(), setup)


func test_first_turn_is_one() -> void:
	assert_eq(_history().turn_number(), 1)


func test_each_end_turn_counts() -> void:
	var history := _history()
	history.push(ActionEndTurn.new(1))
	history.push(ActionEndTurn.new(2))
	assert_eq(history.turn_number(), 3)


func test_undo_takes_the_turn_back() -> void:
	var history := _history()
	history.push(ActionEndTurn.new(1))
	history.undo()
	assert_eq(history.turn_number(), 1)
