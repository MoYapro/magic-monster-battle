class_name CastEvent

enum Type { PROJECTILE, FIZZLE, BACKFIRE }

var type: int  # Type enum value

# PROJECTILE fields
var spell: SpellData
var total_damage: int
var on_hit_effects: Array[Dictionary]
var on_kill_effects: Array[Dictionary]
var mana_refund: int
var zap_mana_cost: int = 0  # total mana spent firing this zap; used by on_kill_effects
var bounces: int = 0  # number of additional targets to chain to after initial hit
var corrupted: bool = false  # consume existing status stacks on target as bonus damage
var reactive: bool = false   # branch on target's existing conditions at hit time
var sunder: bool = false     # each damage point strips two armor
var status_amps: Array[String] = []  # distinct statuses ("fire"/"wet"/"poison") that double damage
var splash: int = 0          # 1: orthogonal neighbours, 2+: all 8 surrounding cells

# BACKFIRE fields
var backfire_damage: int
var backfire_effects: Array[Dictionary]
