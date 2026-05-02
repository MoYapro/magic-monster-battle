class_name BattleState

var enemies: Dictionary = {}    # enemy_id   -> EnemyState
var mages: Array[MageState] = []  # index = render slot, never compacted
var obstacles: Dictionary = {}  # obstacle_id -> ObstacleState
var cells: Dictionary = {}      # Vector2i   -> CellState
var mana: int = 0


func duplicate() -> BattleState:
	var s := BattleState.new()
	for eid: String in enemies:
		s.enemies[eid] = (enemies[eid] as EnemyState).duplicate()
	for ms: MageState in mages:
		s.mages.append(ms.duplicate())
	for oid: String in obstacles:
		s.obstacles[oid] = (obstacles[oid] as ObstacleState).duplicate()
	for pos: Vector2i in cells:
		s.cells[pos] = (cells[pos] as CellState).duplicate()
	s.mana = mana
	return s


func get_cell(pos: Vector2i) -> CellState:
	if not cells.has(pos):
		cells[pos] = CellState.new()
	return cells[pos]


func kill_enemy(enemy_id: String) -> void:
	enemies.erase(enemy_id)
	for ms: MageState in mages:
		ms.combatant.statuses.assign(ms.combatant.statuses.filter(
				func(s: StatusData) -> bool: return s.source_enemy_id != enemy_id))


func add_enemy_status(enemy_id: String, new_status: StatusData) -> void:
	if not enemies.has(enemy_id):
		return
	_add_status(StatusTarget.for_enemy(self, enemy_id), new_status)


func add_mage_status(mage_index: int, new_status: StatusData) -> void:
	_add_status(StatusTarget.for_mage(self, mage_index), new_status)


func _add_status(target: StatusTarget, new_status: StatusData) -> void:
	for status: StatusData in target.get_statuses().duplicate():
		status.on_add_status(target, new_status)
	if new_status.stacks != 0:
		target.get_statuses().append(new_status)
