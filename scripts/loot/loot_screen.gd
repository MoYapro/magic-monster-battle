extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const HEADER_H := 48.0
const BOTTOM_BAR_H := EmberDraw.BOTTOM_BAR_H
const HEADING_H := 58.0  # panel title, rule and counter above the card grid

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
const GRID_INSET := (PANEL_W - CARDS_PER_ROW * CARD_SIZE - (CARDS_PER_ROW - 1) * CARD_GAP) * 0.5
const BACKPACK_SLOTS := LootInventory.BACKPACK_SLOTS
const MAGE_HEADER_H := 30.0
const EMPTY_WAND_SLOT_H := 52.0
const ROW_GAP := 12.0

const CATALOG_W := 900.0
const CATALOG_H := 480.0

const CODEX_W := 960.0
const CODEX_H := 540.0

var _inventory := LootInventory.new(GameState)

# loot wand displays — parallel to _inventory.pending_loot_wands
var _loot_wand_displays: Array[WandDisplay] = []
# equip wand displays — one per mage (null = no wand)
var _equip_wand_displays: Array[WandDisplay] = []
var _mage_row_ys: Array[float] = []
var _mage_row_hs: Array[float] = []

# --- drag state ---
var _dragging: SpellData = null
var _drag_source: LootInventory.Area = LootInventory.Area.NONE
var _dragging_wand: WandData = null
var _drag_wand_source: int = -2  # -1 = from loot; >= 0 = mage index
var _drag_pos: Vector2 = Vector2.ZERO
var _continue_btn: BaseButton = null
var _auto_assign_btn: Button = null
var _add_spell_btn: Button = null
var _reroll_btn: Button = null
var _catalog_layer: CanvasLayer = null
var _catalog_pick: bool = false
var _catalog_open: bool = false

var _codex_layer: CanvasLayer = null
var _codex_open: bool = false

var _spell_tooltip: SpellTooltip = null
var _float_damage: FloatingDamage = null


func _ready() -> void:
	_build_loot_wands()
	_build_equip_wands()
	_build_bottom_bar()
	_build_catalog_layer()
	_build_codex_layer()
	_spell_tooltip = SpellTooltip.new()
	add_child(_spell_tooltip)
	_float_damage = FloatingDamage.new()
	add_child(_float_damage)


func _draw() -> void:
	EmberDraw.backdrop(self)
	_draw_header()
	_draw_loot_panel()
	_draw_backpack_panel()
	_draw_equip_wand_panel()
	_draw_bottom_bar_bg()
	if _dragging != null:
		_draw_spell_card(_drag_pos - Vector2(CARD_SIZE * 0.5, CARD_SIZE * 0.5), _dragging)
	if _dragging_wand != null:
		_draw_wand_card(_drag_pos - Vector2(CARD_SIZE * 0.5, CARD_SIZE * 0.5), _dragging_wand)


# --- input ---

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _dragging != null or _dragging_wand != null:
			_drag_pos = motion.position
			queue_redraw()
		else:
				_update_hover(motion.position)
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		if _catalog_pick:
			_catalog_pick = false
			_end_drag(mb.position)
		else:
			_try_start_drag(mb.position)
	else:
		if not _catalog_pick:
			_end_drag(mb.position)


func _try_start_drag(pos: Vector2) -> void:
	# Spell slots inside any wand (checked before whole-wand drag)
	var spell := _try_pick_spell_from_wand(pos)
	if spell != null:
		_dragging = spell
		_drag_source = LootInventory.Area.LOOT
		_drag_pos = pos
		get_viewport().set_input_as_handled()
		queue_redraw()
		return

	# Loot wand displays (click on wand background = drag whole wand)
	var wand_idx := _loot_wand_index_at(pos)
	if wand_idx >= 0:
		_dragging_wand = _inventory.take_loot_wand(wand_idx)
		_loot_wand_displays[wand_idx].queue_free()
		_loot_wand_displays.remove_at(wand_idx)
		_reposition_loot_wands()
		_drag_wand_source = -1
		_drag_pos = pos
		get_viewport().set_input_as_handled()
		queue_redraw()
		return

	# Spell cards in loot panel
	var loot_idx := _card_index_at(pos, LOOT_X, _inventory.pending_loot.size())
	if loot_idx >= 0:
		_dragging = _inventory.take_loot(loot_idx)
		get_viewport().set_input_as_handled()
		if _dragging == null:
			return  # pick limit reached
		_drag_source = LootInventory.Area.LOOT
		_drag_pos = pos
		_reposition_loot_wands()
		queue_redraw()
		return

	# Spell cards in backpack panel
	var pack_idx := _card_index_at(pos, PACK_X, _inventory.backpack.size())
	if pack_idx >= 0:
		_dragging = _inventory.take_backpack(pack_idx)
		_drag_source = LootInventory.Area.BACKPACK
		_drag_pos = pos
		get_viewport().set_input_as_handled()
		queue_redraw()


