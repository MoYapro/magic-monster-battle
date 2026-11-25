class_name ModalLayer
extends CanvasLayer
## Dims the screen and shows one panel above everything. Closable modals close on Escape,
## on a click outside the panel and through close(); `closed` fires once.

signal closed

const DIM := Color(0.03, 0.02, 0.01, 0.62)

var closable := true
var _dim := ColorRect.new()


func _init(p_closable := true) -> void:
	closable = p_closable
	layer = 10
	_dim.color = DIM
	_dim.position = Vector2(-4000, -4000)  # oversized so the expanded side areas dim as well
	_dim.size = Vector2(9000, 9000)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)


func show_panel(panel: Control) -> void:
	add_child(panel)


func close() -> void:
	closed.emit()
	queue_free()


func _on_dim_input(event: InputEvent) -> void:
	if closable and event is InputEventMouseButton and event.pressed:
		close()


func _unhandled_key_input(event: InputEvent) -> void:
	if closable and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
