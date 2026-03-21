extends Node2D

const _MONSTERS: Array = [
	["Goblin",        preload("res://scripts/battle/monsters/goblin.gd")],
	["Skeleton",      preload("res://scripts/battle/monsters/skeleton.gd")],
	["Witch",         preload("res://scripts/battle/monsters/witch.gd")],
	["Troll",         preload("res://scripts/battle/monsters/troll.gd")],
	["Shield Ogre",   preload("res://scripts/battle/monsters/shield_ogre.gd")],
	["Scorpion",      preload("res://scripts/battle/monsters/scorpion.gd")],
	["Fire Elemental",preload("res://scripts/battle/monsters/fire_elemental.gd")],
	["Treant",        preload("res://scripts/battle/monsters/treant.gd")],
	["Stone Giant",   preload("res://scripts/battle/monsters/stone_giant.gd")],
	["Frost Mage",    preload("res://scripts/battle/monsters/frost_mage.gd")],
	["Bog Shambler",  preload("res://scripts/battle/monsters/bog_shambler.gd")],
	["Cave Spider",   preload("res://scripts/battle/monsters/cave_spider.gd")],
	["Cursed Knight", preload("res://scripts/battle/monsters/cursed_knight.gd")],
]

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
var _intent_hover_enemy: String = ""
var _intent_hover_mage: int = -1

# debug placement
var _battle_enemies: Array[EnemyData] = []
var _battle_positions: Array[Vector2i] = []
var _place_cls: Variant = null
var _place_size: Vector2i = Vector2i(1, 1)
var _place_id_counter: Dictionary = {}
var _place_dropdown: OptionButton = null


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

	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.size = Vector2(70, BOTTOM_BAR_H - 10)
	clear_button.position = Vector2(220, SCREEN_H - BOTTOM_BAR_H + 5)
	clear_button.pressed.connect(_on_clear_pressed)
	layer.add_child(clear_button)

	_place_dropdown = OptionButton.new()
	_place_dropdown.size = Vector2(175, BOTTOM_BAR_H - 10)
	_place_dropdown.position = Vector2(298, SCREEN_H - BOTTOM_BAR_H + 5)
	_place_dropdown.add_item("Place...")
	for entry in _MONSTERS:
		_place_dropdown.add_item(entry[0])
	_place_dropdown.item_selected.connect(_on_place_item_selected)
	layer.add_child(_place_dropdown)

	var battle_label := Label.new()
	battle_label.text = "Battle %d" % (GameState.battle_count + 1)
	battle_label.position = Vector2(16, SCREEN_H - BOTTOM_BAR_H)
	battle_label.size = Vector2(200, BOTTOM_BAR_H)
	battle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	battle_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.70))
	layer.add_child(battle_label)

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

	var reroll_button := Button.new()
	reroll_button.text = "↺ Reroll"
	reroll_button.size = Vector2(90, BOTTOM_BAR_H - 10)
	reroll_button.position = Vector2(SCREEN_W - 210, SCREEN_H - BOTTOM_BAR_H + 5)
	reroll_button.pressed.connect(_on_reroll_pressed)
	layer.add_child(reroll_button)

	_undo_button = Button.new()
	_undo_button.text = "↩ Undo  Ctrl+Z"
	_undo_button.size = Vector2(148, BOTTOM_BAR_H - 10)
	_undo_button.position = Vector2(SCREEN_W - 112, SCREEN_H - BOTTOM_BAR_H + 5)
	_undo_button.pressed.connect(_on_undo_pressed)
	layer.add_child(_undo_button)


func _on_end_turn_pressed() -> void:
	_cancel_targeting()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_apply_state(_history.push(ActionEndTurn.new(rng.seed)))


func _on_undo_pressed() -> void:
	if _history != null and _history.can_undo():
		_apply_state(_history.undo())


func _on_reroll_pressed() -> void:
	_cancel_targeting()
	_place_cls = null
	_build_setup()


func _on_clear_pressed() -> void:
	_cancel_targeting()
	_place_cls = null
	_battle_enemies.clear()
	_battle_positions.clear()
	_place_id_counter.clear()
	_rebuild_battle()


func _on_place_item_selected(index: int) -> void:
	if index == 0:
		_place_cls = null
		return
	_cancel_targeting()
	var entry: Array = _MONSTERS[index - 1]
	_place_cls = entry[1]
	_place_size = (_place_cls.new() as EnemyData).grid_size