func _end_drag(pos: Vector2) -> void:
	if _dragging_wand != null:
		_end_drag_wand(pos)
		return
	if _dragging == null:
		return
	if not _try_drop_on_wand_slot(pos):
		_inventory.drop_spell(_dragging, _panel_area_at(pos), _drag_source)
	_dragging = null
	_drag_source = LootInventory.Area.NONE
	_reposition_loot_wands()
	queue_redraw()


func _end_drag_wand(pos: Vector2) -> void:
	var mage_idx := _mage_equip_index_at(pos)
	if mage_idx >= 0:
		_equip_wand_at(mage_idx, _dragging_wand)
	else:
		_inventory.return_loot_wand(_dragging_wand)
		_add_loot_wand_display(_dragging_wand)
	_dragging_wand = null
	_drag_wand_source = -2
	queue_redraw()


func _try_drop_on_wand_slot(pos: Vector2) -> bool:
	for i in _equip_wand_displays.size():
		var wd: WandDisplay = _equip_wand_displays[i]
		if wd == null:
			continue
		var slot := wd.get_slot_at(wd.to_local(pos))
		if slot == null:
			continue
		if not LootInventory.fits_slot(slot, _dragging):
			return false
		var fusion := _inventory.place_in_slot(i, slot, _dragging)
		if fusion != null:
			_on_fusion(i, fusion)
		wd.queue_redraw()
		return true
	return false


func _panel_area_at(pos: Vector2) -> LootInventory.Area:
	if _panel_rect(LOOT_X).has_point(pos):
		return LootInventory.Area.LOOT
	if _panel_rect(PACK_X).has_point(pos):
		return LootInventory.Area.BACKPACK
	return LootInventory.Area.NONE


func _on_fusion(mage_index: int, result: AlchemyResult) -> void:
	match result.outcome:
		AlchemyResult.Outcome.FIZZLE:
			_spawn_alchemy_feedback(mage_index, AlchemyResult.Outcome.FIZZLE, 0)
		AlchemyResult.Outcome.BACKFIRE:
			var damage := LootInventory.backfire_penalty(_inventory.mages[mage_index])
			_spawn_alchemy_feedback(mage_index, AlchemyResult.Outcome.BACKFIRE, damage)


func _spawn_alchemy_feedback(mage_index: int, outcome: AlchemyResult.Outcome, damage: int) -> void:
	var origin := Vector2(WAND_X + PANEL_W * 0.5, _mage_row_ys[mage_index] + MAGE_HEADER_H * 0.5)
	var ev := CastEvent.new()
	match outcome:
		AlchemyResult.Outcome.FIZZLE:
			ev.type = CastEvent.Type.FIZZLE
		AlchemyResult.Outcome.BACKFIRE:
			ev.type = CastEvent.Type.BACKFIRE
			ev.backfire_damage = damage
	_float_damage.spawn_events([ev], origin)


func _equip_wand_at(mage_index: int, new_wand: WandData) -> void:
	var old_wand := _inventory.equip_wand(mage_index, new_wand)
	if old_wand != null:
		_add_loot_wand_display(old_wand)
	_rebuild_equip_wands()


func _add_loot_wand_display(wand: WandData) -> void:
	var wd := WandDisplay.new()
	add_child(wd)
	wd.setup(wand)
	_loot_wand_displays.append(wd)
	_reposition_loot_wands()


