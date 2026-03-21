class_name MageDisplay
extends Node2D

const WIDTH := 80.0
const PAD := 9.0
const BAR_HEIGHT := 9.0

const COLOR_BG      := Color(0.15, 0.17, 0.19)
const COLOR_BG_DEAD := Color(0.35, 0.06, 0.06)
const COLOR_BORDER := Color(0.38, 0.42, 0.48)
const COLOR_HP_FULL := Color(0.20, 0.75, 0.30)
const COLOR_HP_LOW := Color(0.85, 0.20, 0.15)
const COLOR_HP_BG := Color(0.10, 0.11, 0.13)
const COLOR_TARGET_AVAILABLE := Color(1.0, 0.85, 0.2)
const COLOR_TARGET_HOVER     := Color(0.95, 0.18, 0.18)
const COLOR_MANA             := Color(0.35, 0.70, 1.00)
const COLOR_MANA_LABEL       := Color(0.40, 0.50, 0.65)
const COLOR_POISON           := Color(0.50, 0.20, 0.65)
const COLOR_FIRE             := Color(0.95, 0.42, 0.05)

var _mage: MageData = null
var _height: float = 70.0
var _highlighted := false
var _hovered := false
var _mana_committed: int = 0
var _mana_max: int = 0
var _poison: int = 0
var _fire: int = 0


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


func set_mana(committed: int, max_mana: int) -> void:
	_mana_committed = committed
	_mana_max = max_mana
	queue_redraw()


func set_status(poison: int, fire: int) -> void:
	_poison = poison
	_fire = fire
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(WIDTH, _height))


func _draw() -> void:
	if _mage == null:
		return
	var is_dead := _mage.current_hp <= 0
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), COLOR_BG_DEAD if is_dead else COLOR_BG, true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(WIDTH, _height)), COLOR_BORDER, false, 1.0)

	# vertically centre the content block
	var has_status := _poison > 0 or _fire > 0
	var status_count := int(_poison > 0) + int(_fire > 0)
	var content_h := 16.0 + 6.0 + BAR_HEIGHT + 5.0 + 13.0 + 6.0 + 12.0
	if has_status:
		content_h += status_count * (5.0 + 12.0)
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

	var hp_text_y := bar_y + BAR_HEIGHT + 13.0
	draw_string(font, Vector2(PAD, hp_text_y),
			"%d/%d" % [_mage.current_hp, _mage.max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.65, 0.80, 0.65))

	if _mana_max > 0:
		draw_string(font, Vector2(PAD, hp_text_y + 18.0),
				"%d/%d" % [_mana_committed, _mana_max],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_MANA_LABEL)
		draw_string(font, Vector2(WIDTH - PAD, hp_text_y + 18.0),
				"uses", HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, COLOR_MANA_LABEL)
	if has_status:
		var pill_y := hp_text_y + 18.0 + 5.0
		var pill_h := 12.0
		var pill_w := WIDTH - PAD * 2.0
		if _poison > 0:
			var label := "POI %d" % _poison
			draw_rect(Rect2(Vector2(PAD, pill_y), Vector2(pill_w, pill_h)), COLOR_POISON, true)
			draw_string(font, Vector2(PAD + pill_w * 0.5, pill_y + 10.0),
					label, HORIZONTAL_ALIGNMENT_CENTER, pill_w, 9, Color.WHITE)
			pill_y += pill_h + 5.0
		if _fire > 0:
			var label := "FIRE %d" % _fire
			draw_rect(Rect2(Vector2(PAD, pill_y), Vector2(pill_w, pill_h)), COLOR_FIRE, true)
			draw_string(font, Vector2(PAD + pill_w * 0.5, pill_y + 10.0),
					label, HORIZONTAL_ALIGNMENT_CENTER, pill_w, 9, Color.WHITE)

	var r := get_rect()
	if _hovered:
		draw_rect(r, COLOR_TARGET_HOVER, false, 3.0)
	elif _highlighted:
		draw_rect(r, COLOR_TARGET_AVAILABLE, false, 2.5)
