extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const MARGIN := 40.0
const WAND_PANEL_W := 580.0
const BATTLE_PANEL_W := SCREEN_W - WAND_PANEL_W  # 700.0

const MANA_X := MARGIN
const MAGE_X := MANA_X + ManaDisplay.WIDTH + 8.0
const WAND_X := MAGE_X + MageDisplay.WIDTH + 10.0
const ROW_GAP := 14.0

@onready var enemy_grid: EnemyGrid = $EnemyGrid

var _mage_displays: Array[MageDisplay] = []
var _wand_displays: Array[WandDisplay] = []
var _targeting_wand: WandDisplay = null
var _hovered_mage: MageDisplay = null
var _hovered_wand: WandDisplay = null
var _hovered_cells: Array[Vector2i] = []


func _ready() -> void:
	_setup_mage_wand_rows()
	_populate_test_enemies()


func _setup_mage_wand_rows() -> void:
	var mages := _make_mage_data()
	var wand_displays := _create_wand_displays(_make_wand_data())
	var total_h := _measure_total_height(wand_displays)
	var start_y := MARGIN + (SCREEN_H - MARGIN * 2.0 - total_h) / 2.0
	_place_mana_bar(start_y, total_h)
	_place_rows(wand_displays, mages, start_y)
	_position_enemy_grid(start_y, total_h)


func _create_wand_displays(wands: Array[WandData]) -> Array[WandDisplay]:
	var result: Array[WandDisplay] = []
	for wand_data: WandData in wands:
		var wand := WandDisplay.new()
		add_child(wand)
		wand.setup(wand_data)
		result.append(wand)
	return result


func _measure_total_height(wand_displays: Array[WandDisplay]) -> float:
	var total := 0.0
	for wand: WandDisplay in wand_displays:
		total += wand.get_display_size().y
	return total + ROW_GAP * (wand_displays.size() - 1)


func _place_mana_bar(start_y: float, total_h: float) -> void:
	var mana := ManaDisplay.new()
	add_child(mana)
	mana.position = Vector2(MANA_X, start_y)
	mana.setup(10, 10, total_h)


func _place_rows(wand_displays: Array[WandDisplay], mages: Array[MageData], start_y: float) -> void:
	var y := start_y
	for i in wand_displays.size():
		var wand: WandDisplay = wand_displays[i]
		wand.position = Vector2(WAND_X, y)
		wand.tip_pressed.connect(_on_tip_pressed)
		_wand_displays.append(wand)
		var mage := MageDisplay.new()
		add_child(mage)
		mage.position = Vector2(MAGE_X, y)
		mage.setup(mages[i], wand.get_display_size().y)
		_mage_displays.append(mage)
		y += wand.get_display_size().y + ROW_GAP


func _position_enemy_grid(panel_top: float, panel_h: float) -> void:
	var cell_h := panel_h / EnemyGrid.ROWS
	enemy_grid.cell_size = Vector2(cell_h, cell_h)
	var grid_w := EnemyGrid.COLS * cell_h
	enemy_grid.position = Vector2(
		WAND_PANEL_W + (BATTLE_PANEL_W - grid_w) / 2.0,
		panel_top
	)
	enemy_grid.queue_redraw()


func _on_tip_pressed(wand: WandDisplay) -> void:
	if _targeting_wand == wand:
		_cancel_targeting()
	else:
		_start_targeting(wand)


func _start_targeting(wand: WandDisplay) -> void:
	_targeting_wand = wand
	enemy_grid.set_highlighted(true)
	for m in _mage_displays:
		m.set_highlighted(true)
	for w in _wand_displays:
		w.set_highlighted(true)


func _cancel_targeting() -> void:
	_clear_hover()
	_targeting_wand = null
	enemy_grid.set_highlighted(false)
	for m in _mage_displays:
		m.set_highlighted(false)
	for w in _wand_displays:
		w.set_highlighted(false)


