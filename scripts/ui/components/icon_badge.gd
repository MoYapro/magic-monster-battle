class_name IconBadge
extends Control
## Small round badge with a symbol, used as the leading icon of detail rows.

var symbol := ""
var color := Palette.COLOR_ACCENT


func _init(p_symbol := "", p_color := Palette.COLOR_ACCENT) -> void:
	symbol = p_symbol
	color = p_color
	custom_minimum_size = Vector2(36, 36)


func _draw() -> void:
	var c := size / 2.0
	draw_circle(c, 16.0, Palette.COLOR_HP_BG)
	draw_arc(c, 16.0, 0.0, TAU, 32, color, 1.5, true)
	EmberDraw.text_centered(self, c.x, c.y + 5.0, symbol, 14, color)
