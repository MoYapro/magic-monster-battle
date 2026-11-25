class_name BattleChrome
extends Node2D
## Battle screen backdrop: background, vignette and the battle/turn counter.
## Drawn behind everything else (negative z_index).

var _counter := ""


func _ready() -> void:
	z_index = -10


func set_counter(battle_number: int, turn: int) -> void:
	_counter = "Battle %d · Turn %d" % [battle_number, turn]
	queue_redraw()


func _draw() -> void:
	EmberDraw.backdrop(self)
	EmberDraw.text(self, Vector2(40, 28), _counter, 17, Palette.COLOR_TEXT_DIM, true)
