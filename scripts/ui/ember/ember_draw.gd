class_name EmberDraw
extends RefCounted
## Ember Grimoire drawing primitives shared by every screen; mirrors layout-drafts/gen_drafts.py.
## Every function draws onto the given CanvasItem from inside its _draw().

const FONT: Font = preload("res://assets/fonts/eb_garamond/EBGaramond-Variable.ttf")
const GLOW_COLOR := Color("#ffb04a")
const SLOT_FILL := Color("#3b281a")
const EMPTY_FILL := Color("#1e140d")
const PORTRAIT_BG := Color("#1b120d")
const DEAD_FILL := Color("#140d09")
const DEAD_FIGURE := Color("#3a2a1e")
const WOOD := Color("#7a4f2a")
const WOOD_EDGE := Color("#3a2412")
const RUNE_CORE := Color("#fff3c8")
const ALCHEMY_SPOTS: Array[Vector2] = [Vector2(0.0, 0.27), Vector2(-0.3, -0.2), Vector2(0.3, -0.2)]

static var _bold: FontVariation
static var _glow_tex: GradientTexture2D
static var _vignette_tex: GradientTexture2D
static var _boxes: Dictionary = {}


# ---------------------------------------------------------------- fonts & text

static func bold_font() -> Font:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = FONT
		var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
		_bold.variation_opentype = {wght: 700}
	return _bold