func _rebuild_equip_wands() -> void:
	for wd: WandDisplay in _equip_wand_displays:
		if wd != null:
			wd.queue_free()
	_equip_wand_displays.clear()
	_mage_row_ys.clear()
	_mage_row_hs.clear()
	_build_equip_wands()
	_refresh_continue_btn()
	queue_redraw()


# --- hit testing helpers ---

func _try_pick_spell_from_wand(pos: Vector2) -> SpellData:
	var all_wands: Array[WandDisplay] = []
	all_wands.append_array(_loot_wand_displays)
	for wd: WandDisplay in _equip_wand_displays:
		if wd != null:
			all_wands.append(wd)
	for wd: WandDisplay in all_wands:
		var slot := wd.get_slot_at(wd.to_local(pos))
		if slot != null and slot.spell != null:
			wd.queue_redraw()
			return LootInventory.take_from_slot(slot)
	return null


func _loot_wand_index_at(pos: Vector2) -> int:
	for i in _loot_wand_displays.size():
		var wd := _loot_wand_displays[i]
		if Rect2(wd.position, wd.get_display_size() * wd.scale).has_point(pos):
			return i
	return -1


func _card_index_at(pos: Vector2, panel_x: float, count: int) -> int:
	for i in count:
		if _card_rect(panel_x, i).has_point(pos):
			return i
	return -1


func _card_rect(panel_x: float, index: int) -> Rect2:
	return Rect2(
		Vector2(
			panel_x + GRID_INSET + float(index % CARDS_PER_ROW) * (CARD_SIZE + CARD_GAP),
			PANEL_TOP + HEADING_H + float(index / CARDS_PER_ROW) * (CARD_SIZE + CARD_GAP)
		),
		Vector2(CARD_SIZE, CARD_SIZE)
	)


func _loot_wand_section_y() -> float:
	var spell_rows := ceili(float(_inventory.pending_loot.size()) / float(CARDS_PER_ROW))
	var y := PANEL_TOP + HEADING_H + float(spell_rows) * (CARD_SIZE + CARD_GAP)
	return y + (CARD_GAP if spell_rows > 0 else 0.0)


func _mage_equip_index_at(pos: Vector2) -> int:
	for i in _mage_row_ys.size():
		var r := Rect2(Vector2(WAND_X, _mage_row_ys[i]), Vector2(PANEL_W, _mage_row_hs[i]))
		if r.has_point(pos):
			return i
	return -1


func _panel_rect(panel_x: float) -> Rect2:
	return Rect2(Vector2(panel_x, PANEL_TOP), Vector2(PANEL_W, PANEL_H))


# --- header ---

func _draw_header() -> void:
	var area := GameState.current_biome.name if GameState.current_biome != null else ""
	EmberDraw.title_plate(self, Rect2(440, 8, 400, 40), "Spoils of the " + area if area != "" else "Spoils")
	if GameState.battle_count > 0:
		EmberDraw.text(self, Vector2(24, 34), "Battle %d won" % GameState.battle_count, 18, Palette.COLOR_TEXT_DIM, true)


# --- panels ---

func _draw_panel_frame(panel_x: float, title: String, subtitle := "") -> void:
	var r := _panel_rect(panel_x)
	EmberDraw.panel(self, r)
	var cx := r.get_center().x
	EmberDraw.text_centered(self, cx, PANEL_TOP + 28.0, title, 19, Palette.COLOR_TEXT_BRIGHT, true)
	draw_line(Vector2(cx - 70, PANEL_TOP + 36.0), Vector2(cx + 70, PANEL_TOP + 36.0), Palette.COLOR_BORDER, 1.0)
	if subtitle != "":
		EmberDraw.text_centered(self, cx, PANEL_TOP + 52.0, subtitle, 13, Palette.COLOR_TEXT_DIM)


func _draw_drop_highlight(panel_x: float) -> void:
	if _dragging == null:
		return
	if not _panel_rect(panel_x).has_point(_drag_pos):
		return
	EmberDraw.rounded_rect(self, _panel_rect(panel_x), Palette.COLOR_DROP_HIGHLIGHT, Palette.COLOR_DROP_BORDER, 2, 4)


