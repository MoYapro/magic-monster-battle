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
const BOTTOM_BAR_H := 38.0

@onready var enemy_grid: EnemyGrid = $EnemyGrid

var _mages: Array[MageData] = []
var _mage_displays: Array[MageDisplay] = []
var _wand_displays: Array[WandDisplay] = []
var _mana_display: ManaDisplay = null
var _panel_height: float = 0.0

var _setup: BattleSetup = null
var _history: BattleHistory = null
var _undo_button: Button = null

var _targeting_wand: WandDisplay = null
var _hovered_mage: MageDisplay = null
var _hovered_wand: WandDisplay = null
var _hovered_cells: Array[Vector2i] = []


func _ready() -> void:
	_build_bottom_bar()
	_setup_mage_wand_rows()
	_build_setup()


# --- bottom bar ---

func _build_bottom_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.09, 0.10)
	bg.position = Vector2(0, SCREEN_H - BOTTOM_BAR_H)
	bg.size = Vector2(SCREEN_W, BOTTOM_BAR_H)
	layer.add_child(bg)

	var sep := ColorRect.new()
	sep.color = Color(0.25, 0.28, 0.32)
	sep.position = Vector2(0, SCREEN_H - BOTTOM_BAR_H)
	sep.size = Vector2(SCREEN_W, 1)
	layer.add_child(sep)

	var end_turn_button := Button.new()
	end_turn_button.text = "End Turn"
	end_turn_button.size = Vector2(100, BOTTOM_BAR_H - 10)
	end_turn_button.position = Vector2(SCREEN_W - 420, SCREEN_H - BOTTOM_BAR_H + 5)
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	layer.add_child(end_turn_button)

	var win_button := Button.new()
	win_button.text = "🏆 Win"
	win_button.size = Vector2(90, BOTTOM_BAR_H - 10)
	win_button.position = Vector2(SCREEN_W - 310, SCREEN_H - BOTTOM_BAR_H + 5)
	win_button.pressed.connect(_on_battle_won)
	layer.add_child(win_button)

	_undo_button = Button.new()
	_undo_button.text = "↩ Undo  Ctrl+Z"
	_undo_button.size = Vector2(148, BOTTOM_BAR_H - 10)
	_undo_button.position = Vector2(SCREEN_W - 156, SCREEN_H - BOTTOM_BAR_H + 5)
	_undo_button.pressed.connect(_on_undo_pressed)
	layer.add_child(_undo_button)


func _on_end_turn_pressed() -> void:
	_cancel_targeting()
	_apply_state(_history.push(ActionEndTurn.new()))


func _on_undo_pressed() -> void:
	if _history != null and _history.can_undo():
		_apply_state(_history.undo())


func _refresh_ui() -> void:
	if _undo_button != null and _history != null:
		_undo_button.disabled = not _history.can_undo()


# --- layout ---

func _setup_mage_wand_rows() -> void:
	_mages = _make_mage_data()
	var wand_displays := _create_wand_displays(_make_wand_data())
	var total_h := _measure_total_height(wand_displays)
	var usable_h := SCREEN_H - BOTTOM_BAR_H
	var start_y := MARGIN + (usable_h - MARGIN * 2.0 - total_h) / 2.0
	_place_mana_bar(start_y, total_h)
	_place_rows(wand_displays, _mages, start_y)
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
	_panel_height = total_h
	_mana_display = ManaDisplay.new()
	add_child(_mana_display)
	_mana_display.position = Vector2(MANA_X, start_y)
	_mana_display.setup(10, 10, total_h)


func _place_rows(wand_displays: Array[WandDisplay], mages: Array[MageData], start_y: float) -> void:
	var y := start_y
	for i in wand_displays.size():
		var wand: WandDisplay = wand_displays[i]
		wand.position = Vector2(WAND_X, y)
		wand.tip_pressed.connect(_on_tip_pressed)
		wand.body_slot_clicked.connect(_on_body_slot_clicked)
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


# --- battle state ---

func _build_setup() -> void:
	var positions: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 3), Vector2i(0, 3), Vector2i(2, 0),
	]
	var wands: Array[WandData] = []
	for wd: WandDisplay in _wand_displays:
		wands.append(wd.get_wand_data())
	_setup = BattleSetup.new(_make_enemy_data(), positions, _mages, wands, 10)
	_history = BattleHistory.new(_setup.make_initial_state(), _setup)
	_apply_state(_history.current_state())


