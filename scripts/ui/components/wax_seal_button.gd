class_name WaxSealButton
extends BaseButton
## Crimson wax seal used for the screen's main action (End Turn, Claim Spoils, ...).

@export var line1 := "END":
	set(v):
		line1 = v
		queue_redraw()
@export var line2 := "TURN":
	set(v):
		line2 = v
		queue_redraw()
@export var radius := 34.0:
	set(v):
		radius = v
		_update_size()


func _ready() -> void:
	_update_size()
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _update_size() -> void:
	custom_minimum_size = Vector2.ONE * (radius + 12.0) * 2.0
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	return point.distance_to(size / 2.0) <= radius


func _draw() -> void:
	var r := radius * (0.96 if is_pressed() else 1.0)
	EmberDraw.wax_seal(self, size / 2.0, r, line1, line2, is_hovered(), disabled)