func _place_enemy_at(cell: Vector2i) -> void:
	var occupied: Dictionary = {}
	for i in _battle_positions.size():
		var sz: Vector2i = _battle_enemies[i].grid_size
		for dx in range(sz.x):
			for dy in range(sz.y):
				occupied[_battle_positions[i] + Vector2i(dx, dy)] = true
	for dx in range(_place_size.x):
		for dy in range(_place_size.y):
			var c := cell + Vector2i(dx, dy)
			if c.x >= EnemyGrid.COLS or c.y >= EnemyGrid.ROWS or occupied.has(c):
				return
	var enemy: EnemyData = _place_cls.new()
	var base_id := enemy.display_name.to_lower().replace(" ", "_")
	_place_id_counter[base_id] = _place_id_counter.get(base_id, 0) + 1
	enemy.id = base_id + "_" + str(_place_id_counter[base_id])
	_battle_enemies.append(enemy)
	_battle_positions.append(cell)
	_rebuild_battle()
	_place_dropdown.select(0)
	_place_cls = null


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
		wand.body_slot_right_clicked.connect(_on_body_slot_right_clicked)
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
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var biome: BiomeData = GameState.current_biome
	if biome == null:
		biome = BiomesData.all()[0]
	var biome_level: int = GameState.battle_count_by_biome.get(biome.name, 0) + 1
	var composition := BattleComposer.compose(biome, biome_level, rng)
	_battle_enemies = composition["enemies"]
	_battle_positions = composition["positions"]
	_place_id_counter.clear()
	var wands: Array[WandData] = []
	for wd: WandDisplay in _wand_displays:
		wands.append(wd.get_wand_data())
	_setup = BattleSetup.new(_battle_enemies, _battle_positions, _mages, wands, 10, composition["obstacles"], composition["obstacle_positions"])
	_history = BattleHistory.new(_setup.make_initial_state(), _setup)
	_apply_state(_history.current_state())


func _rebuild_battle() -> void:
	var prev := _history.current_state()
	var wands: Array[WandData] = []
	for wd: WandDisplay in _wand_displays:
		wands.append(wd.get_wand_data())
	_setup = BattleSetup.new(_battle_enemies, _battle_positions, _mages, wands, _setup.max_mana, _setup.obstacles, _setup.obstacle_positions)
	var new_state := _setup.make_initial_state()
	for i in new_state.mage_hp.size():
		new_state.mage_hp[i] = prev.mage_hp[i]
	new_state.mana = prev.mana
	new_state.slot_charges = prev.slot_charges.duplicate()
	new_state.mage_mana_spent = prev.mage_mana_spent.duplicate()
	_history = BattleHistory.new(new_state, _setup)
	_apply_state(_history.current_state())


func _apply_state(state: BattleState) -> void:
	_refresh_enemy_grid(state)
	for i in _setup.mages.size():
		_setup.mages[i].current_hp = state.mage_hp[i]
		var poison := state.mage_poison[i] if i < state.mage_poison.size() else 0
		var fire := state.mage_fire[i] if i < state.mage_fire.size() else 0
		var incoming_attack := 0
		for enemy_id: String in state.monster_intents:
			var intent: Dictionary = state.monster_intents[enemy_id]
			if intent.get("target", -1) != i or not state.enemy_hp.has(enemy_id):
				continue
			if state.enemy_frozen.has(enemy_id):
				continue
			var enemy := _setup.get_enemy(enemy_id)
			if enemy == null:
				continue
			var action_index: int = intent.get("action_index", 0)
			if action_index >= enemy.action_pool.size():
				continue
			var action := enemy.action_pool[action_index]
			if action is MonsterActionAttack:
				incoming_attack += (action as MonsterActionAttack).damage
		_mage_displays[i].set_status(poison, fire, incoming_attack)
	_mana_display.setup(state.mana, _setup.max_mana, _panel_height)
	_refresh_wand_charges(state)
	_refresh_ui()
	var all_mages_dead := true
	for hp: int in state.mage_hp:
		if hp > 0:
			all_mages_dead = false
			break
	if all_mages_dead:
		_on_battle_lost()
		return
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
		var webbed := {}
		for slot: SpellSlotData in _setup.wands[i].slots:
			if state.webbed_slots.has("%d/%s" % [i, slot.id]):
				webbed[slot.id] = true
		_wand_displays[i].set_webbed(webbed)
		_mage_displays[i].set_mana(state.mage_mana_spent[i], _setup.mages[i].mana_allowance)


func _on_battle_lost() -> void:
	_cancel_targeting()
	get_tree().change_scene_to_file("res://scenes/game_over/game_over_screen.tscn")


func _on_battle_won() -> void:
	_cancel_targeting()
	GameState.battle_count += 1
	if GameState.current_biome != null:
		var biome_name := GameState.current_biome.name
		GameState.battle_count_by_biome[biome_name] = GameState.battle_count_by_biome.get(biome_name, 0) + 1
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
	GameState.pending_loot_wands.clear()
	GameState.pending_loot_wands.append(WandGenerator.generate(rng))
	GameState.pending_loot.append(WandGenerator._pick_tip_spell(rng))
	for enemy: EnemyData in _setup.enemies:
		if not enemy.drop_pool.is_empty():
			GameState.pending_loot.append(
				enemy.drop_pool[rng.randi_range(0, enemy.drop_pool.size() - 1)])


