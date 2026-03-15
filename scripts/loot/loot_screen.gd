extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const HEADER_H := 48.0
const BOTTOM_BAR_H := 38.0

const MARGIN_X := 20.0
const PANEL_W := 400.0
const PANEL_GAP := 20.0
const PANEL_TOP := HEADER_H + 8.0
const PANEL_H := SCREEN_H - PANEL_TOP - BOTTOM_BAR_H - 8.0

const LOOT_X := MARGIN_X
const PACK_X := LOOT_X + PANEL_W + PANEL_GAP
const WAND_X := PACK_X + PANEL_W + PANEL_GAP

const CARD_SIZE := 80.0
const CARD_GAP := 8.0
const CARDS_PER_ROW := 4
const BACKPACK_SLOTS := 12

const COLOR_BG             := Color(0.07, 0.08, 0.09)
const COLOR_PANEL          := Color(0.10, 0.12, 0.14)
const COLOR_BORDER         := Color(0.22, 0.26, 0.30)
const COLOR_HEADER_BG      := Color(0.08, 0.09, 0.11)
const COLOR_SCREEN_TITLE   := Color(0.85, 0.90, 0.95)
const COLOR_SECTION        := Color(0.45, 0.52, 0.60)
const COLOR_MAGE_NAME      := Color(0.85, 0.90, 0.95)
const COLOR_SLOT_EMPTY     := Color(0.12, 0.14, 0.16)
const COLOR_SLOT_BORDER    := Color(0.20, 0.24, 0.28)
const COLOR_HP_FULL        := Color(0.20, 0.75, 0.30)
const COLOR_HP_LOW         := Color(0.85, 0.20, 0.15)
const COLOR_HP_BG          := Color(0.10, 0.12, 0.14)
const COLOR_DROP_HIGHLIGHT := Color(1.00, 0.85, 0.20, 0.12)
const COLOR_DROP_BORDER    := Color(1.00, 0.85, 0.20, 0.80)

var _equip_wand_displays: Array[WandDisplay] = []
var _mage_row_ys: Array[float] = []
var _loot_wand_display: WandDisplay = null

# --- drag state ---
var _dragging: SpellData = null
var _drag_source: String = ""   # "loot" | "backpack"
var _drag_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	_build_loot_wand()
	_build_equip_wands()
	_build_bottom_bar()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, SCREEN_H)), COLOR_BG, true)
	_draw_header()
	_draw_loot_panel()
	_draw_backpack_panel()
	_draw_equip_wand_panel()
	_draw_bottom_bar_bg()
	if _dragging != null:
		_draw_spell_card(_drag_pos - Vector2(CARD_SIZE * 0.5, CARD_SIZE * 0.5), _dragging)


# --- input ---

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _dragging != null:
			_drag_pos = (event as InputEventMouseMotion).position
			queue_redraw()
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_try_start_drag(mb.position)
	else:
		_end_drag(mb.position)


func _try_start_drag(pos: Vector2) -> void:
	var loot_idx := _card_index_at(pos, LOOT_X, GameState.pending_loot.size())
	if loot_idx >= 0:
		_dragging = GameState.pending_loot[loot_idx]
		GameState.pending_loot.remove_at(loot_idx)
		_drag_source = "loot"
		_drag_pos = pos
		_reposition_loot_wand()
		get_viewport().set_input_as_handled()
		queue_redraw()
		return
	var pack_idx := _card_index_at(pos, PACK_X, GameState.backpack.size())
	if pack_idx >= 0:
		_dragging = GameState.backpack[pack_idx]
		GameState.backpack.remove_at(pack_idx)
		_drag_source = "backpack"
		_drag_pos = pos
		get_viewport().set_input_as_handled()
		queue_redraw()


func _end_drag(pos: Vector2) -> void:
	if _dragging == null:
		return
	if _try_drop_on_wand_slot(pos):
		pass
	elif _panel_rect(LOOT_X).has_point(pos):
		GameState.pending_loot.append(_dragging)
	elif _panel_rect(PACK_X).has_point(pos) and GameState.backpack.size() < BACKPACK_SLOTS:
		GameState.backpack.append(_dragging)
	elif _drag_source == "loot":
		GameState.pending_loot.append(_dragging)
	else:
		GameState.backpack.append(_dragging)
	_dragging = null
	_drag_source = ""
	_reposition_loot_wand()
	queue_redraw()


func _try_drop_on_wand_slot(pos: Vector2) -> bool:
	for wd: WandDisplay in _equip_wand_displays:
		var slot := wd.get_slot_at(wd.to_local(pos))
		if slot == null:
			continue
		if slot.is_tip != _dragging.tags.has("tip"):
			return false  # type mismatch — let fallback return spell to source
		var displaced: SpellData = slot.spell
		slot.spell = _dragging
		wd.queue_redraw()
		if displaced != null:
			_place_spell_in_backpack_or_loot(displaced)
		return true
	return false