# --- loot panel ---

func _draw_loot_panel() -> void:
	_draw_panel_frame(LOOT_X, "Spoils", _loot_panel_subtitle())
	_draw_drop_highlight(LOOT_X)
	if _inventory.pending_loot.is_empty() and _inventory.pending_loot_wands.is_empty():
		EmberDraw.text_centered(self, LOOT_X + PANEL_W * 0.5, PANEL_TOP + 110.0, "No loot this battle", 14, Palette.COLOR_TEXT_DIM)
		return
	if not _inventory.pending_loot.is_empty():
		_draw_spell_grid(LOOT_X, _inventory.pending_loot, -1)
	if not _inventory.pending_loot_wands.is_empty():
		var y := _loot_wand_section_y() + 12.0
		EmberDraw.text(self, Vector2(LOOT_X + 16.0, y), "Wands", 14, Palette.COLOR_TEXT_DIM)
		draw_line(Vector2(LOOT_X + 66.0, y - 4.0), Vector2(LOOT_X + PANEL_W - 16.0, y - 4.0), Palette.COLOR_BORDER, 1.0)


func _loot_panel_subtitle() -> String:
	if _inventory.battle_drops.is_empty():
		return "What you leave behind is lost to the dark."
	return "%d of %d taken" % [_inventory.picks_used(), LootRoller.MAX_PICKS]


# --- backpack panel ---

func _draw_backpack_panel() -> void:
	_draw_panel_frame(PACK_X, "Satchel", "%d of %d pockets" % [_inventory.backpack.size(), BACKPACK_SLOTS])
	_draw_drop_highlight(PACK_X)
	_draw_spell_grid(PACK_X, _inventory.backpack, BACKPACK_SLOTS)


# --- spell grid ---

func _draw_spell_grid(panel_x: float, spells: Array[SpellData], total_slots: int) -> void:
	var count := total_slots if total_slots >= 0 else spells.size()
	for i in count:
		var pos := _card_rect(panel_x, i).position
		if i < spells.size():
			_draw_spell_card(pos, spells[i])
		else:
			_draw_empty_slot(pos)


## A spell as its rune socket with the name below, inside the card's hit area.
func _draw_spell_card(pos: Vector2, spell: SpellData) -> void:
	EmberDraw.spell_socket(self, spell, pos + Vector2(CARD_SIZE * 0.5, 30.0), 24.0)
	EmberDraw.text_centered(self, pos.x + CARD_SIZE * 0.5, pos.y + CARD_SIZE - 2.0, spell.display_name, 12, Palette.COLOR_TEXT_DIM)


## A wand being dragged: a short staff with its rune count and tip.
func _draw_wand_card(pos: Vector2, wand: WandData) -> void:
	var rect := Rect2(pos, Vector2(CARD_SIZE * 1.6, CARD_SIZE * 0.7))
	EmberDraw.panel(self, rect, true, Palette.COLOR_WAND_CARD)
	EmberDraw.staff(self, rect.position + Vector2(10, rect.size.y * 0.5 - 7.0), rect.size.x - 20)
	var tip := wand.get_tip_slot()
	var label := "%d runes" % (wand.slots.size() - 1)
	if tip != null and tip.spell != null:
		label += " · " + tip.spell.display_name
	EmberDraw.text_centered(self, rect.get_center().x, rect.position.y + 18.0, label, 12, Palette.COLOR_TEXT_BRIGHT)


func _draw_empty_slot(pos: Vector2) -> void:
	EmberDraw.empty_socket(self, pos + Vector2(CARD_SIZE * 0.5, 30.0), 24.0)


# --- equipped wand panel ---

func _draw_equip_wand_panel() -> void:
	_draw_panel_frame(WAND_X, "Wielded Wands")
	for i in _mage_row_ys.size():
		if i >= _inventory.mages.size():
			break
		_draw_mage_header(_inventory.mages[i], _mage_row_ys[i])
		if _equip_wand_displays[i] == null:
			_draw_empty_wand_slot(i)


