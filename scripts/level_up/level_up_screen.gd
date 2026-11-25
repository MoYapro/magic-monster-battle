extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const BOTTOM_BAR_H := EmberDraw.BOTTOM_BAR_H

const CARD_W := 360.0
const CARD_H := 494.0
const CARD_GAP := 40.0
const CARD_Y := 116.0
const CARDS_TOTAL_W := 3.0 * CARD_W + 2.0 * CARD_GAP
const CARD_MARGIN := (SCREEN_W - CARDS_TOTAL_W) * 0.5

const OPTION_H := 110.0
const OPTION_PAD := 24.0
const HP_GAIN := MageProgression.HP_GAIN
const MANA_GAIN := MageProgression.MANA_GAIN
const STATS := ["hp", "mana"]

var _mages: Array[MageData] = []
var _heal_button: Button = null
var _hovered := Vector2i(-1, -1)  # (mage, stat index) under the mouse


func _ready() -> void:
	_mages = GameState.mages
	_build_bottom_bar()


func _draw() -> void:
	EmberDraw.backdrop(self)
	EmberDraw.title_plate(self, Rect2(440, 10, 400, 40), "The Embers Grow")
	EmberDraw.text(self, Vector2(24, 36), "Battle %d won" % GameState.battle_count, 18, Palette.COLOR_TEXT_DIM, true)
	EmberDraw.text_centered(self, SCREEN_W / 2.0, 92, "One mage may draw strength from the fire.", 17, Palette.COLOR_TEXT_DIM)
	for i in _mages.size():
		_draw_mage_card(i)
	EmberDraw.bottom_bar(self, "Pick one upgrade, or heal the whole party instead")


func _card_x(i: int) -> float:
	return CARD_MARGIN + i * (CARD_W + CARD_GAP)


func _option_rect(mage_i: int, stat: String) -> Rect2:
	var y := CARD_Y + 230.0 + (0.0 if stat == "hp" else OPTION_H + 20.0)
	return Rect2(Vector2(_card_x(mage_i) + OPTION_PAD, y), Vector2(CARD_W - OPTION_PAD * 2.0, OPTION_H))


func _draw_mage_card(i: int) -> void:
	var mage := _mages[i]
	var card := Rect2(_card_x(i), CARD_Y, CARD_W, CARD_H)
	var hot := _hovered.x == i
	EmberDraw.panel(self, card, hot)
	var cx := card.get_center().x
	EmberDraw.medallion(self, Vector2(cx, CARD_Y + 74), 46, MageColors.color_for(mage.name), hot)
	EmberDraw.text_centered(self, cx, CARD_Y + 152, mage.name, 26, Palette.COLOR_TEXT_BRIGHT, true)
	EmberDraw.hp_bar(self, Rect2(cx - 100, CARD_Y + 166, 200, 9), mage.current_hp, mage.max_hp)
	EmberDraw.text_centered(self, cx, CARD_Y + 196, "%d/%d" % [mage.current_hp, mage.max_hp], 14, Palette.COLOR_TEXT_DIM)
	_draw_option(i, "hp", "♥", Palette.COLOR_HP_LOW, "Vitality", "Max HP", mage.max_hp, HP_GAIN)
	_draw_option(i, "mana", "✦", Palette.COLOR_MANA, "Attunement", "Mana per turn", mage.mana_allowance, MANA_GAIN)


func _draw_option(mage_i: int, stat: String, symbol: String, color: Color, title: String, label: String,
		current: int, gain: int) -> void:
	var r := _option_rect(mage_i, stat)
	var hot := _hovered == Vector2i(mage_i, STATS.find(stat))
	EmberDraw.rounded_rect(self, r, Palette.COLOR_SELECTED_BG.lerp(Color("#4a2a12"), 0.6) if hot else Palette.COLOR_PANEL_RAISED,
			Palette.COLOR_ACCENT if hot else Palette.COLOR_BORDER, 2 if hot else 1, 3)
	var icon := r.position + Vector2(42, r.size.y / 2.0)
	if hot:
		EmberDraw.glow(self, icon, 44, 0.7)
	draw_circle(icon, 22, Palette.COLOR_HP_BG)
	draw_arc(icon, 22, 0.0, TAU, 32, color, 1.5, true)
	EmberDraw.text_centered(self, icon.x, icon.y + 7, symbol, 20, color)
	var tx := r.position.x + 82
	EmberDraw.text(self, Vector2(tx, r.position.y + 38), title, 20, Palette.COLOR_TEXT_BRIGHT, true)
	EmberDraw.text(self, Vector2(tx, r.position.y + 60), label, 14, Palette.COLOR_TEXT_DIM)
	EmberDraw.text(self, Vector2(tx, r.position.y + 90), "%d → %d" % [current, current + gain], 20, color, true)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover((event as InputEventMouseMotion).position)
		return
	if not (event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var pos := (event as InputEventMouseButton).position
	for i in _mages.size():
		for stat in STATS:
			if _option_rect(i, stat).has_point(pos):
				get_viewport().set_input_as_handled()
				_apply_upgrade(i, stat)
				return


func _update_hover(pos: Vector2) -> void:
	var hovered := Vector2i(-1, -1)
	for i in _mages.size():
		for k in STATS.size():
			if _option_rect(i, STATS[k]).has_point(pos):
				hovered = Vector2i(i, k)
	if hovered != _hovered:
		_hovered = hovered
		queue_redraw()


func _build_bottom_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_heal_button = Button.new()
	_heal_button.text = "Heal All ♥"
	_heal_button.size = Vector2(150, 36)
	_heal_button.position = Vector2(SCREEN_W - 190.0, SCREEN_H - BOTTOM_BAR_H + 10.0)
	_heal_button.pressed.connect(_on_heal_all_pressed)
	layer.add_child(_heal_button)


func _on_heal_all_pressed() -> void:
	MageProgression.heal_all(_mages)
	GameState.mages = _mages
	get_tree().change_scene_to_file("res://scenes/world/path_selection_screen.tscn")


func _apply_upgrade(mage_i: int, stat: String) -> void:
	MageProgression.apply_upgrade(_mages[mage_i], stat)
	GameState.mages = _mages
	get_tree().change_scene_to_file("res://scenes/world/path_selection_screen.tscn")
