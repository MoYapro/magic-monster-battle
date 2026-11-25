@tool
class_name RuneIcon
extends Control

# Ember-style spell rune on a dark disc, drawn at runtime at any size.
# Basic spell: set `letters`. Alchemy result: set `catalyst`, `reactant_a`, `reactant_b`
# (reactants on top, catalyst at the bottom).

const DISC_COLOR := Color("1e130c")
const CORE_COLOR := Color("fff3c8")
const ALCHEMY_SPOTS := [Vector2(0.0, 0.27), Vector2(-0.3, -0.2), Vector2(0.3, -0.2)]

@export var color := Color("e0602a"):
	set(v):
		color = v
		queue_redraw()
@export var letters := "F":
	set(v):
		letters = v
		queue_redraw()
@export var catalyst := "":
	set(v):
		catalyst = v
		queue_redraw()
@export var reactant_a := "":
	set(v):
		reactant_a = v
		queue_redraw()
@export var reactant_b := "":
	set(v):
		reactant_b = v
		queue_redraw()


func is_alchemy() -> bool:
	return catalyst != "" and reactant_a != "" and reactant_b != ""


func _draw() -> void:
	var r := minf(size.x, size.y) / 2.0
	var c := size / 2.0
	draw_circle(c, r, DISC_COLOR)
	draw_arc(c, r - r * 0.025, 0.0, TAU, 64, color, r * 0.05, true)
	if is_alchemy():
		_draw_alchemy(c, r)
	else:
		_draw_rune(letters, c, r * 1.05, r * 0.08)


func _draw_alchemy(c: Vector2, r: float) -> void:
	var parts := [catalyst, reactant_a, reactant_b]
	for i in parts.size():
		_draw_rune(parts[i], c + ALCHEMY_SPOTS[i] * r, r * 0.55, r * 0.045)


func _draw_rune(text: String, center: Vector2, box: float, width: float) -> void:
	EmberDraw.rune(self, text, center, box, width, color)