func _clear_hover() -> void:
	if _hovered_mage != null:
		_hovered_mage.set_hovered(false)
		_hovered_mage = null
	if _hovered_wand != null:
		_hovered_wand.set_hovered(false)
		_hovered_wand = null
	if not _hovered_cells.is_empty():
		enemy_grid.set_hovered_cells([])
		_hovered_cells.clear()


func _update_hover(mouse: Vector2) -> void:
	_clear_hover()
	var cell := enemy_grid.get_cell_at(enemy_grid.to_local(mouse))
	if cell.x >= 0:
		var tip := _targeting_wand.get_tip_spell()
		var pattern: Array[Vector2i] = [Vector2i(0, 0)]
		if tip != null and not tip.hit_pattern.is_empty():
			pattern = tip.hit_pattern
		_hovered_cells = enemy_grid.get_hit_cells(cell, pattern)
		enemy_grid.set_hovered_cells(_hovered_cells)
		return
	for mage in _mage_displays:
		if mage.get_rect().has_point(mage.to_local(mouse)):
			_hovered_mage = mage
			mage.set_hovered(true)
			return
	for wand in _wand_displays:
		if Rect2(Vector2.ZERO, wand.get_display_size()).has_point(wand.to_local(mouse)):
			_hovered_wand = wand
			wand.set_hovered(true)
			return


func _unhandled_input(event: InputEvent) -> void:
	if _targeting_wand == null:
		return
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_targeting()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var mouse := (event as InputEventMouseButton).position

	var cell := enemy_grid.get_cell_at(enemy_grid.to_local(mouse))
	if cell.x >= 0:
		_fire_at_cell(cell)
		_cancel_targeting()
		get_viewport().set_input_as_handled()
		return

	for mage in _mage_displays:
		if mage.get_rect().has_point(mage.to_local(mouse)):
			_cancel_targeting()
			get_viewport().set_input_as_handled()
			return

	for wand in _wand_displays:
		if Rect2(Vector2.ZERO, wand.get_display_size()).has_point(wand.to_local(mouse)):
			_cancel_targeting()
			get_viewport().set_input_as_handled()
			return

	_cancel_targeting()


func _fire_at_cell(cell: Vector2i) -> void:
	var wand := _targeting_wand.get_wand_data()
	var tip := _targeting_wand.get_tip_spell()
	var pattern: Array[Vector2i] = [Vector2i(0, 0)]
	if tip != null and not tip.hit_pattern.is_empty():
		pattern = tip.hit_pattern
	var hit_cells := enemy_grid.get_hit_cells(cell, pattern)
	var damage := wand.get_total_damage()
	for hit in hit_cells:
		enemy_grid.apply_damage(hit, damage)


func _make_mage_data() -> Array[MageData]:
	return [
		MageData.new("Lyra", 30),
		MageData.new("Eron", 30),
		MageData.new("Vael", 30),
	]


func _make_wand_data() -> Array[WandData]:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return [
		WandGenerator.generate(rng),
		WandGenerator.generate(rng),
		WandGenerator.generate(rng),
	]


func _populate_test_enemies() -> void:
	enemy_grid.place_enemy(
		EnemyData.new("goblin_1", "Goblin", 40, Vector2i(1, 1), Color(0.2, 0.65, 0.2)),
		Vector2i(0, 0)
	)
	enemy_grid.place_enemy(
		EnemyData.new("skeleton_1", "Skeleton", 35, Vector2i(1, 1), Color(0.8, 0.8, 0.7)),
		Vector2i(1, 1)
	)
	enemy_grid.place_enemy(
		EnemyData.new("witch_1", "Witch", 50, Vector2i(1, 1), Color(0.55, 0.1, 0.7)),
		Vector2i(2, 3)
	)
	enemy_grid.place_enemy(
		EnemyData.new("ogre_1", "Shield Ogre", 100, Vector2i(2, 1), Color(0.65, 0.25, 0.15)),
		Vector2i(0, 3)
	)
	enemy_grid.place_enemy(
		EnemyData.new("troll_1", "Troll", 80, Vector2i(1, 2), Color(0.3, 0.5, 0.2)),
		Vector2i(2, 0)
	)