func _make_enemy_data() -> Array[EnemyData]:
	var ember  := SpellData.new("Ember",  "Em",  ["fire"],    Color(1.00, 0.45, 0.10), [], "", 3)
	var frost  := SpellData.new("Frost",  "Fr",  ["water"],   Color(0.25, 0.65, 1.00), [], "", 2)
	var venom  := SpellData.new("Venom",  "Vn",  ["poison"],  Color(0.30, 0.85, 0.20), [], "", 2)
	var amplify := SpellData.new("Amplify","Amp", ["amplify"], Color(0.80, 0.30, 1.00), [], "", 5)
	var shield := SpellData.new("Shield", "Sh",  ["shield"],  Color(0.65, 0.75, 0.90), [], "", 0)

	var goblin   := EnemyData.new("goblin_1",   "Goblin",      40,  Vector2i(1, 1), Color(0.2,  0.65, 0.2))
	var skeleton := EnemyData.new("skeleton_1", "Skeleton",    35,  Vector2i(1, 1), Color(0.8,  0.8,  0.7))
	var witch    := EnemyData.new("witch_1",    "Witch",        50,  Vector2i(1, 1), Color(0.55, 0.1,  0.7))
	var ogre     := EnemyData.new("ogre_1",     "Shield Ogre", 100, Vector2i(2, 1), Color(0.65, 0.25, 0.15))
	var troll    := EnemyData.new("troll_1",    "Troll",        80,  Vector2i(1, 2), Color(0.3,  0.5,  0.2))

	goblin.drop_pool   = [ember, venom]
	skeleton.drop_pool = [frost, shield]
	witch.drop_pool    = [venom, amplify]
	ogre.drop_pool     = [shield, ember]
	troll.drop_pool    = [venom, frost]

	return [goblin, skeleton, witch, ogre, troll]


func _apply_state(state: BattleState) -> void:
	_refresh_enemy_grid(state)
	for i in _setup.mages.size():
		_setup.mages[i].current_hp = state.mage_hp[i]
		_mage_displays[i].queue_redraw()
	_mana_display.setup(state.mana, _setup.max_mana, _panel_height)
	_refresh_wand_charges(state)
	_refresh_ui()
	if _history.can_undo() and state.enemy_hp.is_empty():
		_on_battle_won()


func _refresh_wand_charges(state: BattleState) -> void:
	for i in _wand_displays.size():
		var charges := {}
		var committed := 0
		for slot: SpellSlotData in _setup.wands[i].slots:
			var key := "%d/%s" % [i, slot.id]
			var c: int = state.slot_charges.get(key, 0)
			charges[slot.id] = c
			committed += c
		_wand_displays[i].set_charges(charges)
		_mage_displays[i].set_mana(state.mage_mana_spent[i], _setup.mages[i].mana_allowance)


func _on_battle_won() -> void:
	_cancel_targeting()
	var wands: Array[WandData] = []
	for wd: WandDisplay in _wand_displays:
		wands.append(wd.get_wand_data())
	GameState.mages = _mages
	GameState.wands = wands
	_generate_loot()
	get_tree().change_scene_to_file("res://scenes/loot/loot_screen.tscn")


func _generate_loot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	GameState.pending_loot.clear()
	GameState.pending_loot_wand = WandGenerator.generate(rng)
	GameState.pending_loot.append(WandGenerator._pick_tip_spell(rng))
	for enemy: EnemyData in _setup.enemies:
		if not enemy.drop_pool.is_empty():
			GameState.pending_loot.append(
				enemy.drop_pool[rng.randi_range(0, enemy.drop_pool.size() - 1)])


func _refresh_enemy_grid(state: BattleState) -> void:
	for enemy: EnemyData in _setup.enemies:
		enemy_grid.remove_enemy(enemy.id)
	for i in _setup.enemies.size():
		var enemy := _setup.enemies[i]
		if not state.enemy_hp.has(enemy.id):
			continue
		enemy.current_hp = state.enemy_hp[enemy.id]
		enemy_grid.place_enemy(enemy, _setup.enemy_positions[i])


# --- targeting ---

func _on_body_slot_clicked(wand: WandDisplay, slot_id: String) -> void:
	if _targeting_wand != null:
		_cancel_targeting()
		return
	var mage_index := _wand_displays.find(wand)
	_apply_state(_history.push(ActionAddMana.new(mage_index, slot_id)))


func _on_tip_pressed(wand: WandDisplay) -> void:
	if _targeting_wand == wand:
		_cancel_targeting()
		return
	var mage_index := _wand_displays.find(wand)
	var tip := _setup.wands[mage_index].get_tip_slot()
	if tip == null or tip.spell == null:
		return
	var key := "%d/%s" % [mage_index, tip.id]
	var charges: int = _history.current_state().slot_charges.get(key, 0)
	if charges < tip.spell.mana_cost:
		_apply_state(_history.push(ActionAddMana.new(mage_index, tip.id)))
	elif _history.current_state().mage_mana_spent[mage_index] < _setup.mages[mage_index].mana_allowance:
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
	if event is InputEventKey and event.pressed \
			and event.keycode == KEY_Z and event.ctrl_pressed:
		_on_undo_pressed()
		get_viewport().set_input_as_handled()
		return

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
	var mage_index := _wand_displays.find(_targeting_wand)
	_apply_state(_history.push(ActionZapWand.new(mage_index, cell)))


# --- data factories ---

func _make_mage_data() -> Array[MageData]:
	if not GameState.mages.is_empty():
		return GameState.mages
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