func _place_spell_in_backpack_or_loot(spell: SpellData) -> void:
	if GameState.backpack.size() < BACKPACK_SLOTS:
		GameState.backpack.append(spell)
	else:
		GameState.pending_loot.append(spell)


# --- hit testing helpers ---

func _card_index_at(pos: Vector2, panel_x: float, count: int) -> int:
	for i in count:
		if _card_rect(panel_x, i).has_point(pos):
			return i
	return -1


func _card_rect(panel_x: float, index: int) -> Rect2:
	return Rect2(
		Vector2(
			panel_x + 12.0 + float(index % CARDS_PER_ROW) * (CARD_SIZE + CARD_GAP),
			PANEL_TOP + 32.0 + float(index / CARDS_PER_ROW) * (CARD_SIZE + CARD_GAP)
		),
		Vector2(CARD_SIZE, CARD_SIZE)
	)


func _panel_rect(panel_x: float) -> Rect2:
	return Rect2(Vector2(panel_x, PANEL_TOP), Vector2(PANEL_W, PANEL_H))


# --- header ---

func _draw_header() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SCREEN_W, HEADER_H)), COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, HEADER_H - 1), Vector2(SCREEN_W, 1)), COLOR_BORDER, true)
	draw_string(ThemeDB.fallback_font,
			Vector2(SCREEN_W * 0.5, HEADER_H * 0.5 + 9.0),
			"Loot", HORIZONTAL_ALIGNMENT_CENTER, -1, 22, COLOR_SCREEN_TITLE)


# --- panels ---

func _draw_panel_frame(panel_x: float, title: String) -> void:
	var r := _panel_rect(panel_x)
	draw_rect(r, COLOR_PANEL, true)
	draw_rect(r, COLOR_BORDER, false, 1.0)
	draw_string(ThemeDB.fallback_font,
			Vector2(panel_x + 12.0, PANEL_TOP + 20.0),
			title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_SECTION)


func _draw_drop_highlight(panel_x: float) -> void:
	if _dragging == null:
		return
	if not _panel_rect(panel_x).has_point(_drag_pos):
		return
	draw_rect(_panel_rect(panel_x), COLOR_DROP_HIGHLIGHT, true)
	draw_rect(_panel_rect(panel_x), COLOR_DROP_BORDER, false, 2.0)


# --- loot panel ---

func _draw_loot_panel() -> void:
	_draw_panel_frame(LOOT_X, "Battle Loot")
	_draw_drop_highlight(LOOT_X)
	var spells := GameState.pending_loot
	var has_wand := GameState.pending_loot_wand != null
	if spells.is_empty() and not has_wand:
		draw_string(ThemeDB.fallback_font,
				Vector2(LOOT_X + PANEL_W * 0.5, PANEL_TOP + 80.0),
				"No loot this battle",
				HORIZONTAL_ALIGNMENT_CENTER, PANEL_W, 13, COLOR_SLOT_BORDER)
		return
	if not spells.is_empty():
		_draw_spell_grid(LOOT_X, spells, -1)
	if has_wand:
		draw_string(ThemeDB.fallback_font,
				Vector2(LOOT_X + 12.0, _loot_wand_y() - 4.0),
				"Wand drop", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_SECTION)


# --- backpack panel ---

func _draw_backpack_panel() -> void:
	_draw_panel_frame(PACK_X, "Backpack")
	_draw_drop_highlight(PACK_X)
	_draw_spell_grid(PACK_X, GameState.backpack, BACKPACK_SLOTS)


# --- spell grid ---

func _draw_spell_grid(panel_x: float, spells: Array[SpellData], total_slots: int) -> void:
	var count := total_slots if total_slots >= 0 else spells.size()
	for i in count:
		var pos := _card_rect(panel_x, i).position
		if i < spells.size():
			_draw_spell_card(pos, spells[i])
		else:
			_draw_empty_slot(pos)


func _draw_spell_card(pos: Vector2, spell: SpellData) -> void:
	var rect := Rect2(pos, Vector2(CARD_SIZE, CARD_SIZE))
	var tint := spell.element_color
	tint.a = 0.22
	draw_rect(rect, tint, true)
	draw_rect(rect, COLOR_SLOT_BORDER, false, 1.0)
	var font := ThemeDB.fallback_font
	var label := spell.abbreviation if not spell.abbreviation.is_empty() else "?"
	draw_string(font,
			Vector2(pos.x, pos.y + CARD_SIZE * 0.5 + 6.0),
			label, HORIZONTAL_ALIGNMENT_CENTER, CARD_SIZE, 20,
			Color(spell.element_color.r, spell.element_color.g, spell.element_color.b))
	draw_string(font,
			Vector2(pos.x, pos.y + CARD_SIZE - 8.0),
			spell.display_name, HORIZONTAL_ALIGNMENT_CENTER, CARD_SIZE, 10, COLOR_SECTION)


