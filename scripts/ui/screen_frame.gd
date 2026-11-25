extends Node
## Global display setup: the bundled font for text drawn in _draw(), which reads ThemeDB.fallback_font.

const FONT: Font = preload("res://assets/fonts/eb_garamond/EBGaramond-Variable.ttf")


func _ready() -> void:
	ThemeDB.fallback_font = FONT
