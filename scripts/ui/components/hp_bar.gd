class_name HpBar
extends Control
## HP bar: remaining HP, then the incoming hit, then status losses; shield overlays the right end.

var hp := 0
var max_hp := 1
var incoming := 0
var shield := 0
var status_losses: Array[int] = []
var status_colors: Array[Color] = []
var fill := Palette.COLOR_HP_FULL


func set_values(p_hp: int, p_max: int, p_incoming := 0, p_shield := 0) -> void:
	hp = p_hp
	max_hp = p_max
	incoming = p_incoming
	shield = p_shield
	queue_redraw()


func _draw() -> void:
	EmberDraw.hp_bar(self, Rect2(Vector2.ZERO, size), hp, max_hp, incoming, status_losses, status_colors, shield, fill)
