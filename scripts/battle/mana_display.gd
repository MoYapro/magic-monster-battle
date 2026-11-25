class_name ManaDisplay
extends Node2D

const WIDTH := 56.0
const PAD := 8.0

var _current: int = 10
var _max: int = 10
var _height: float = 200.0


func setup(current: int, max_mana: int, height: float) -> void:
	_current = current
	_max = max_mana
	_height = height
	queue_redraw()


const LABEL_H := 22.0


## A tall vial of mana drops: filled drops are mana left to place this turn.
func _draw() -> void:
	var vial := Rect2(Vector2.ZERO, Vector2(WIDTH, _height - LABEL_H))
	EmberDraw.rounded_rect(self, vial, Palette.COLOR_PANEL, Palette.COLOR_BORDER, 1, int(WIDTH / 2.0))
	EmberDraw.rounded_rect(self, vial.grow(-5), Color.TRANSPARENT, Palette.COLOR_INNER_BORDER, 1, int(WIDTH / 2.0) - 5)
	EmberDraw.text_centered(self, WIDTH / 2.0, _height - 5.0, "%d/%d" % [_current, _max], 13, Palette.COLOR_MANA_BORDER, true)
	if _max <= 0:
		return
	var step := minf(30.0, (vial.size.y - PAD * 4.0) / float(_max))
	var top := (vial.size.y - step * _max) / 2.0
	for i in _max:
		var filled := i >= _max - _current  # drops drain from the top
		_draw_drop(Vector2(WIDTH / 2.0, top + step * (i + 0.5)), minf(10.0, step * 0.36), filled)


func _draw_drop(c: Vector2, r: float, filled: bool) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r * 1.9)])
	for i in 13:
		pts.append(c + Vector2.from_angle(-0.25 * PI + i * 1.5 * PI / 12.0) * r)
	if filled:
		draw_colored_polygon(pts, Palette.COLOR_MANA)
		EmberDraw.glow(self, c, r * 2.2, 0.35)
	pts.append(pts[0])
	draw_polyline(pts, Palette.COLOR_MANA_BORDER if filled else Palette.COLOR_MANA_DROPLET.darkened(0.2), 1.2, true)
