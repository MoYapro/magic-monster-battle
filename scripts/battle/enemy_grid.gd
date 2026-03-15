class_name EnemyGrid
extends Node2D

const COLS: int = 3
const ROWS: int = 5
var cell_size := Vector2(80.0, 80.0)

const COLOR_CELL := Color(0.18, 0.20, 0.22)
const COLOR_BORDER := Color(0.45, 0.50, 0.55)
const COLOR_LABEL := Color(1.0, 1.0, 1.0)
const COLOR_HP := Color(0.8, 0.95, 0.8)
const COLOR_TARGET_AVAILABLE := Color(1.0, 0.85, 0.2)
const COLOR_TARGET_HOVER := Color(0.95, 0.18, 0.18)

# cell position -> EnemyData (one entry per occupied cell)
var _cells: Dictionary = {}
# enemy id -> top-left grid position
var _enemy_positions: Dictionary = {}
var _highlighted := false
var _hovered_cells: Array[Vector2i] = []


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered_cells(cells: Array[Vector2i]) -> void:
	_hovered_cells = cells
	queue_redraw()


static func get_hit_cells(target: Vector2i, pattern: Array[Vector2i]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in pattern:
		var cell := target + offset
		if cell.x < 0 or cell.x >= COLS or cell.y < 0 or cell.y >= ROWS:
			continue
		if not result.has(cell):
			result.append(cell)
	return result


func get_cell_at(local_pos: Vector2) -> Vector2i:
	var col := int(local_pos.x / cell_size.x)
	var row := int(local_pos.y / cell_size.y)
	if col < 0 or col >= COLS or row < 0 or row >= ROWS:
		return Vector2i(-1, -1)
	return Vector2i(col, row)



# --- pure static helpers (unit-testable, no scene tree needed) ---

static func get_cells_for_enemy(grid_pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row in grid_size.y:
		for col in grid_size.x:
			cells.append(grid_pos + Vector2i(col, row))
	return cells


static func is_within_bounds(grid_pos: Vector2i, grid_size: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.y < 0:
		return false
	if grid_pos.x + grid_size.x > COLS:
		return false
	if grid_pos.y + grid_size.y > ROWS:
		return false
	return true


# --- placement ---

func can_place_enemy(grid_pos: Vector2i, grid_size: Vector2i) -> bool:
	if not is_within_bounds(grid_pos, grid_size):
		return false
	for cell in get_cells_for_enemy(grid_pos, grid_size):
		if _cells.has(cell):
			return false
	return true


func place_enemy(enemy: EnemyData, grid_pos: Vector2i) -> bool:
	if not can_place_enemy(grid_pos, enemy.grid_size):
		return false
	for cell in get_cells_for_enemy(grid_pos, enemy.grid_size):
		_cells[cell] = enemy
	_enemy_positions[enemy.id] = grid_pos
	queue_redraw()
	return true


func remove_enemy(enemy_id: String) -> void:
	if not _enemy_positions.has(enemy_id):
		return
	var to_remove: Array[Vector2i] = []
	for cell: Vector2i in _cells:
		if (_cells[cell] as EnemyData).id == enemy_id:
			to_remove.append(cell)
	for cell in to_remove:
		_cells.erase(cell)
	_enemy_positions.erase(enemy_id)
	queue_redraw()


func get_enemy_at(grid_pos: Vector2i) -> EnemyData:
	return _cells.get(grid_pos, null)


func apply_damage(cell: Vector2i, amount: int) -> void:
	var enemy: EnemyData = _cells.get(cell, null)
	if enemy == null:
		return
	enemy.current_hp -= amount
	if enemy.current_hp <= 0:
		remove_enemy(enemy.id)
	else:
		queue_redraw()


# --- rendering ---

func _draw() -> void:
	_draw_grid()
	_draw_enemies()


func _draw_grid() -> void:
	for row in ROWS:
		for col in COLS:
			var rect := Rect2(Vector2(col, row) * cell_size, cell_size)
			draw_rect(rect, COLOR_CELL, true)
			draw_rect(rect, COLOR_BORDER, false)
			if _hovered_cells.has(Vector2i(col, row)):
				draw_rect(rect, COLOR_TARGET_HOVER, false, 3.0)
			elif _highlighted:
				draw_rect(rect, COLOR_TARGET_AVAILABLE, false, 2.5)


func _draw_enemies() -> void:
	var drawn: Dictionary = {}
	for cell_pos: Vector2i in _cells:
		var enemy: EnemyData = _cells[cell_pos]
		if drawn.has(enemy.id):
			continue
		drawn[enemy.id] = true

		var grid_pos: Vector2i = _enemy_positions[enemy.id]
		var pixel_pos := Vector2(grid_pos) * cell_size
		var pixel_size := Vector2(enemy.grid_size) * cell_size

		var enemy_rect := Rect2(pixel_pos, pixel_size)
		draw_rect(enemy_rect, enemy.color, true)

		var occupied := get_cells_for_enemy(grid_pos, enemy.grid_size)
		var is_hovered := false
		for hc in _hovered_cells:
			if occupied.has(hc):
				is_hovered = true
				break
		var border_color := COLOR_TARGET_HOVER if is_hovered \
				else (COLOR_TARGET_AVAILABLE if _highlighted else Color.WHITE)
		var border_width := 3.0 if (is_hovered or _highlighted) else 2.0
		draw_rect(enemy_rect, border_color, false, border_width)

		var font := ThemeDB.fallback_font
		draw_string(font, pixel_pos + Vector2(5, 16), enemy.display_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_LABEL)
		draw_string(font, pixel_pos + Vector2(5, 32),
				"%d / %d" % [enemy.current_hp, enemy.max_hp],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_HP)
