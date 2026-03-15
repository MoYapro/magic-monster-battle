class_name BattleAction

func apply(_state: BattleState, _setup: BattleSetup) -> BattleState:
	return _state.duplicate()
