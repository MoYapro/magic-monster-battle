class_name WandDisplay
extends Node2D

const SLOT_SIZE := Vector2(50.0, 50.0)
const CELL_SPACING := Vector2(70.0, 60.0)
const PAD := Vector2(16.0, 16.0)
const PAD_BOTTOM := 14.0

signal tip_pressed(wand: WandDisplay)
signal body_slot_clicked(wand: WandDisplay, slot_id: String)
signal body_slot_right_clicked(wand: WandDisplay, slot_id: String)

var _data: WandData = null
var _highlighted := false
var _hovered := false
var _charges: Dictionary = {}  # slot_id -> int
var _webbed: Dictionary = {}   # slot_id -> true
var min_width := 0.0  # rows share one panel width
var min_height := 0.0  # tall enough for the mage card beside it


func setup(wand_data: WandData) -> void:
	_data = wand_data
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func set_charges(charges: Dictionary) -> void:
	_charges = charges
	queue_redraw()


func set_webbed(webbed: Dictionary) -> void:
	_webbed = webbed
	queue_redraw()


func get_display_size() -> Vector2:
	return _compute_bounds().size


func get_wand_data() -> WandData:
	return _data


func get_slot_at(local_pos: Vector2) -> SpellSlotData:
	if _data == null:
		return null
	for slot: SpellSlotData in _data.slots:
		if Rect2(_slot_pixel_pos(slot), SLOT_SIZE).has_point(local_pos):
			return slot
	return null


func get_tip_spell() -> SpellData:
	if _data == null:
		return null
	var tip := _data.get_tip_slot()
	return tip.spell if tip else null


func _slot_pixel_pos(slot: SpellSlotData) -> Vector2:
	return Vector2(float(slot.grid_col), float(slot.grid_row)) * CELL_SPACING + PAD


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
	return Rect2(Vector2.ZERO, Vector2(maxf(w, min_width), maxf(h, min_height)))


func _unhandled_input(event: InputEvent) -> void:
	if _data == null:
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	var button: MouseButton = event.button_index
	if button != MOUSE_BUTTON_LEFT and button != MOUSE_BUTTON_RIGHT:
		return
	var local := to_local(event.position)
	for slot: SpellSlotData in _data.slots:
		if not Rect2(_slot_pixel_pos(slot), SLOT_SIZE).has_point(local):
			continue
		if button == MOUSE_BUTTON_RIGHT:
			body_slot_right_clicked.emit(self, slot.id)
		elif slot.is_tip:
			tip_pressed.emit(self)
		else:
			body_slot_clicked.emit(self, slot.id)
		get_viewport().set_input_as_handled()
		return


const SOCKET_R := 19.0
const WEB := Color("#d8cfc0", 0.75)


func _draw() -> void:
	if _data == null:
		return
	var bounds := _compute_bounds()
	EmberDraw.panel(self, bounds, _highlighted or _hovered, Palette.COLOR_WAND_BG)
	if _hovered:
		EmberDraw.rounded_rect(self, bounds.grow(2), Color.TRANSPARENT, Palette.COLOR_TARGET_AVAILABLE, 2, 5)
	_draw_staff()
	_draw_edges()
	for slot: SpellSlotData in _data.slots:
		_draw_slot(slot)


## Socket centre: the upper part of the slot cell; the cost pips sit below it.
func _socket_center(slot: SpellSlotData) -> Vector2:
	return _slot_pixel_pos(slot) + Vector2(SLOT_SIZE.x * 0.5, SOCKET_R + 2.0)


## Wooden staff along the tip's row, from the first column to just past the tip.
func _draw_staff() -> void:
	var tip := _data.get_tip_slot()
	if tip == null:
		return
	var y := _socket_center(tip).y - 7.0
	var x0 := PAD.x - 4.0
	EmberDraw.staff(self, Vector2(x0, y), _socket_center(tip).x + SOCKET_R + 14.0 - x0)


func _draw_edges() -> void:
	for slot: SpellSlotData in _data.slots:
		var next := _data.get_slot(slot.next_id) if not slot.next_id.is_empty() else null
		if next == null:
			continue
		var from := _socket_center(slot)
		var to := _socket_center(next)
		var dir := (to - from).normalized()
		var tip := to - dir * (SOCKET_R + 3.0)
		draw_line(from + dir * (SOCKET_R + 2.0), tip, Palette.COLOR_WAND_EDGE, 2.0, true)
		var perp := Vector2(-dir.y, dir.x) * 4.5
		var base := tip - dir * 7.0
		draw_colored_polygon(PackedVector2Array([tip, base + perp, base - perp]), Palette.COLOR_WAND_EDGE)


func _draw_slot(slot: SpellSlotData) -> void:
	var c := _socket_center(slot)
	if slot.spell == null:
		EmberDraw.empty_socket(self, c, SOCKET_R, slot.is_tip)
		return
	var charges: int = _charges.get(slot.id, 0)
	var active := slot.spell.mana_cost > 0 and charges >= slot.spell.mana_cost
	EmberDraw.spell_socket(self, slot.spell, c, SOCKET_R, charges, slot.is_tip, active)
	if _webbed.has(slot.id):
		_draw_web(c)


## Spider web over a socket: a ring plus spokes and a second ring.
func _draw_web(c: Vector2) -> void:
	draw_circle(c, SOCKET_R, Color(0, 0, 0, 0.35))
	for i in 6:
		draw_line(c, c + Vector2.from_angle(i * TAU / 6.0) * SOCKET_R, WEB, 1.0, true)
	draw_arc(c, SOCKET_R * 0.5, 0.0, TAU, 6, WEB, 1.0, true)
	draw_arc(c, SOCKET_R * 0.9, 0.0, TAU, 6, WEB, 1.0, true)
