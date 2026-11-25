class_name RigLayer
extends RefCounted
## One exported image of a rig: drawn on `joint` at `pos` (top-left, rig pixels) with draw order `z`.
## Paper-rim layers use low z so the rim stays below every body part.

var file: String
var joint: String
var z: int
var pos: Vector2


func _init(p_file: String, p_joint: String, p_z: int, p_pos: Vector2) -> void:
	file = p_file
	joint = p_joint
	z = p_z
	pos = p_pos
