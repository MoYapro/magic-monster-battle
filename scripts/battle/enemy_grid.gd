class_name EnemyGrid
extends Node2D

const COLS: int = 3
const ROWS: int = 5
var cell_size := Vector2(80.0, 80.0)

const COLOR_CELL := Color(0.18, 0.20, 0.22)
const COLOR_BORDER := Color(0.45, 0.50, 0.55)
const COLOR_LABEL := Color(1.0, 1.0, 1.0)
const COLOR_HP := Color(0.8, 0.95, 0.8)

# cell position -> EnemyData (one entry per occupied cell)
var _cells: Dictionary = {}
# enemy id -> top-left grid position
var _enemy_positions: Dictionary = {}


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

		draw_rect(Rect2(pixel_pos, pixel_size), enemy.color, true)
		draw_rect(Rect2(pixel_pos, pixel_size), Color.WHITE, false, 2.0)

		var font := ThemeDB.fallback_font
		draw_string(font, pixel_pos + Vector2(5, 16), enemy.display_name,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COLOR_LABEL)
		draw_string(font, pixel_pos + Vector2(5, 32),
				"%d / %d" % [enemy.current_hp, enemy.max_hp],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, COLOR_HP)
