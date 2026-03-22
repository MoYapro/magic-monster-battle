class_name SpellData

var display_name: String
var abbreviation: String
var tags: Array[String]
var element_color: Color
var hit_pattern: Array[Vector2i]
var icon: String
var damage: int
var mana_cost: int
var description: String


func _init(p_name: String, p_abbrev: String, p_tags: Array[String], p_color: Color,
		p_pattern: Array[Vector2i] = [], p_icon: String = "", p_damage: int = 0,
		p_mana_cost: int = 1, p_description: String = "") -> void:
	display_name = p_name
	abbreviation = p_abbrev
	tags = p_tags
	element_color = p_color
	hit_pattern = p_pattern
	icon = p_icon
	damage = p_damage
	mana_cost = p_mana_cost
	description = p_description
