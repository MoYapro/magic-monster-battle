class_name BattleHistory

var _initial_state: BattleState
var _setup: BattleSetup
var _actions: Array[BattleAction] = []


func _init(initial_state: BattleState, setup: BattleSetup) -> void:
	_initial_state = initial_state
	_setup = setup


func push(action: BattleAction) -> BattleState:
	_actions.append(action)
	return current_state()


func undo() -> BattleState:
	if not _actions.is_empty():
		_actions.pop_back()
	return current_state()


func can_undo() -> bool:
	return not _actions.is_empty()


func current_state() -> BattleState:
	var state := _initial_state.duplicate()
	for action: BattleAction in _actions:
		state = action.apply(state, _setup)
	return state
