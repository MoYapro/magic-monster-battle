class_name SpellData

var display_name: String
var abbreviation: String
var tags: Array[String]
var element_color: Color
var hit_pattern: Array[Vector2i]
var ignores_los: bool
var icon: String
var damage: int


func _init(p_name: String, p_abbrev: String, p_tags: Array[String], p_color: Color,
		p_pattern: Array[Vector2i] = [], p_ignores_los: bool = false,
		p_icon: String = "", p_damage: int = 0) -> void:
	display_name = p_name
	abbreviation = p_abbrev
	tags = p_tags
	element_color = p_color
	hit_pattern = p_pattern
	ignores_los = p_ignores_los
	icon = p_icon
	damage = p_damage
