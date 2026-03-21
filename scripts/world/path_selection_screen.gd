extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const HEADER_H := 48.0
const BOTTOM_BAR_H := 38.0

const CARD_W := 500.0
const CARD_H := 360.0
const CARD_GAP := 40.0
const CARDS_TOTAL_W := 2.0 * CARD_W + CARD_GAP
const CARD_X_LEFT  := (SCREEN_W - CARDS_TOTAL_W) * 0.5
const CARD_X_RIGHT := CARD_X_LEFT + CARD_W + CARD_GAP
const CARD_Y := HEADER_H + (SCREEN_H - HEADER_H - BOTTOM_BAR_H - CARD_H) * 0.5

const COLOR_BG           := Color(0.07, 0.08, 0.09)
const COLOR_HEADER_BG    := Color(0.08, 0.09, 0.11)
const COLOR_BORDER       := Color(0.22, 0.26, 0.30)
const COLOR_CARD         := Color(0.10, 0.12, 0.14)
const COLOR_TITLE        := Color(0.85, 0.90, 0.95)
const COLOR_TAGLINE      := Color(0.50, 0.57, 0.65)
const COLOR_SELECTED_BG  := Color(0.08, 0.10, 0.12)

var _choices: Array[BiomeData] = []
var _selected: int = -1
var _confirm_button: Button = null


func _ready() -> void:
	_pick_choices()
	_build_bottom_bar()


func _pick_choices() -> void:
	var pool := BiomeData.all()
	pool.shuffle()
	_choices = [pool[0], pool[1]]


func _card_x(i: int) -> float:
	return CARD_X_LEFT if i == 0 else CARD_X_RIGHT


func _card_rect(i: int) -> Rect2:
	return Rect2(Vector2(_card_x(i), CARD_Y), Vector2(CARD_W, CARD_H))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), COLOR_BG, true)
	_draw_header()
	for i in _choices.size():
		_draw_card(i)
	_draw_bottom_bar_bg()


func _draw_header() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, HEADER_H)), COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, HEADER_H - 1), Vector2(SCREEN_W, 1)), COLOR_BORDER, true)
	draw_string(ThemeDB.fallback_font,
			Vector2(SCREEN_W * 0.5, HEADER_H * 0.5 + 9.0),
			"Choose your path", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, COLOR_TITLE)


func _draw_card(i: int) -> void:
	var biome := _choices[i]
	var r := _card_rect(i)
	var selected := _selected == i

	# Background with biome colour tint
	var tint := biome.color
	tint.a = 0.18 if selected else 0.08
	draw_rect(r, COLOR_CARD, true)
	draw_rect(r, tint, true)

	# Border — brighter when selected
	var border_color := Color(biome.color, 0.90) if selected else Color(biome.color, 0.35)
	draw_rect(r, border_color, false, 2.5 if selected else 1.5)

	var font := ThemeDB.fallback_font
	var lx := r.position.x

	# Biome name
	var name_color := Color(biome.color.r * 1.4, biome.color.g * 1.4, biome.color.b * 1.4).clamp()
	draw_string(font,
			Vector2(lx, r.position.y + CARD_H * 0.42),
			biome.name, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 32, name_color)

	# Tagline
	draw_string(font,
			Vector2(lx + 20.0, r.position.y + CARD_H * 0.42 + 38.0),
			biome.tagline, HORIZONTAL_ALIGNMENT_CENTER, CARD_W - 40.0, 13, COLOR_TAGLINE)

	# Level
	var level: int = GameState.battle_count_by_biome.get(biome.name, 0) + 1
	draw_string(font,
			Vector2(lx, r.position.y + CARD_H * 0.42 + 66.0),
			"Level %d" % level, HORIZONTAL_ALIGNMENT_CENTER, CARD_W, 12, COLOR_TAGLINE)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	for i in _choices.size():
		if _card_rect(i).has_point(pos):
			_selected = i
			_confirm_button.disabled = false
			queue_redraw()
			get_viewport().set_input_as_handled()
			return


func _draw_bottom_bar_bg() -> void:
	var bar_y := SCREEN_H - BOTTOM_BAR_H
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(SCREEN_W, BOTTOM_BAR_H)), COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(SCREEN_W, 1)), COLOR_BORDER, true)


func _build_bottom_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_confirm_button = Button.new()
	_confirm_button.text = "Venture forth →"
	_confirm_button.size = Vector2(164, BOTTOM_BAR_H - 10)
	_confirm_button.position = Vector2(SCREEN_W - 172.0, SCREEN_H - BOTTOM_BAR_H + 5.0)
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	layer.add_child(_confirm_button)


func _on_confirm_pressed() -> void:
	GameState.current_biome = _choices[_selected]
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
