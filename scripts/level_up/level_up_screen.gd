extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const HEADER_H := 48.0
const BOTTOM_BAR_H := 38.0

const CARD_W := 340.0
const CARD_H := 210.0
const CARD_GAP := 30.0
const CARD_Y := HEADER_H + (SCREEN_H - HEADER_H - BOTTOM_BAR_H - CARD_H) * 0.5
const CARDS_TOTAL_W := 3.0 * CARD_W + 2.0 * CARD_GAP
const CARD_MARGIN := (SCREEN_W - CARDS_TOTAL_W) * 0.5

const OPTION_H := 50.0
const OPTION_PAD := 12.0
const HP_GAIN := 10
const MANA_GAIN := 1

const COLOR_BG             := Color(0.07, 0.08, 0.09)
const COLOR_HEADER_BG      := Color(0.08, 0.09, 0.11)
const COLOR_BORDER         := Color(0.22, 0.26, 0.30)
const COLOR_CARD           := Color(0.10, 0.12, 0.14)
const COLOR_SECTION        := Color(0.45, 0.52, 0.60)
const COLOR_MAGE_NAME      := Color(0.85, 0.90, 0.95)
const COLOR_STAT           := Color(0.65, 0.72, 0.80)
const COLOR_GAIN           := Color(0.35, 0.85, 0.45)
const COLOR_OPTION_BG      := Color(0.13, 0.16, 0.18)
const COLOR_SELECTED_BG    := Color(0.12, 0.30, 0.18)
const COLOR_SELECTED_BORDER := Color(0.30, 0.80, 0.40)
const COLOR_TITLE          := Color(0.85, 0.90, 0.95)

var _mages: Array[MageData] = []
var _selected_mage: int = -1
var _selected_stat: String = ""
var _confirm_button: Button = null


func _ready() -> void:
	_mages = GameState.mages
	_build_bottom_bar()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), COLOR_BG, true)
	_draw_header()
	for i in _mages.size():
		_draw_mage_card(i)
	_draw_bottom_bar_bg()


func _draw_header() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, HEADER_H)), COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, HEADER_H - 1), Vector2(SCREEN_W, 1)), COLOR_BORDER, true)
	draw_string(ThemeDB.fallback_font,
			Vector2(SCREEN_W * 0.5, HEADER_H * 0.5 + 9.0),
			"Level Up", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, COLOR_TITLE)


func _card_x(i: int) -> float:
	return CARD_MARGIN + i * (CARD_W + CARD_GAP)


func _option_rect(mage_i: int, stat: String) -> Rect2:
	var x := _card_x(mage_i) + OPTION_PAD
	var w := CARD_W - OPTION_PAD * 2.0
	var y := CARD_Y + 50.0 + (0.0 if stat == "hp" else OPTION_H + 8.0)
	return Rect2(Vector2(x, y), Vector2(w, OPTION_H))


func _draw_mage_card(i: int) -> void:
	var mage := _mages[i]
	var x := _card_x(i)
	draw_rect(Rect2(Vector2(x, CARD_Y), Vector2(CARD_W, CARD_H)), COLOR_CARD, true)
	draw_rect(Rect2(Vector2(x, CARD_Y), Vector2(CARD_W, CARD_H)), COLOR_BORDER, false, 1.0)
	draw_string(ThemeDB.fallback_font,
			Vector2(x + OPTION_PAD, CARD_Y + 26.0),
			mage.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COLOR_MAGE_NAME)
	_draw_option(i, "hp",   "HP",        mage.max_hp,          HP_GAIN)
	_draw_option(i, "mana", "Mana / turn", mage.mana_allowance, MANA_GAIN)


func _draw_option(mage_i: int, stat: String, label: String, current: int, gain: int) -> void:
	var r := _option_rect(mage_i, stat)
	var selected := _selected_mage == mage_i and _selected_stat == stat
	if selected:
		draw_rect(r, COLOR_SELECTED_BG, true)
		draw_rect(r, COLOR_SELECTED_BORDER, false, 2.0)
	else:
		draw_rect(r, COLOR_OPTION_BG, true)
		draw_rect(r, COLOR_BORDER, false, 1.0)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(r.position.x + 8.0, r.position.y + 16.0),
			label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_SECTION)
	var value_color := COLOR_GAIN if selected else COLOR_STAT
	draw_string(font, Vector2(r.position.x + 8.0, r.position.y + 36.0),
			"%d  →  %d" % [current, current + gain],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, value_color)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	for i in _mages.size():
		for stat in ["hp", "mana"]:
			if _option_rect(i, stat).has_point(pos):
				_selected_mage = i
				_selected_stat = stat
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
	_confirm_button.text = "Confirm →"
	_confirm_button.size = Vector2(148, BOTTOM_BAR_H - 10)
	_confirm_button.position = Vector2(SCREEN_W - 156.0, SCREEN_H - BOTTOM_BAR_H + 5.0)
	_confirm_button.disabled = true
	_confirm_button.pressed.connect(_on_confirm_pressed)
	layer.add_child(_confirm_button)


func _on_confirm_pressed() -> void:
	var mage := _mages[_selected_mage]
	if _selected_stat == "hp":
		mage.max_hp += HP_GAIN
		mage.current_hp = mage.max_hp
	else:
		mage.mana_allowance += MANA_GAIN
	GameState.mages = _mages
	get_tree().change_scene_to_file("res://scenes/world/path_selection_screen.tscn")
