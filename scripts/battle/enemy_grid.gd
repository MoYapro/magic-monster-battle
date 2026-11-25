class_name EnemyGrid
extends Node2D

const COLS: int = 5
const ROWS: int = 7
var cell_size := Vector2(80.0, 80.0)

# cell position -> EnemyData (one entry per occupied cell)
var _cells: Dictionary = {}
# enemy id -> top-left grid position
var _enemy_positions: Dictionary = {}
var _obstacles: Array[ObstacleData] = []
var _obstacle_positions: Array[Vector2i] = []
var _obstacle_hp: Dictionary = {}
var _ground: Dictionary = {}  # Vector2i -> GroundType.Type
var _highlighted := false
var _hovered_cells: Array[Vector2i] = []
var _hover_blocked: bool = false
var _intents: Dictionary = {}
var _armors: Dictionary = {}
var _blocks: Dictionary = {}
var _shields: Dictionary = {}
var _enemy_statuses: Dictionary = {}  # enemy_id -> Array[StatusData]


func set_armors(armors: Dictionary) -> void:
	_armors = armors
	queue_redraw()


func set_blocks(blocks: Dictionary) -> void:
	_blocks = blocks
	queue_redraw()


func set_shields(shields: Dictionary) -> void:
	_shields = shields
	queue_redraw()


func set_statuses(enemy_statuses: Dictionary) -> void:
	_enemy_statuses = enemy_statuses
	queue_redraw()


func set_ground(ground: Dictionary) -> void:
	_ground = ground
	queue_redraw()


func set_intents(intents: Dictionary) -> void:
	_intents = intents
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered_cells(cells: Array[Vector2i], blocked: bool = false) -> void:
	_hovered_cells = cells
	_hover_blocked = blocked
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


# In-bounds cells touching the occupant (including diagonals), excluding its own cells.
static func get_surrounding_cells(grid_pos: Vector2i, grid_size: Vector2i) -> Array[Vector2i]:
	var own := get_cells_for_enemy(grid_pos, grid_size)
	var result: Array[Vector2i] = []
	for row in range(grid_pos.y - 1, grid_pos.y + grid_size.y + 1):
		for col in range(grid_pos.x - 1, grid_pos.x + grid_size.x + 1):
			var cell := Vector2i(col, row)
			if not own.has(cell) and is_within_bounds(cell, Vector2i.ONE):
				result.append(cell)
	return result


