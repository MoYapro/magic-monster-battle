class_name MageData

var name: String
var max_hp: int
var current_hp: int


func _init(p_name: String, p_max_hp: int) -> void:
	name = p_name
	max_hp = p_max_hp
	current_hp = p_max_hp
