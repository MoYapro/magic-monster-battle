class_name MageStatusData extends RefCounted

var source_enemy_id: String = ""
var display_name: String = ""
var display_color: Color = Color.WHITE
# -1 = non-stacked (always added); positive = stacked; 0 = fully absorbed (skip add)
var stacks: int = -1


func get_label() -> String:
	return display_name


# Returns true if this status blocks the mage from zapping entirely.
func blocks_zap() -> bool:
	return false


# Called when the mage attempts to zap their wand (before cast, after block check).
func on_zap(state: BattleState, _setup: BattleSetup, _mage_index: int) -> BattleState:
	return state


# Called each time the mage successfully places one mana unit on a slot.
func on_mana_spent(state: BattleState, _setup: BattleSetup, _mage_index: int) -> BattleState:
	return state


# Called on each existing status when a new status is added to this mage.
# Can modify incoming.stacks (set to 0 to absorb it) or erase self.
func on_add_status(_state: BattleState, _mage_index: int, _incoming: MageStatusData) -> void:
	pass


# Called at end of turn after monsters act. Handles decay, damage-over-time, self-removal.
func on_turn_end(state: BattleState, _setup: BattleSetup, _mage_index: int) -> BattleState:
	return state


# Returns the damage this status will deal this turn (used for HP bar preview).
func get_turn_damage() -> int:
	return 0
