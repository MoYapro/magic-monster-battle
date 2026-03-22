class_name MonsterActionData

enum TargetType { MAGE, SELF, MONSTER }

var name: String
var target_type: TargetType


func execute(_state: BattleState, _setup: BattleSetup,
		_enemy_id: String, _target: int) -> BattleState:
	return _state.duplicate()
