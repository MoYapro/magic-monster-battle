extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0

const CARD_W := 460.0
const CARD_H := 420.0
const CARD_GAP := 140.0
const CARDS_TOTAL_W := 2.0 * CARD_W + CARD_GAP
const CARD_X_LEFT  := (SCREEN_W - CARDS_TOTAL_W) * 0.5
const CARD_X_RIGHT := CARD_X_LEFT + CARD_W + CARD_GAP
const CARD_X_CENTER := (SCREEN_W - CARD_W) * 0.5
const DEAD_END_BTN_SIZE := Vector2(180, 44)
const CARD_Y := 76.0
const HERE := Vector2(640.0, 604.0)  # the "you are here" waypoint

var _choices: Array[BiomeData] = []
var _hovered := -1


func _ready() -> void:
	_pick_choices()
	if _choices.is_empty():
		_build_dead_end_button()


func _pick_choices() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_choices = RunProgress.pick_path_choices(GameState.battle_count_by_biome, rng)


func _card_x(i: int) -> float:
	if _choices.size() == 1:
		return CARD_X_CENTER
	return CARD_X_LEFT if i == 0 else CARD_X_RIGHT


func _card_rect(i: int) -> Rect2:
	return Rect2(Vector2(_card_x(i), CARD_Y), Vector2(CARD_W, CARD_H))


func _draw() -> void:
	EmberDraw.backdrop(self)
	EmberDraw.title_plate(self, Rect2(440, 10, 400, 40), "Choose Your Path")
	EmberDraw.text(self, Vector2(24, 36), "Next: battle %d" % (GameState.battle_count + 1), 18, Palette.COLOR_TEXT_DIM, true)
	EmberDraw.bottom_bar(self, "Choose a road · each grows harder the more often it is walked")
	if _choices.is_empty():
		_draw_dead_end()
	for i in _choices.size():
		_draw_road(i)
	for i in _choices.size():
		_draw_card(i)
	if not _choices.is_empty():
		draw_circle(HERE, 9.0, Palette.COLOR_ACCENT)
		draw_arc(HERE, 9.0, 0.0, TAU, 24, Palette.COLOR_TEXT_BRIGHT, 1.2, true)
		EmberDraw.text_centered(self, HERE.x, HERE.y + 30.0, "you are here", 13, Palette.COLOR_TEXT_DIM)


func _draw_dead_end() -> void:
	EmberDraw.text_centered(self, SCREEN_W / 2.0, SCREEN_H * 0.5 - 20.0, "You have reached a dead end", 32, Palette.COLOR_TEXT_BRIGHT, true)


func _build_dead_end_button() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var btn := Button.new()
	btn.text = "Then I lose"
	btn.size = DEAD_END_BTN_SIZE
	btn.position = Vector2((SCREEN_W - DEAD_END_BTN_SIZE.x) * 0.5, SCREEN_H * 0.5 + 20.0)
	btn.pressed.connect(_on_then_i_lose_pressed)
	layer.add_child(btn)


func _on_then_i_lose_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game_over/game_over_screen.tscn")


## Dotted road from the waypoint up to a card; the hovered road glows.
func _draw_road(i: int) -> void:
	var r := _card_rect(i)
	var to := Vector2(r.get_center().x, r.end.y + 6.0)
	var ctrl := Vector2((HERE.x + to.x) / 2.0, to.y + 50.0)
	var col := Palette.COLOR_ACCENT if i == _hovered else Palette.COLOR_BORDER
	for k in 28:
		var t := k / 27.0
		var p := HERE.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t)
		draw_circle(p, 2.2 if i == _hovered else 1.6, col)


func _draw_card(i: int) -> void:
	var biome := _choices[i]
	var r := _card_rect(i)
	var hot := i == _hovered
	if hot:
		EmberDraw.glow(self, r.get_center(), r.size.x * 0.7, 0.35)
	EmberDraw.panel(self, r, hot)
	var art := Rect2(r.position + Vector2(20, 20), Vector2(r.size.x - 40, 200))
	draw_rect(art, Color(biome.color, 0.16))
	_draw_emblem(art.get_center(), biome, hot)
	var cx := r.get_center().x
	EmberDraw.text_centered(self, cx, r.position.y + 272, biome.name, 34, Palette.COLOR_TEXT_BRIGHT, true)
	draw_line(Vector2(cx - 90, r.position.y + 286), Vector2(cx + 90, r.position.y + 286), Palette.COLOR_BORDER, 1.0)
	EmberDraw.text_centered(self, cx, r.position.y + 316, "“%s”" % biome.tagline, 15, Palette.COLOR_TEXT_DIM)
	var level: int = GameState.battle_count_by_biome.get(biome.name, 0) + 1
	EmberDraw.text_centered(self, cx, r.position.y + 352, "Approach %d of %d" % [level, BattleComposer.MAX_LEVEL], 14, Palette.COLOR_ACCENT)
	var total := BattleComposer.MAX_LEVEL
	EmberDraw.mana_pips(self, Vector2(cx - (total - 1) * 9.0, r.position.y + 378), level - 1, total, 5.0, 18.0)


## Round compass emblem with the area's initial in its colour.
func _draw_emblem(c: Vector2, biome: BiomeData, hot: bool) -> void:
	var col := biome.color.lightened(0.2)
	if hot:
		EmberDraw.glow(self, c, 110, 0.8)
	draw_circle(c, 64, Color("#33241a"))
	draw_arc(c, 64, 0.0, TAU, 64, col, 2.5, true)
	draw_arc(c, 54, 0.0, TAU, 64, Color(col, 0.35), 1.0, true)
	for k in 8:
		var d := Vector2.from_angle(k * TAU / 8.0)
		draw_line(c + d * 58, c + d * (70 if k % 2 == 0 else 66), col, 1.5, true)
	EmberDraw.text_centered(self, c.x, c.y + 18, biome.name.left(1), 52, col, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	for i in _choices.size():
		if _card_rect(i).has_point(pos):
			get_viewport().set_input_as_handled()
			GameState.current_biome = _choices[i]
			get_tree().change_scene_to_file("res://scenes/loot/loot_screen.tscn")
			return


func _update_hover(pos: Vector2) -> void:
	var hovered := -1
	for i in _choices.size():
		if _card_rect(i).has_point(pos):
			hovered = i
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()
