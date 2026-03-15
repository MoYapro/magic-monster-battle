class_name MageDisplay
extends Node2D

const WIDTH := 80.0
const PAD := 9.0
const BAR_HEIGHT := 9.0

const COLOR_BG := Color(0.15, 0.17, 0.19)
const COLOR_BORDER := Color(0.38, 0.42, 0.48)
const COLOR_HP_FULL := Color(0.20, 0.75, 0.30)
const COLOR_HP_LOW := Color(0.85, 0.20, 0.15)
const COLOR_HP_BG := Color(0.10, 0.11, 0.13)
const COLOR_HIGHLIGHT := Color(1.0, 0.85, 0.2)

var _mage: MageData = null
var _height: float = 70.0
var _highlighted := false
var _hovered := false


func setup(mage: MageData, height: float) -> void:
	_mage = mage
	_height = height
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(WIDTH, _height))


func _draw() -> void:
	if _mage == null:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), COLOR_BG, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), COLOR_BORDER, false, 1.0)

	# vertically centre the content block
	var content_h := 16.0 + 6.0 + BAR_HEIGHT + 5.0 + 13.0
	var y := (_height - content_h) * 0.5

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(PAD, y + 16.0), _mage.name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

	var bar_y := y + 24.0
	var bar_w := WIDTH - PAD * 2.0
	draw_rect(Rect2(Vector2(PAD, bar_y), Vector2(bar_w, BAR_HEIGHT)), COLOR_HP_BG, true)

	var hp_frac := float(_mage.current_hp) / float(_mage.max_hp)
	var hp_color := COLOR_HP_FULL.lerp(COLOR_HP_LOW, 1.0 - hp_frac)
	draw_rect(Rect2(Vector2(PAD, bar_y), Vector2(bar_w * hp_frac, BAR_HEIGHT)), hp_color, true)

	draw_string(font, Vector2(PAD, bar_y + BAR_HEIGHT + 13.0),
			"%d/%d" % [_mage.current_hp, _mage.max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.80, 0.65))
	var r := get_rect()
	if _highlighted:
		draw_rect(r, Color(COLOR_HIGHLIGHT, 0.12), true)
		draw_rect(r, Color(COLOR_HIGHLIGHT, 0.9), false, 2.5)
	if _hovered:
		draw_rect(r, Color(COLOR_HIGHLIGHT, 0.28), true)
		draw_rect(r, Color(COLOR_HIGHLIGHT, 1.0), false, 3.5)
