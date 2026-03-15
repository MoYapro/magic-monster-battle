class_name MageRow
extends Node2D

const MAGE_WIDTH := 80.0
const MAGE_HEIGHT := 62.0
const PAD := 8.0
const BAR_HEIGHT := 8.0

const COLOR_BG := Color(0.15, 0.17, 0.19)
const COLOR_BORDER := Color(0.38, 0.42, 0.48)
const COLOR_HP_FULL := Color(0.20, 0.75, 0.30)
const COLOR_HP_LOW := Color(0.85, 0.20, 0.15)
const COLOR_HP_BG := Color(0.10, 0.11, 0.13)

var _mages: Array[MageData] = []


func setup(mages: Array[MageData]) -> void:
	_mages = mages
	queue_redraw()


func _draw() -> void:
	for i in _mages.size():
		_draw_mage(i, _mages[i])


func _draw_mage(index: int, mage: MageData) -> void:
	var x := float(index) * MAGE_WIDTH
	draw_rect(Rect2(Vector2(x, 0.0), Vector2(MAGE_WIDTH, MAGE_HEIGHT)), COLOR_BG, true)
	draw_rect(Rect2(Vector2(x, 0.0), Vector2(MAGE_WIDTH, MAGE_HEIGHT)), COLOR_BORDER, false, 1.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(x + PAD, PAD + 11.0), mage.name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)

	var bar_y := PAD + 18.0
	var bar_w := MAGE_WIDTH - PAD * 2.0
	draw_rect(Rect2(Vector2(x + PAD, bar_y), Vector2(bar_w, BAR_HEIGHT)), COLOR_HP_BG, true)

	var hp_frac := float(mage.current_hp) / float(mage.max_hp)
	var hp_color := COLOR_HP_FULL.lerp(COLOR_HP_LOW, 1.0 - hp_frac)
	draw_rect(Rect2(Vector2(x + PAD, bar_y), Vector2(bar_w * hp_frac, BAR_HEIGHT)), hp_color, true)

	draw_string(font, Vector2(x + PAD, bar_y + BAR_HEIGHT + 13.0),
			"%d / %d" % [mage.current_hp, mage.max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.65, 0.80, 0.65))
