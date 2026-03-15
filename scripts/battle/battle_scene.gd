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


func _ready() -> void:
	_setup_mage_wand_rows()
	_populate_test_enemies()


func _setup_mage_wand_rows() -> void:
	var mages := _make_mage_data()
	var wands := _make_wand_data()

	# Pass 1: create and measure to get total panel height
	var wand_displays: Array[WandDisplay] = []
	var total_h := 0.0
	for i in wands.size():
		var wand := WandDisplay.new()
		add_child(wand)
		wand.setup(wands[i])
		wand_displays.append(wand)
		total_h += wand.get_display_size().y
	total_h += ROW_GAP * (wands.size() - 1)

	# Vertically centre rows within content area
	var start_y := MARGIN + (SCREEN_H - MARGIN * 2.0 - total_h) / 2.0

	# Pass 2: position everything
	var mana := ManaDisplay.new()
	add_child(mana)
	mana.position = Vector2(MANA_X, start_y)
	mana.setup(10, 10, total_h)

	var y := start_y
	for i in wand_displays.size():
		var wand: WandDisplay = wand_displays[i]
		wand.position = Vector2(WAND_X, y)

		var mage := MageDisplay.new()
		add_child(mage)
		mage.position = Vector2(MAGE_X, y)
		mage.setup(mages[i], wand.get_display_size().y)

		y += wand.get_display_size().y + ROW_GAP

	_position_enemy_grid(start_y, total_h)


func _position_enemy_grid(panel_top: float, panel_h: float) -> void:
	var cell_h := panel_h / EnemyGrid.ROWS
	enemy_grid.cell_size = Vector2(cell_h, cell_h)
	var grid_w := EnemyGrid.COLS * cell_h
	enemy_grid.position = Vector2(
		WAND_PANEL_W + (BATTLE_PANEL_W - grid_w) / 2.0,
		panel_top
	)
	enemy_grid.queue_redraw()


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
		EnemyData.new("goblin_1", "Goblin", 10, Vector2i(1, 1), Color(0.2, 0.65, 0.2)),
		Vector2i(0, 0)
	)
	enemy_grid.place_enemy(
		EnemyData.new("skeleton_1", "Skeleton", 8, Vector2i(1, 1), Color(0.8, 0.8, 0.7)),
		Vector2i(1, 1)
	)
	enemy_grid.place_enemy(
		EnemyData.new("witch_1", "Witch", 14, Vector2i(1, 1), Color(0.55, 0.1, 0.7)),
		Vector2i(2, 3)
	)
	enemy_grid.place_enemy(
		EnemyData.new("ogre_1", "Shield Ogre", 30, Vector2i(2, 1), Color(0.65, 0.25, 0.15)),
		Vector2i(0, 3)
	)
	enemy_grid.place_enemy(
		EnemyData.new("troll_1", "Troll", 25, Vector2i(1, 2), Color(0.3, 0.5, 0.2)),
		Vector2i(2, 0)
	)