static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, color: Color, bold := false) -> void:
	ci.draw_string(bold_font() if bold else FONT, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Draws s centred on x with its baseline at y.
static func text_centered(ci: CanvasItem, x: float, y: float, s: String, size: int, color: Color,
		bold := false) -> void:
	var f := bold_font() if bold else FONT
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(f, Vector2(x - w / 2.0, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func text_right(ci: CanvasItem, x: float, y: float, s: String, size: int, color: Color,
		bold := false) -> void:
	var f := bold_font() if bold else FONT
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	ci.draw_string(f, Vector2(x - w, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


# ---------------------------------------------------------------- boxes, panels, glow

static func box(fill: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var key := "%s|%s|%d|%d" % [fill.to_html(), border.to_html(), width, radius]
	if not _boxes.has(key):
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.border_color = border
		sb.set_border_width_all(width)
		sb.set_corner_radius_all(radius)
		sb.anti_aliasing = true
		_boxes[key] = sb
	return _boxes[key]


static func rounded_rect(ci: CanvasItem, rect: Rect2, fill: Color, border := Color.TRANSPARENT,
		width := 0, radius := 3) -> void:
	box(fill, border, width, radius).draw(ci.get_canvas_item(), rect)


## Panel with the double frame used throughout the drafts (outer border + inset inner line).
static func panel(ci: CanvasItem, rect: Rect2, selected := false, fill := Palette.COLOR_PANEL) -> void:
	var border := Palette.COLOR_ACCENT if selected else Palette.COLOR_BORDER
	rounded_rect(ci, rect, fill, border, 2 if selected else 1, 4)
	inner_frame(ci, rect)


static func inner_frame(ci: CanvasItem, rect: Rect2) -> void:
	rounded_rect(ci, rect.grow(-6), Color.TRANSPARENT, Palette.COLOR_INNER_BORDER, 1, 3)


static func glow(ci: CanvasItem, center: Vector2, radius: float, strength := 1.0,
		color := GLOW_COLOR) -> void:
	var r := Vector2(radius, radius)
	ci.draw_texture_rect(_glow_texture(), Rect2(center - r, r * 2.0), false, Color(color, 0.55 * strength))


static func _glow_texture() -> GradientTexture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color.WHITE)
		g.set_color(1, Color(1, 1, 1, 0))
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 128
		_glow_tex.height = 128
	return _glow_tex


## Darkens the edges of rect, as in the drafts' backdrop.
static func vignette(ci: CanvasItem, rect: Rect2) -> void:
	if _vignette_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.55)])
		_vignette_tex = GradientTexture2D.new()
		_vignette_tex.gradient = g
		_vignette_tex.fill = GradientTexture2D.FILL_RADIAL
		_vignette_tex.fill_from = Vector2(0.5, 0.45)
		_vignette_tex.fill_to = Vector2(1.25, 0.45)
	ci.draw_texture_rect(_vignette_tex, rect, false)


## Centred title plate: framed box with the accent title between fleurons.
static func title_plate(ci: CanvasItem, rect: Rect2, title: String) -> void:
	rounded_rect(ci, rect, Palette.COLOR_PANEL, Palette.COLOR_BORDER, 1, 3)
	rounded_rect(ci, rect.grow(-6), Color.TRANSPARENT, Palette.COLOR_INNER_BORDER, 1, 2)
	var y := rect.position.y + rect.size.y / 2.0 + 6.0
	text_centered(ci, rect.get_center().x, y, "❧  %s  ☙" % title, 18, Palette.COLOR_ACCENT)


static func staff(ci: CanvasItem, pos: Vector2, length: float) -> void:
	rounded_rect(ci, Rect2(pos, Vector2(length, 14)), WOOD, WOOD_EDGE, 1, 7)
	ci.draw_line(pos + Vector2(6, 4), pos + Vector2(length - 8, 4), Color(1, 0.85, 0.6, 0.18), 2.0)
	glow(ci, pos + Vector2(length - 6, 7), 18, 0.8)


# ---------------------------------------------------------------- bars & pips

## Boundaries (as HP values) of the loss segments drawn after the remaining HP: first the incoming
## hit, then each status loss, all clipped to the current HP. Index 0 is the HP left afterwards.
static func hp_segments(hp: int, incoming: int, status_losses: Array[int]) -> PackedInt32Array:
	var total := incoming
	for loss in status_losses:
		total += loss
	var after := maxi(0, hp - total)
	var out := PackedInt32Array([after])
	var edge := after
	for loss in [incoming] + status_losses:
		edge = mini(hp, edge + loss)
		out.append(edge)
	return out


static func hp_bar(ci: CanvasItem, rect: Rect2, hp: int, max_hp: int, incoming := 0,
		status_losses: Array[int] = [], status_colors: Array[Color] = [], shield := 0,
		fill := Palette.COLOR_HP_FULL) -> void:
	rounded_rect(ci, rect, Palette.COLOR_HP_BG, Color.TRANSPARENT, 0, 2)
	if max_hp <= 0:
		return
	var edges := hp_segments(hp, incoming, status_losses)
	var px := func(v: int) -> float: return rect.size.x * float(v) / float(max_hp)
	if edges[0] > 0:
		rounded_rect(ci, Rect2(rect.position, Vector2(px.call(edges[0]), rect.size.y)), fill)
	var colors: Array[Color] = [Palette.COLOR_HP_LOW]
	colors.append_array(status_colors)
	for i in range(1, edges.size()):
		var x0: float = px.call(edges[i - 1])
		var w: float = px.call(edges[i]) - x0
		if w > 0.0:
			ci.draw_rect(Rect2(rect.position + Vector2(x0, 0), Vector2(w, rect.size.y)), colors[mini(i - 1, colors.size() - 1)])
	if shield > 0:
		var sw: float = minf(rect.size.x, px.call(shield))
		ci.draw_rect(Rect2(rect.end.x - sw, rect.position.y, sw, rect.size.y), Color(Palette.COLOR_SHIELD_EDGE, 0.75))


static func mana_pips(ci: CanvasItem, start: Vector2, filled: int, total: int, r := 5.0, gap := 13.0) -> void:
	for i in total:
		pip(ci, start + Vector2(i * gap, 0), r, i < filled)


static func pip(ci: CanvasItem, center: Vector2, r: float, filled: bool) -> void:
	ci.draw_circle(center, r, Palette.COLOR_MANA if filled else Palette.COLOR_MANA_EMPTY)
	ci.draw_arc(center, r, 0.0, TAU, 16, Palette.COLOR_MANA, 1.0, true)


# ---------------------------------------------------------------- runes & spell sockets

static func rune(ci: CanvasItem, letters: String, center: Vector2, box_size: float, width: float,
		color: Color) -> void:
	if RuneGeometry.normalize(letters).is_empty():
		return
	var segs := RuneGeometry.fit(RuneGeometry.segments(letters), center, box_size)
	_stroke(ci, segs, Color(color, 0.12), width * 4.0)
	_stroke(ci, segs, Color(color, 0.25), width * 2.4)
	_stroke(ci, segs, color, width)
	_stroke(ci, segs, Color(RUNE_CORE, 0.9), width * 0.38)


static func _stroke(ci: CanvasItem, segs: Array[PackedVector2Array], col: Color, width: float) -> void:
	for s in segs:
		ci.draw_line(s[0], s[1], col, width, true)
		if col.a >= 0.9:  # round caps; skipped on translucent glow layers to avoid bright dots
			ci.draw_circle(s[0], width / 2.0, col)
			ci.draw_circle(s[1], width / 2.0, col)


static func alchemy_rune(ci: CanvasItem, parts: PackedStringArray, center: Vector2, r: float,
		color: Color) -> void:
	for i in mini(parts.size(), ALCHEMY_SPOTS.size()):
		rune(ci, parts[i], center + ALCHEMY_SPOTS[i] * r, r * 0.55, maxf(1.0, r * 0.045), color)


## The spell's glyph inside a socket of radius r; bolts add their direction arrow.
static func spell_rune(ci: CanvasItem, spell: SpellData, center: Vector2, r: float) -> void:
	var col := spell.element_color
	var parts := SpellRunes.alchemy(spell.spell_id)
	if not parts.is_empty():
		alchemy_rune(ci, parts, center, r, col)
		return
	rune(ci, SpellRunes.letters(spell.spell_id), center, r * 1.0, maxf(1.2, r * 0.08), col)
	if SpellRunes.is_bolt(spell.spell_id) and spell.hit_pattern.size() > 1:
		bolt_arrow(ci, center + Vector2(r * 0.62, r * 0.62), r * 0.3, Vector2(spell.hit_pattern[1]), col)


## Small arrow pointing along the bolt's direction (its second hit cell), drawn as geometry.
static func bolt_arrow(ci: CanvasItem, at: Vector2, length: float, dir: Vector2, color: Color) -> void:
	var d := dir.normalized()
	var tail := at - d * length
	var head := at + d * length
	ci.draw_circle(at, length * 1.35, EMPTY_FILL)
	ci.draw_line(tail, head, color, 1.6, true)
	ci.draw_line(head, head - d.rotated(0.6) * length * 0.8, color, 1.6, true)
	ci.draw_line(head, head - d.rotated(-0.6) * length * 0.8, color, 1.6, true)


## One look for a spell everywhere: coloured ring, rune, mana-cost pips below (filled = charged).
static func spell_socket(ci: CanvasItem, spell: SpellData, center: Vector2, r: float, charged := 0,
		tip := false, highlight := false) -> void:
	if highlight or tip:
		glow(ci, center, r + 14.0, 1.0 if highlight else 0.6)
	ci.draw_circle(center, r, Palette.COLOR_WAND_SLOT_TIP if tip else SLOT_FILL)
	ci.draw_arc(center, r, 0.0, TAU, 48, spell.element_color, 1.8, true)
	ci.draw_arc(center, r - 4.0, 0.0, TAU, 48, Palette.COLOR_WAND_BORDER_TIP if tip else Palette.COLOR_INNER_BORDER, 1.0, true)
	spell_rune(ci, spell, center, r)
	cost_pips(ci, center + Vector2(0, r + 7.0), spell.mana_cost, charged, 3.2 if r >= 18.0 else 2.6)


static func cost_pips(ci: CanvasItem, center: Vector2, cost: int, charged: int, r := 3.2) -> void:
	for i in cost:
		pip(ci, center + Vector2(-(cost - 1) * 4.5 + i * 9.0, 0), r, i < charged)


static func empty_socket(ci: CanvasItem, center: Vector2, r: float, tip := false) -> void:
	ci.draw_circle(center, r, EMPTY_FILL)
	ci.draw_arc(center, r, 0.0, TAU, 48, Palette.COLOR_WAND_BORDER_TIP if tip else Palette.COLOR_INNER_BORDER, 1.2, true)
	ci.draw_circle(center, 2.0, Palette.COLOR_INNER_BORDER)


# ---------------------------------------------------------------- portraits & seals

## Round portrait: a hooded figure silhouette in the character's colour.
static func medallion(ci: CanvasItem, center: Vector2, r: float, color: Color, selected := false,
		dead := false) -> void:
	if selected and not dead:
		glow(ci, center, r + 10.0)
	ci.draw_circle(center, r, DEAD_FILL if dead else PORTRAIT_BG)
	var ring := Palette.COLOR_INNER_BORDER if dead else (Palette.COLOR_ACCENT if selected else Palette.COLOR_BORDER)
	ci.draw_arc(center, r, 0.0, TAU, 48, ring, 2.0, true)
	var figure := DEAD_FIGURE if dead else Color(color, 0.9)
	ci.draw_circle(center + Vector2(0, -r * 0.18), r * 0.34, figure)
	ci.draw_colored_polygon(_shoulders(center, r), figure)


static func _shoulders(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 13:  # quadratic curve from left shoulder over the chest to the right shoulder
		var t := i / 12.0
		var a := c + Vector2(-r * 0.6, r * 0.7)
		var ctrl := c + Vector2(0, r * 0.05)
		var b := c + Vector2(r * 0.6, r * 0.7)
		pts.append(a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t))
	return pts


static func wax_seal(ci: CanvasItem, center: Vector2, r: float, line1: String, line2 := "",
		hovered := false, disabled := false) -> void:
	var dim := 0.45 if disabled else 1.0
	glow(ci, center, r + 12.0, (1.3 if hovered else 0.9) * dim)
	ci.draw_circle(center, r, Palette.COLOR_SEAL.darkened(0.0 if not disabled else 0.4))
	ci.draw_arc(center, r, 0.0, TAU, 48, Palette.COLOR_SEAL_LIGHT, 2.0, true)
	ci.draw_arc(center, r - 7.0, 0.0, TAU, 48, Color("#ffb08a", 0.6 * dim), 1.0, true)
	var col := Color(Palette.COLOR_SEAL_TEXT, dim)
	if line2.is_empty():
		text_centered(ci, center.x, center.y + 5.0, line1, 14, col, true)
		return
	text_centered(ci, center.x, center.y - 2.0, line1, 14, col, true)
	text_centered(ci, center.x, center.y + 13.0, line2, 11, col, true)
