class_name RigJoint
extends RefCounted
## One movable body part of a monster rig: its pivot (in rig pixels) and parent joint.

var name: String
var pivot: Vector2
var parent: String


func _init(p_name: String, p_pivot: Vector2, p_parent: String) -> void:
	name = p_name
	pivot = p_pivot
	parent = p_parent