# In-bounds cells next to any hit cell, excluding the hit cells: orthogonal at level 1, all 8 at level 2+.
static func get_splash_cells(hit_cells: Array[Vector2i], level: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if level <= 0:
		return result
	for cell: Vector2i in hit_cells:
		for offset: Vector2i in _splash_offsets(level):
			var n := cell + offset
			if not hit_cells.has(n) and not result.has(n) and is_within_bounds(n, Vector2i.ONE):
				result.append(n)
	return result


static func _splash_offsets(level: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	if level >= 2:
		offsets.append_array([Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)])
	return offsets


static func is_within_bounds(grid_pos: Vector2i, grid_size: Vector2i) -> bool:
	if grid_pos.x < 0 or grid_pos.y < 0:
		return false
	if grid_pos.x + grid_size.x > COLS:
		return false
	if grid_pos.y + grid_size.y > ROWS:
		return false
	return true


func clear_enemies() -> void:
	_cells.clear()
	_enemy_positions.clear()
	queue_redraw()


func set_obstacles(obstacles: Array[ObstacleData], positions: Array[Vector2i], hp: Dictionary) -> void:
	_obstacles = obstacles
	_obstacle_positions = positions
	_obstacle_hp = hp
	queue_redraw()


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

const OBSTACLE_TILES := {"stone": "stone_3", "boulder": "stone_3"}
const CELL_LINE := Color(0.04, 0.03, 0.02, 0.85)

var _ground_base: Array[String] = GroundTiles.DEFAULT_BASE
var _art: Dictionary = {}  # art id -> Texture2D (or null when the monster has no art yet)
var _title := ""


func set_title(title: String) -> void:
	_title = title
	queue_redraw()


func set_ground_tiles(base: Array[String]) -> void:
	_ground_base = base
	queue_redraw()


func _draw() -> void:
	_draw_frame()
	_draw_grid()
	_draw_obstacles()
	_draw_enemies()
	_draw_targeting()


func _draw_frame() -> void:
	var grid := Rect2(Vector2.ZERO, Vector2(COLS, ROWS) * cell_size)
	EmberDraw.panel(self, grid.grow(18))
	if not _title.is_empty():
		EmberDraw.title_plate(self, Rect2(grid.size.x / 2.0 - 150.0, -38.0, 300.0, 32.0), _title)


func _draw_grid() -> void:
	for row in ROWS:
		for col in COLS:
			var cell := Vector2i(col, row)
			var rect := Rect2(Vector2(cell) * cell_size, cell_size)
			var ground: GroundType.Type = _ground.get(cell, GroundType.Type.SOIL)
			var tex := GroundTiles.texture(GroundTiles.tile_for(_ground_base, ground, cell))
			if tex != null:
				draw_texture_rect(tex, rect, false)
			else:
				draw_rect(rect, Palette.COLOR_GRID_CELL, true)
			draw_rect(rect, CELL_LINE, false, 1.5)


## Target overlays go on top of tokens so a monster under the reticle is visibly targeted.
func _draw_targeting() -> void:
	var target := Palette.COLOR_TARGET_BLOCKED if _hover_blocked else Palette.COLOR_TARGET_AVAILABLE
	for row in ROWS:
		for col in COLS:
			var rect := Rect2(Vector2(col, row) * cell_size, cell_size).grow(-1.5)
			if _hovered_cells.has(Vector2i(col, row)):
				draw_rect(rect, Color(target, 0.22), true)
				draw_rect(rect, target, false, 3.0)
			elif _highlighted:
				draw_rect(rect, Color(Palette.COLOR_TARGET_AVAILABLE, 0.35), false, 1.5)


func _draw_obstacles() -> void:
	for i in _obstacles.size():
		var obs := _obstacles[i]
		if not _obstacle_hp.has(obs.id):
			continue
		var rect := Rect2(Vector2(_obstacle_positions[i]) * cell_size, Vector2(obs.grid_size) * cell_size)
		var tile: String = OBSTACLE_TILES.get(_script_id(obs), "")
		TokenDraw.obstacle(self, rect, obs, _obstacle_hp[obs.id], GroundTiles.texture(tile) if tile else null)


func _draw_enemies() -> void:
	var drawn: Dictionary = {}
	for cell_pos: Vector2i in _cells:
		var enemy: EnemyData = _cells[cell_pos]
		if drawn.has(enemy.id):
			continue
		drawn[enemy.id] = true
		var grid_pos: Vector2i = _enemy_positions[enemy.id]
		_draw_enemy(enemy, Rect2(Vector2(grid_pos) * cell_size, Vector2(enemy.grid_size) * cell_size), grid_pos)


func _draw_enemy(enemy: EnemyData, rect: Rect2, grid_pos: Vector2i) -> void:
	var hovered := get_cells_for_enemy(grid_pos, enemy.grid_size).any(
			func(c: Vector2i) -> bool: return _hovered_cells.has(c))
	var tex := _art_for(enemy)
	if tex != null:
		TokenDraw.art(self, rect, tex)
	else:
		TokenDraw.placeholder(self, rect, enemy)
	TokenDraw.card(self, rect, enemy.color, hovered, _highlighted)
	TokenDraw.hp_bar(self, rect, enemy.current_hp, enemy.max_hp)
	TokenDraw.side_chips(self, rect, _status_chips(enemy.id), _defence_chips(enemy.id))
	if _intents.has(enemy.id):
		TokenDraw.intent_chip(self, rect, IntentLabel.text_for(enemy, _intents[enemy.id]))


func _status_chips(enemy_id: String) -> Array:
	var out := []
	for status: StatusData in _enemy_statuses.get(enemy_id, []):
		if status.display_name != "":
			var stacks := str(status.stacks) if status.stacks > 0 else ""
			out.append([status.icon + stacks, status.display_color])
	return out


func _defence_chips(enemy_id: String) -> Array:
	var out := []
	if _armors.get(enemy_id, 0) > 0:
		out.append(["⛨ %d" % _armors[enemy_id], Palette.COLOR_GRID_INTENT])
	if _shields.get(enemy_id, 0) > 0:
		out.append(["◇ %d" % _shields[enemy_id], Palette.COLOR_GRID_FROZEN])
	if _blocks.get(enemy_id, 0) > 0:
		out.append(["▣ %d" % _blocks[enemy_id], Palette.COLOR_GRID_BLOCK])
	return out


func _art_for(enemy: EnemyData) -> Texture2D:
	var art_id := MonsterRig.art_id_for(enemy)
	if not _art.has(art_id):
		_art[art_id] = MonsterRig.full_texture(art_id)
	return _art[art_id]


static func _script_id(obj: Object) -> String:
	var script: Script = obj.get_script()
	return script.resource_path.get_file().get_basename() if script else ""