func _draw_mage_header(mage: MageData, row_y: float) -> void:
	var x := WAND_X + 16.0
	EmberDraw.medallion(self, Vector2(x + 11.0, row_y + 11.0), 11.0, MageColors.color_for(mage.name))
	EmberDraw.text(self, Vector2(x + 30.0, row_y + 16.0), mage.name, 15, Palette.COLOR_TEXT_BRIGHT, true)
	EmberDraw.text_right(self, WAND_X + PANEL_W - 16.0, row_y + 16.0, "%d/%d" % [mage.current_hp, mage.max_hp], 12, Palette.COLOR_TEXT_DIM)
	EmberDraw.hp_bar(self, Rect2(x + 100.0, row_y + 9.0, PANEL_W - 190.0, 6.0), mage.current_hp, mage.max_hp)


func _draw_empty_wand_slot(mage_index: int) -> void:
	var slot_y := _mage_row_ys[mage_index] + MAGE_HEADER_H
	var r := Rect2(Vector2(WAND_X + 12.0, slot_y), Vector2(PANEL_W - 24.0, EMPTY_WAND_SLOT_H))
	var is_target := _dragging_wand != null and _mage_equip_index_at(_drag_pos) == mage_index
	EmberDraw.rounded_rect(self, r, Palette.COLOR_DROP_HIGHLIGHT if is_target else Palette.COLOR_SLOT_EMPTY,
			Palette.COLOR_DROP_BORDER if is_target else Palette.COLOR_INNER_BORDER, 1, 4)
	EmberDraw.text_centered(self, r.get_center().x, r.get_center().y + 5.0, "The wand rack is empty — drop a wand here", 13, Palette.COLOR_TEXT_DIM)


func _build_loot_wands() -> void:
	for wand: WandData in _inventory.pending_loot_wands:
		var wd := WandDisplay.new()
		add_child(wd)
		wd.setup(wand)
		wd.min_width = PANEL_W - 24.0
		_loot_wand_displays.append(wd)
	_reposition_loot_wands()


## Stacks the loot wands below the spells and shrinks them when they would overflow the panel.
func _reposition_loot_wands() -> void:
	var top := _loot_wand_section_y() + 18.0
	var total := 0.0
	for wd: WandDisplay in _loot_wand_displays:
		total += wd.get_display_size().y + ROW_GAP
	var k := minf(1.0, (PANEL_TOP + PANEL_H - 8.0 - top) / maxf(total, 1.0))
	var y := top
	for wd: WandDisplay in _loot_wand_displays:
		wd.scale = Vector2.ONE * k
		wd.position = Vector2(LOOT_X + (PANEL_W - wd.get_display_size().x * k) * 0.5, y)
		y += (wd.get_display_size().y + ROW_GAP) * k


func _build_equip_wands() -> void:
	var y := PANEL_TOP + HEADING_H
	for i in _inventory.mages.size():
		_mage_row_ys.append(y)
		var wand_data := _inventory.equipped_wand(i)
		var wd: WandDisplay = null
		var wand_h: float
		if wand_data != null:
			wd = WandDisplay.new()
			add_child(wd)
			wd.setup(wand_data)
			wd.min_width = PANEL_W - 24.0
			wand_h = wd.get_display_size().y
			wd.position = Vector2(WAND_X + (PANEL_W - wd.get_display_size().x) * 0.5,
					y + MAGE_HEADER_H)
		else:
			wand_h = EMPTY_WAND_SLOT_H
		_equip_wand_displays.append(wd)
		var row_h := MAGE_HEADER_H + wand_h + ROW_GAP
		_mage_row_hs.append(row_h)
		y += row_h


# --- spell catalog ---

func _all_body_spells() -> Array[SpellData]:
	return SpellRegistry.all_body_spells()


func _all_tip_spells() -> Array[SpellData]:
	return SpellRegistry.all_tip_spells()


