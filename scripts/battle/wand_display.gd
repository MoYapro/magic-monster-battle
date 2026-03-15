class_name WandDisplay
extends Node2D

const SLOT_SIZE := Vector2(50.0, 50.0)
const CELL_SPACING := Vector2(70.0, 60.0)
const PAD := Vector2(16.0, 16.0)
const PAD_BOTTOM := 14.0

const COLOR_BG := Color(0.12, 0.13, 0.15)
const COLOR_BG_BORDER := Color(0.35, 0.40, 0.46)
const COLOR_SLOT_BODY := Color(0.20, 0.23, 0.26)
const COLOR_SLOT_TIP := Color(0.26, 0.18, 0.08)
const COLOR_BORDER_BODY := Color(0.42, 0.48, 0.55)
const COLOR_BORDER_TIP := Color(0.85, 0.65, 0.20)
const COLOR_EDGE := Color(0.45, 0.50, 0.58)

var _data: WandData = null


func setup(wand_data: WandData) -> void:
	_data = wand_data
	queue_redraw()


func get_display_size() -> Vector2:
	return _compute_bounds().size


func _slot_pixel_pos(slot: SpellSlotData) -> Vector2:
	return Vector2(float(slot.grid_col), float(slot.grid_row)) * CELL_SPACING + PAD


func _slot_center(slot: SpellSlotData) -> Vector2:
	return _slot_pixel_pos(slot) + SLOT_SIZE * 0.5


func _compute_bounds() -> Rect2:
	if _data == null or _data.slots.is_empty():
		return Rect2(Vector2.ZERO, Vector2(120.0, 70.0))
	var max_col := 0
	var max_row := 0
	for slot: SpellSlotData in _data.slots:
		max_col = maxi(max_col, slot.grid_col)
		max_row = maxi(max_row, slot.grid_row)
	var w := float(max_col) * CELL_SPACING.x + SLOT_SIZE.x + PAD.x * 2.0
	var h := float(max_row) * CELL_SPACING.y + SLOT_SIZE.y + PAD.y + PAD_BOTTOM
	return Rect2(Vector2.ZERO, Vector2(w, h))


func _draw() -> void:
	if _data == null:
		return
	var bounds := _compute_bounds()
	draw_rect(bounds, COLOR_BG, true)
	draw_rect(bounds, COLOR_BG_BORDER, false, 1.5)
	_draw_edges()
	for slot: SpellSlotData in _data.slots:
		_draw_slot(slot)


func _draw_edges() -> void:
	for slot: SpellSlotData in _data.slots:
		if slot.next_id.is_empty():
			continue
		var next := _data.get_slot(slot.next_id)
		if next == null:
			continue
		var from := _slot_center(slot)
		var to := _slot_center(next)
		var dir := (to - from).normalized()
		var half := SLOT_SIZE.x * 0.5
		draw_line(from + dir * (half + 1.0), to - dir * (half + 1.0), COLOR_EDGE, 1.5)
		_draw_arrowhead(from, to)


func _draw_arrowhead(from: Vector2, to: Vector2) -> void:
	var dir := (to - from).normalized()
	var tip := to - dir * (SLOT_SIZE.x * 0.5 + 2.0)
	var perp := Vector2(-dir.y, dir.x) * 4.5
	var base := tip - dir * 7.0
	draw_colored_polygon(PackedVector2Array([tip, base + perp, base - perp]), COLOR_EDGE)


func _draw_slot(slot: SpellSlotData) -> void:
	var pos := _slot_pixel_pos(slot)
	var rect := Rect2(pos, SLOT_SIZE)
	if slot.is_tip:
		draw_rect(rect, COLOR_SLOT_TIP, true)
		draw_rect(rect, COLOR_BORDER_TIP, false, 1.5)
		draw_string(ThemeDB.fallback_font, pos + Vector2(4.0, 14.0), "T",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_BORDER_TIP)
	else:
		draw_rect(rect, COLOR_SLOT_BODY, true)
		draw_rect(rect, COLOR_BORDER_BODY, false, 1.0)
