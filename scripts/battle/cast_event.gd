class_name CastEvent

enum Type { PROJECTILE, FIZZLE, BACKFIRE }

var type: int  # Type enum value

# PROJECTILE fields
var spell: SpellData
var total_damage: int
var on_hit_effects: Array[Dictionary]
var mana_refund: int

# BACKFIRE fields
var backfire_damage: int
var backfire_effects: Array[Dictionary]
