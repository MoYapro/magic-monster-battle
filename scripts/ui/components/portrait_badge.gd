class_name PortraitBadge
extends Control
## Round portrait with an HP ring around it and status icons along the bottom edge.

const RING_WIDTH := 4.0

@export var color := Color("#d9a032")
@export var selected := false:
	set(v):
		selected = v
		queue_redraw()
var hp := 1
var max_hp := 1
var dead := false
var statuses: Array[String] = []  # short icon strings, e.g. "☠2"


func set_hp(p_hp: int, p_max: int) -> void:
	hp = p_hp
	max_hp = p_max
	dead = p_hp <= 0
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0 - RING_WIDTH - 2.0
	EmberDraw.medallion(self, c, r - RING_WIDTH, color, selected, dead)
	draw_arc(c, r, 0.0, TAU, 48, Palette.COLOR_HP_BG, RING_WIDTH, true)
	if not dead and max_hp > 0:
		var frac := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * frac, 48, Palette.COLOR_HP_FULL, RING_WIDTH, true)
	_draw_statuses(c, r)


func _draw_statuses(c: Vector2, r: float) -> void:
	for i in statuses.size():
		var p := c + Vector2((i - (statuses.size() - 1) / 2.0) * 22.0, r + 2.0)
		EmberDraw.rounded_rect(self, Rect2(p - Vector2(10, 8), Vector2(20, 16)), Palette.COLOR_HP_BG, Palette.COLOR_BORDER, 1, 3)
		EmberDraw.text_centered(self, p.x, p.y + 4.0, statuses[i], 10, Palette.COLOR_TEXT_BRIGHT)
