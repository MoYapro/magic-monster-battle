extends Node
## Global display setup: bundled font for text drawn in _draw(), and the 1280x720 layout centred
## in any window. Aspect "expand" grows the viewport; the extra space shows the dark clear colour.

const FONT: Font = preload("res://assets/fonts/eb_garamond/EBGaramond-Variable.ttf")
const DESIGN_SIZE := Vector2(1280, 720)


func _ready() -> void:
	ThemeDB.fallback_font = FONT
	get_tree().root.size_changed.connect(_center_layout)
	_center_layout()


func _center_layout() -> void:
	var root := get_tree().root
	root.global_canvas_transform = Transform2D(0.0, centering_offset(root.get_visible_rect().size))


static func centering_offset(visible_size: Vector2) -> Vector2:
	return ((visible_size - DESIGN_SIZE) / 2.0).floor()
