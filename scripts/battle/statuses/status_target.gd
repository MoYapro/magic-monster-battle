class_name StatusTarget extends RefCounted

var _state: BattleState
var _enemy_id: String
var _mage_index: int


static func for_enemy(state: BattleState, enemy_id: String) -> StatusTarget:
	var t := StatusTarget.new()
	t._state = state
	t._enemy_id = enemy_id
	t._mage_index = -1
	return t


static func for_mage(state: BattleState, mage_index: int) -> StatusTarget:
	var t := StatusTarget.new()
	t._state = state
	t._enemy_id = ""
	t._mage_index = mage_index
	return t


func is_enemy() -> bool:
	return not _enemy_id.is_empty()


func get_hp() -> int:
	if is_enemy():
		return _state.enemy_hp.get(_enemy_id, 0)
	return _state.mage_hp[_mage_index]


func set_hp(val: int) -> void:
	if is_enemy():
		_state.enemy_hp[_enemy_id] = val
	else:
		_state.mage_hp[_mage_index] = val


func get_statuses() -> Array:
	if is_enemy():
		return _state.enemy_statuses.get(_enemy_id, [])
	return _state.mage_statuses[_mage_index]


func add_status(s: StatusData) -> void:
	if is_enemy():
		_state.add_enemy_status(_enemy_id, s)
	else:
		_state.add_mage_status(_mage_index, s)


func remove_status(s: StatusData) -> void:
	get_statuses().erase(s)


func kill() -> void:
	if is_enemy():
		_state.kill_enemy(_enemy_id)
	# mage death is detected by battle_scene via hp check


func is_alive() -> bool:
	if is_enemy():
		return _state.enemy_hp.has(_enemy_id)
	return _state.mage_hp[_mage_index] > 0


func get_state() -> BattleState:
	return _state