func _build_catalog_layer() -> void:
	_catalog_layer = CanvasLayer.new()
	_catalog_layer.layer = 2
	_catalog_layer.visible = false
	add_child(_catalog_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_catalog_layer.add_child(dim)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Palette.COLOR_PANEL
	panel_style.border_color = Palette.COLOR_BORDER
	panel_style.set_border_width_all(1)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.size = Vector2(CATALOG_W, CATALOG_H)
	panel.position = Vector2((SCREEN_W - CATALOG_W) * 0.5, (SCREEN_H - CATALOG_H) * 0.5)
	_catalog_layer.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)

	var title_row := HBoxContainer.new()
	outer.add_child(title_row)
	var title_lbl := Label.new()
	title_lbl.text = "Add Spell"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(title_lbl)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_close_catalog)
	title_row.add_child(close_btn)

	var sep := HSeparator.new()
	outer.add_child(sep)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	outer.add_child(content)

	content.add_child(_build_spell_section("Body Spells", _all_body_spells()))
	var vsep := VSeparator.new()
	content.add_child(vsep)
	content.add_child(_build_spell_section("Tip Spells", _all_tip_spells()))


func _build_spell_section(title: String, spells: Array[SpellData]) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 4)
	var lbl := Label.new()
	lbl.text = title
	lbl.add_theme_font_size_override("font_size", 11)
	section.add_child(lbl)
	var grid := GridContainer.new()
	grid.columns = CARDS_PER_ROW
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	section.add_child(grid)
	for spell in spells:
		grid.add_child(_make_spell_button(spell))
	return section


func _make_spell_button(spell: SpellData) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
	var tint := spell.element_color
	tint.a = 0.35
	var normal := StyleBoxFlat.new()
	normal.bg_color = tint
	normal.border_color = Palette.COLOR_SLOT_BORDER
	normal.set_border_width_all(1)
	var hover := StyleBoxFlat.new()
	hover.bg_color = spell.element_color * Color(1, 1, 1, 0.55)
	hover.border_color = spell.element_color
	hover.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	var label := spell.abbreviation if not spell.abbreviation.is_empty() else "?"
	btn.text = label + "\n" + spell.display_name
	btn.pressed.connect(func() -> void: _on_catalog_spell_selected(spell))
	return btn


func _on_catalog_spell_selected(spell: SpellData) -> void:
	_dragging = spell
	_drag_pos = get_viewport().get_mouse_position()
	_drag_source = LootInventory.Area.LOOT
	_catalog_pick = true
	_close_catalog()


func _on_reroll_pressed() -> void:
	GameState.reroll_spell_loot()
	_rebuild_loot_wands()
	queue_redraw()


func _rebuild_loot_wands() -> void:
	for wd: WandDisplay in _loot_wand_displays:
		wd.queue_free()
	_loot_wand_displays.clear()
	_build_loot_wands()


func _on_add_spell_pressed() -> void:
	_catalog_layer.visible = true
	_catalog_open = true


func _close_catalog() -> void:
	_catalog_layer.visible = false
	_catalog_open = false


# --- tooltip ---

func _spell_at(pos: Vector2) -> SpellData:
	var loot_idx := _card_index_at(pos, LOOT_X, _inventory.pending_loot.size())
	if loot_idx >= 0:
		return _inventory.pending_loot[loot_idx]
	var pack_idx := _card_index_at(pos, PACK_X, _inventory.backpack.size())
	if pack_idx >= 0:
		return _inventory.backpack[pack_idx]
	var all_wands: Array[WandDisplay] = []
	all_wands.append_array(_loot_wand_displays)
	for wd: WandDisplay in _equip_wand_displays:
		if wd != null:
			all_wands.append(wd)
	for wd: WandDisplay in all_wands:
		var slot := wd.get_slot_at(wd.to_local(pos))
		if slot != null and slot.spell != null:
			return slot.spell
	return null


func _update_hover(pos: Vector2) -> void:
	_spell_tooltip.notify_hover(pos, null if _catalog_open or _codex_open else _spell_at(pos))


# --- bottom bar ---

func _draw_bottom_bar_bg() -> void:
	EmberDraw.bottom_bar(self, "Drag spells between spoils, satchel and wands", 460.0)