func _refresh_enemy_grid(state: BattleState) -> void:
	enemy_grid.clear_enemies()
	for i in _setup.enemies.size():
		var enemy := _setup.enemies[i]
		if not state.enemy_hp.has(enemy.id):
			continue
		enemy.current_hp = state.enemy_hp[enemy.id]
		enemy_grid.place_enemy(enemy, _setup.enemy_positions[i])
	enemy_grid.set_intents(state.monster_intents)
	enemy_grid.set_armors(state.enemy_armor)
	enemy_grid.set_blocks(state.enemy_block)
	enemy_grid.set_statuses(state.enemy_poison, state.enemy_fire)


# --- targeting ---

func _on_body_slot_clicked(wand: WandDisplay, slot_id: String) -> void:
	if _targeting_wand != null:
		_cancel_targeting()
		return
	var mage_index := _wand_displays.find(wand)
	if _history.current_state().mage_hp[mage_index] <= 0:
		return
	_apply_state(_history.push(ActionAddMana.new(mage_index, slot_id)))


func _on_body_slot_right_clicked(wand: WandDisplay, slot_id: String) -> void:
	if _targeting_wand != null:
		return
	var mage_index := _wand_displays.find(wand)
	if _history.current_state().mage_hp[mage_index] <= 0:
		return
	_apply_state(_history.push(ActionRemoveMana.new(mage_index, slot_id)))


func _on_tip_pressed(wand: WandDisplay) -> void:
	if _targeting_wand == wand:
		_cancel_targeting()
		return
	var mage_index := _wand_displays.find(wand)
	if _history.current_state().mage_hp[mage_index] <= 0:
		return
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
	_clear_intent_hover()
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


func _update_intent_hover(mouse: Vector2) -> void:
	var cell := enemy_grid.get_cell_at(enemy_grid.to_local(mouse))
	var hovered_id := ""
	if cell.x >= 0:
		var enemy := enemy_grid.get_enemy_at(cell)
		if enemy != null:
			hovered_id = enemy.id
	if hovered_id == _intent_hover_enemy:
		return
	_clear_intent_hover()
	_intent_hover_enemy = hovered_id
	if hovered_id != "":
		var intent: Dictionary = _history.current_state().monster_intents.get(hovered_id, {})
		_intent_hover_mage = intent.get("target", -1)
		if _intent_hover_mage >= 0 and _intent_hover_mage < _mage_displays.size():
			_mage_displays[_intent_hover_mage].set_highlighted(true)
	queue_redraw()


func _clear_intent_hover() -> void:
	if _intent_hover_mage >= 0 and _intent_hover_mage < _mage_displays.size():
		_mage_displays[_intent_hover_mage].set_highlighted(false)
	_intent_hover_enemy = ""
	_intent_hover_mage = -1
	queue_redraw()


func _draw() -> void:
	if _intent_hover_enemy == "" or _intent_hover_mage < 0:
		return
	var from := _get_enemy_scene_center(_intent_hover_enemy)
	var to := _mage_displays[_intent_hover_mage].position \
			+ _mage_displays[_intent_hover_mage].get_rect().get_center()
	var color := Color(1.0, 0.45, 0.1, 0.9)
	draw_line(from, to, color, 2.5, true)
	var dir := (to - from).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var tip := to - dir * 4.0
	draw_line(tip - dir * 10.0 + perp * 6.0, tip, color, 2.5, true)
	draw_line(tip - dir * 10.0 - perp * 6.0, tip, color, 2.5, true)


func _get_enemy_scene_center(enemy_id: String) -> Vector2:
	for i in _setup.enemies.size():
		if _setup.enemies[i].id == enemy_id:
			var enemy := _setup.enemies[i]
			var px := Vector2(_setup.enemy_positions[i]) * enemy_grid.cell_size
			var ps := Vector2(enemy.grid_size) * enemy_grid.cell_size
			return enemy_grid.position + px + ps * 0.5
	return Vector2.ZERO


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

	if _place_cls != null:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			enemy_grid.set_hovered_cells([])
			_place_dropdown.select(0)
			_place_cls = null
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseMotion:
			var cell := enemy_grid.get_cell_at(enemy_grid.to_local((event as InputEventMouseMotion).position))
			var cells: Array[Vector2i] = []
			if cell.x >= 0:
				for dx in range(_place_size.x):
					for dy in range(_place_size.y):
						cells.append(cell + Vector2i(dx, dy))
			enemy_grid.set_hovered_cells(cells)
			return
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			var cell := enemy_grid.get_cell_at(enemy_grid.to_local((event as InputEventMouseButton).position))
			if cell.x >= 0:
				enemy_grid.set_hovered_cells([])
				_place_enemy_at(cell)
				get_viewport().set_input_as_handled()
			return

	if _targeting_wand == null:
		if event is InputEventMouseMotion:
			_update_intent_hover((event as InputEventMouseMotion).position)
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
		get_viewport().set_input_as_handled()
		_fire_at_cell(cell)
		_cancel_targeting()
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
	var result: Array[WandData] = []
	for i in _mages.size():
		var w: WandData = GameState.wands[i] if i < GameState.wands.size() else null
		result.append(w if w != null else WandGenerator.generate(rng))
	return result
