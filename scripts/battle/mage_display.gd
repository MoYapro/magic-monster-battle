class_name MageDisplay
extends Node2D

const WIDTH := 100.0
const PAD := 12.0
const BAR_HEIGHT := 8.0
const PORTRAIT_R := 24.0
const MIN_HEIGHT := 150.0  # portrait, name, HP and mana pips with some air

var _mage: MageData = null
var _height: float = 70.0
var _highlighted := false
var _hovered := false
var _mana_committed: int = 0
var _mana_max: int = 0
var _incoming_attack: int = 0
var _statuses: Array = []
var _shield: int = 0


func setup(mage: MageData, height: float) -> void:
	_mage = mage
	_height = height
	queue_redraw()


func set_highlighted(on: bool) -> void:
	_highlighted = on
	queue_redraw()


func set_hovered(on: bool) -> void:
	_hovered = on
	queue_redraw()


func set_mana(committed: int, max_mana: int) -> void:
	_mana_committed = committed
	_mana_max = max_mana
	queue_redraw()


func set_status(incoming_attack: int = 0, statuses: Array = [], shield: int = 0) -> void:
	_incoming_attack = incoming_attack
	_statuses = statuses
	_shield = shield
	queue_redraw()


func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(WIDTH, _height))


func _draw() -> void:
	if _mage == null:
		return
	var dead := _mage.current_hp <= 0
	var rect := get_rect()
	EmberDraw.panel(self, rect, _highlighted or _hovered, Palette.COLOR_WIDGET_DEAD if dead else Palette.COLOR_PANEL)
	if _hovered:
		EmberDraw.rounded_rect(self, rect.grow(2), Color.TRANSPARENT, Palette.COLOR_TARGET_AVAILABLE, 2, 5)
	var y := (_height - _content_height()) * 0.5
	EmberDraw.medallion(self, Vector2(WIDTH / 2.0, y + PORTRAIT_R), PORTRAIT_R,
			MageColors.color_for(_mage.name), _highlighted, dead)
	y += PORTRAIT_R * 2.0 + 18.0
	EmberDraw.text_centered(self, WIDTH / 2.0, y, _mage.name, 15, Palette.COLOR_TEXT_BRIGHT, true)
	y = _draw_hp(y + 8.0)
	y = _draw_mana(y)
	_draw_statuses(y)


func _content_height() -> float:
	var h := PORTRAIT_R * 2.0 + 18.0 + 8.0 + BAR_HEIGHT + 16.0
	if _mana_max > 0:
		h += 14.0
	if _incoming_attack > 0:
		h += 16.0
	return h + _statuses.size() * 20.0


func _draw_hp(y: float) -> float:
	var losses: Array[int] = []
	var colors: Array[Color] = []
	for status: StatusData in _statuses:
		if status.get_turn_damage() > 0:
			losses.append(status.get_turn_damage())
			colors.append(status.display_color)
	EmberDraw.hp_bar(self, Rect2(PAD, y, WIDTH - PAD * 2.0, BAR_HEIGHT), _mage.current_hp, _mage.max_hp,
			_incoming_attack, losses, colors, _shield)
	var label := "%d/%d" % [_mage.current_hp, _mage.max_hp] + (" +%d" % _shield if _shield > 0 else "")
	EmberDraw.text_centered(self, WIDTH / 2.0, y + BAR_HEIGHT + 14.0, label, 12, Palette.COLOR_TEXT_DIM)
	return y + BAR_HEIGHT + 16.0


## Mana this mage has put into the wand this turn, as pips (filled = used).
func _draw_mana(y: float) -> float:
	if _mana_max > 0:
		var gap := minf(12.0, (WIDTH - PAD * 2.0) / float(_mana_max))
		var x0 := WIDTH / 2.0 - gap * (_mana_max - 1) / 2.0
		EmberDraw.mana_pips(self, Vector2(x0, y + 6.0), _mana_committed, _mana_max, minf(4.0, gap * 0.38), gap)
		y += 14.0
	if _incoming_attack > 0:
		EmberDraw.text_centered(self, WIDTH / 2.0, y + 13.0, "⚔ −%d" % _incoming_attack, 13, Palette.COLOR_HP_LOW, true)
		y += 16.0
	return y


func _draw_statuses(y: float) -> void:
	for status: StatusData in _statuses:
		TokenDraw.chip(self, Vector2(WIDTH / 2.0, y + 10.0), "%s %s" % [status.icon, status.get_label()],
				status.display_color, TokenDraw.CHIP_BG, 10)
		y += 20.0