func _build_bottom_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_add_spell_btn = Button.new()
	_add_spell_btn.text = "+ Spell"
	_add_spell_btn.size = Vector2(90, 36)
	_add_spell_btn.position = Vector2(24.0, SCREEN_H - BOTTOM_BAR_H + 10.0)
	_add_spell_btn.pressed.connect(_on_add_spell_pressed)
	layer.add_child(_add_spell_btn)
	_reroll_btn = Button.new()
	_reroll_btn.text = "↺ Reroll"
	_reroll_btn.size = Vector2(90, 36)
	_reroll_btn.position = Vector2(122.0, SCREEN_H - BOTTOM_BAR_H + 10.0)
	_reroll_btn.disabled = _inventory.is_initial_setup
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	layer.add_child(_reroll_btn)
	var codex_btn := Button.new()
	codex_btn.text = "Codex"
	codex_btn.size = Vector2(90, 36)
	codex_btn.position = Vector2(220.0, SCREEN_H - BOTTOM_BAR_H + 10.0)
	codex_btn.pressed.connect(_on_codex_pressed)
	layer.add_child(codex_btn)
	var seal := WaxSealButton.new()
	seal.line1 = "GO"
	seal.line2 = "FORTH"
	seal.position = Vector2(SCREEN_W - 98.0, SCREEN_H - 92.0)
	_continue_btn = seal
	_continue_btn.pressed.connect(_on_continue_pressed)
	layer.add_child(_continue_btn)
	if _inventory.is_initial_setup:
		_auto_assign_btn = Button.new()
		_auto_assign_btn.text = "Auto Assign"
		_auto_assign_btn.size = Vector2(120, 36)
		_auto_assign_btn.position = Vector2(318.0, SCREEN_H - BOTTOM_BAR_H + 10.0)
		_auto_assign_btn.pressed.connect(_on_auto_assign_pressed)
		layer.add_child(_auto_assign_btn)
	_refresh_continue_btn()


func _refresh_continue_btn() -> void:
	if _continue_btn == null:
		return
	_continue_btn.disabled = not _inventory.can_continue()


func _on_auto_assign_pressed() -> void:
	_inventory.auto_assign()
	_rebuild_loot_wands()
	_rebuild_equip_wands()
	_on_continue_pressed()


func _on_continue_pressed() -> void:
	_inventory.finish()
	get_tree().change_scene_to_file("res://scenes/battle/battle_scene.tscn")


# --- codex ---

func _build_codex_layer() -> void:
	_codex_layer = CanvasLayer.new()
	_codex_layer.layer = 3
	add_child(_codex_layer)
	_codex_layer.visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_codex_layer.add_child(dim)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Palette.COLOR_PANEL
	panel_style.border_color = Palette.COLOR_BORDER
	panel_style.set_border_width_all(1)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.size = Vector2(CODEX_W, CODEX_H)
	panel.position = Vector2((SCREEN_W - CODEX_W) * 0.5, (SCREEN_H - CODEX_H) * 0.5)
	_codex_layer.add_child(panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 4)
	panel.add_child(outer)

	var title_row := HBoxContainer.new()
	outer.add_child(title_row)
	var title_lbl := Label.new()
	title_lbl.text = "Codex"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(title_lbl)
	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(_on_codex_close_pressed)
	title_row.add_child(close_btn)

	outer.add_child(HSeparator.new())

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(tabs)
	tabs.add_child(_build_codex_spells_tab())
	tabs.add_child(_build_codex_monsters_tab())
	tabs.add_child(_build_codex_biomes_tab())


func _build_codex_spells_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "Spells"
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)
	var body_cards: Array[Control] = []
	for spell in SpellRegistry.all_body_spells():
		body_cards.append(_make_codex_spell_card(spell))
	vbox.add_child(_codex_grid_section("Body Spells", body_cards))
	var tip_cards: Array[Control] = []
	for spell in SpellRegistry.all_tip_spells():
		tip_cards.append(_make_codex_spell_card(spell))
	vbox.add_child(_codex_grid_section("Tip Spells", tip_cards))
	return scroll


func _build_codex_monsters_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "Monsters"
	var cards: Array[Control] = []
	for monster in _all_codex_monsters():
		cards.append(_make_codex_monster_card(monster))
	var section := _codex_grid_section("", cards)
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(section)
	return scroll


func _build_codex_biomes_tab() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "Biomes"
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", CARD_GAP)
	scroll.add_child(vbox)
	for biome: BiomeData in BiomesData.all():
		vbox.add_child(_make_codex_biome_row(biome))
	return scroll


