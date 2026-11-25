class_name TokenDraw
extends RefCounted
## Drawing of battlefield tokens (monsters and obstacles) on top of the ground tiles.

const INTENT_BG := Color("#3a200e")
const INTENT_FG := Color("#ffcf6a")
const CHIP_BG := Color("#140c08", 0.9)
const SHADE := Color(0.0, 0.0, 0.0, 0.35)


## Card frame in the monster's colour; the ground shows through. Hovered cards glow gold.
static func card(ci: CanvasItem, rect: Rect2, color: Color, hovered: bool, targetable: bool) -> void:
	var inner := rect.grow(-3)
	var border := Palette.COLOR_TARGET_AVAILABLE if (hovered or targetable) else color.lightened(0.15)
	EmberDraw.rounded_rect(ci, inner, Color(0, 0, 0, 0.12), border, 3 if hovered else 2, 4)


static func art(ci: CanvasItem, rect: Rect2, tex: Texture2D) -> void:
	ci.draw_texture_rect(tex, rect.grow(-4), false)


static func placeholder(ci: CanvasItem, rect: Rect2, enemy: EnemyData) -> void:
	EmberDraw.rounded_rect(ci, rect.grow(-4), Color(enemy.color, 0.55), Color.TRANSPARENT, 0, 3)
	EmberDraw.text_centered(ci, rect.get_center().x, rect.get_center().y, enemy.display_name, 12, Palette.COLOR_TEXT_BRIGHT, true)


static func hp_bar(ci: CanvasItem, rect: Rect2, hp: int, max_hp: int) -> void:
	var bar := Rect2(rect.position.x + 9, rect.end.y - 13, rect.size.x - 18, 5)
	EmberDraw.rounded_rect(ci, bar.grow(1), Palette.COLOR_HP_BG, Color.TRANSPARENT, 0, 2)
	var frac := clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)
	if frac > 0.0:
		EmberDraw.rounded_rect(ci, Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Palette.COLOR_HP_LOW, Color.TRANSPARENT, 0, 2)


## Small pill with text, centred on `center`.
static func chip(ci: CanvasItem, center: Vector2, label: String, fg: Color, bg := CHIP_BG,
		size := 11) -> void:
	var w := EmberDraw.FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 12.0
	var r := Rect2(center - Vector2(w / 2.0, 9), Vector2(w, 18))
	EmberDraw.rounded_rect(ci, r, bg, fg, 1, 9)
	EmberDraw.text_centered(ci, center.x, center.y + size * 0.36, label, size, fg)


static func intent_chip(ci: CanvasItem, rect: Rect2, label: String) -> void:
	chip(ci, Vector2(rect.get_center().x, rect.position.y + 4), label, INTENT_FG, INTENT_BG, 12)


## Status chips down the left edge (icon + stacks) and defence chips down the right edge.
static func side_chips(ci: CanvasItem, rect: Rect2, left: Array, right: Array) -> void:
	for i in left.size():
		chip(ci, Vector2(rect.position.x + 20, rect.position.y + 24 + i * 20), left[i][0], left[i][1])
	for i in right.size():
		chip(ci, Vector2(rect.end.x - 20, rect.position.y + 24 + i * 20), right[i][0], right[i][1])


static func obstacle(ci: CanvasItem, rect: Rect2, obs: ObstacleData, hp: int, tex: Texture2D) -> void:
	var inner := rect.grow(-3)
	if tex != null:
		ci.draw_texture_rect(tex, inner, false)
	else:
		EmberDraw.rounded_rect(ci, inner, Color(obs.color.darkened(0.2), 0.7), Color.TRANSPARENT, 0, 4)
	EmberDraw.rounded_rect(ci, inner, Color.TRANSPARENT, obs.color.darkened(0.45), 2, 4)
	ci.draw_rect(Rect2(inner.position.x, inner.end.y - 22, inner.size.x, 22), SHADE)
	EmberDraw.text_centered(ci, inner.get_center().x, inner.end.y - 9, "%s  %d" % [obs.display_name, hp], 11, Palette.COLOR_TEXT_BRIGHT)