func _draw_empty_slot(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(CARD_SIZE, CARD_SIZE)), COLOR_SLOT_EMPTY, true)
	draw_rect(Rect2(pos, Vector2(CARD_SIZE, CARD_SIZE)), COLOR_SLOT_BORDER, false, 1.0)


# --- equipped wand panel ---

func _draw_equip_wand_panel() -> void:
	_draw_panel_frame(WAND_X, "Wands")
	for i in _mage_row_ys.size():
		if i >= GameState.mages.size():
			break
		_draw_mage_header(GameState.mages[i], _mage_row_ys[i])


func _draw_mage_header(mage: MageData, row_y: float) -> void:
	var pad := 12.0
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(WAND_X + pad, row_y + 14.0),
			mage.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_MAGE_NAME)
	draw_string(font, Vector2(WAND_X + PANEL_W - pad, row_y + 14.0),
			"%d / %d" % [mage.current_hp, mage.max_hp],
			HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, COLOR_SECTION)
	var bar_y := row_y + 19.0
	var bar_w := PANEL_W - pad * 2.0
	draw_rect(Rect2(Vector2(WAND_X + pad, bar_y), Vector2(bar_w, 5.0)), COLOR_HP_BG, true)
	var hp_frac := float(mage.current_hp) / float(mage.max_hp)
	var hp_color := COLOR_HP_FULL.lerp(COLOR_HP_LOW, 1.0 - hp_frac)
	draw_rect(Rect2(Vector2(WAND_X + pad, bar_y), Vector2(bar_w * hp_frac, 5.0)), hp_color, true)


func _build_equip_wands() -> void:
	var mage_header_h := 30.0
	var row_gap := 12.0
	var y := PANEL_TOP + 30.0
	for wand_data: WandData in GameState.wands:
		var wd := WandDisplay.new()
		add_child(wd)
		wd.setup(wand_data)
		var wand_size := wd.get_display_size()
		wd.position = Vector2(WAND_X + (PANEL_W - wand_size.x) * 0.5, y + mage_header_h)
		_equip_wand_displays.append(wd)
		_mage_row_ys.append(y)
		y += mage_header_h + wand_size.y + row_gap


# --- loot wand ---

func _loot_wand_y() -> float:
	var spell_rows := ceili(float(GameState.pending_loot.size()) / float(CARDS_PER_ROW))
	var base := PANEL_TOP + 32.0 + float(spell_rows) * (CARD_SIZE + CARD_GAP)
	return base + (12.0 if spell_rows > 0 else 0.0) + 14.0


func _build_loot_wand() -> void:
	if GameState.pending_loot_wand == null:
		return
	_loot_wand_display = WandDisplay.new()
	add_child(_loot_wand_display)
	_loot_wand_display.setup(GameState.pending_loot_wand)
	_reposition_loot_wand()


func _reposition_loot_wand() -> void:
	if _loot_wand_display == null:
		return
	var wand_size := _loot_wand_display.get_display_size()
	_loot_wand_display.position = Vector2(
		LOOT_X + (PANEL_W - wand_size.x) * 0.5,
		_loot_wand_y()
	)


# --- bottom bar ---

func _draw_bottom_bar_bg() -> void:
	var bar_y := SCREEN_H - BOTTOM_BAR_H
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(SCREEN_W, BOTTOM_BAR_H)), COLOR_HEADER_BG, true)
	draw_rect(Rect2(Vector2(0, bar_y), Vector2(SCREEN_W, 1)), COLOR_BORDER, true)


func _build_bottom_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var btn := Button.new()
	btn.text = "Continue →"
	btn.size = Vector2(148, BOTTOM_BAR_H - 10)
	btn.position = Vector2(SCREEN_W - 156.0, SCREEN_H - BOTTOM_BAR_H + 5.0)
	btn.pressed.connect(_on_continue_pressed)
	layer.add_child(btn)


func _on_continue_pressed() -> void:
	for spell: SpellData in GameState.pending_loot:
		GameState.backpack.append(spell)
	GameState.pending_loot.clear()
	if GameState.pending_loot_wand != null:
		GameState.backpack_wands.append(GameState.pending_loot_wand)
		GameState.pending_loot_wand = null
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")