func _codex_grid_section(title: String, cards: Array[Control]) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 4)
	if not title.is_empty():
		var lbl := Label.new()
		lbl.text = title
		lbl.add_theme_color_override("font_color", Palette.COLOR_SECTION)
		lbl.add_theme_font_size_override("font_size", 11)
		section.add_child(lbl)
	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", CARD_GAP)
	grid.add_theme_constant_override("v_separation", CARD_GAP)
	section.add_child(grid)
	for card in cards:
		grid.add_child(card)
	return section


func _make_codex_spell_card(spell: SpellData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
	var style := StyleBoxFlat.new()
	var tint := spell.element_color
	tint.a = 0.22
	style.bg_color = tint
	style.border_color = Palette.COLOR_SLOT_BORDER
	style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel", style)
	card.tooltip_text = spell.display_name + "\n" + spell.description
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	var abbr := Label.new()
	abbr.text = spell.abbreviation if not spell.abbreviation.is_empty() else "?"
	abbr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	abbr.add_theme_color_override("font_color", spell.element_color)
	abbr.add_theme_font_size_override("font_size", 20)
	vbox.add_child(abbr)
	var name_lbl := Label.new()
	name_lbl.text = spell.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Palette.COLOR_SECTION)
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)
	return card


func _make_codex_monster_card(monster: EnemyData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_SIZE, CARD_SIZE)
	var style := StyleBoxFlat.new()
	var tint := monster.color
	tint.a = 0.22
	style.bg_color = tint
	style.border_color = Palette.COLOR_SLOT_BORDER
	style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel", style)
	card.tooltip_text = monster.display_name + "\n" + monster.description
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(vbox)
	var name_lbl := Label.new()
	name_lbl.text = monster.display_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", monster.color)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_lbl)
	var hp_lbl := Label.new()
	hp_lbl.text = "%d hp" % monster.max_hp
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_color_override("font_color", Palette.COLOR_SECTION)
	hp_lbl.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hp_lbl)
	return card


func _make_codex_biome_row(biome: BiomeData) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	var tint := biome.color
	tint.a = 0.15
	style.bg_color = tint
	style.border_color = Palette.COLOR_SLOT_BORDER
	style.set_border_width_all(1)
	style.border_width_left = 4
	card.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	card.add_child(margin)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	margin.add_child(hbox)
	var name_lbl := Label.new()
	name_lbl.text = biome.name
	name_lbl.custom_minimum_size = Vector2(90, 0)
	name_lbl.add_theme_color_override("font_color", biome.color)
	name_lbl.add_theme_font_size_override("font_size", 13)
	hbox.add_child(name_lbl)
	var tagline_lbl := Label.new()
	tagline_lbl.text = biome.tagline
	tagline_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tagline_lbl.add_theme_color_override("font_color", Palette.COLOR_SECTION)
	tagline_lbl.add_theme_font_size_override("font_size", 11)
	tagline_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(tagline_lbl)
	var monster_names: Array[String] = []
	for mc in biome.monster_pool:
		var m: EnemyData = mc.new()
		monster_names.append(m.display_name)
	var monsters_lbl := Label.new()
	monsters_lbl.text = ", ".join(monster_names)
	monsters_lbl.custom_minimum_size = Vector2(300, 0)
	monsters_lbl.add_theme_color_override("font_color", Palette.COLOR_SECTION)
	monsters_lbl.add_theme_font_size_override("font_size", 9)
	monsters_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	monsters_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(monsters_lbl)
	return card


func _all_codex_monsters() -> Array[EnemyData]:
	var seen := {}
	var result: Array[EnemyData] = []
	for biome: BiomeData in BiomesData.all():
		for monster_class in biome.monster_pool:
			var m: EnemyData = monster_class.new()
			if not seen.has(m.id):
				seen[m.id] = true
				result.append(m)
	result.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.display_name < b.display_name)
	return result


func _on_codex_pressed() -> void:
	_codex_layer.visible = true
	_codex_open = true


func _on_codex_close_pressed() -> void:
	_codex_layer.visible = false
	_codex_open = false
