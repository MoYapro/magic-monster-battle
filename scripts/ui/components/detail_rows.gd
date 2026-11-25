class_name DetailRows
extends RefCounted
## Builders for the rows of the details panels: section headings and icon/title/subtitle rows.


static func label(text: String, size: int, color: Color, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", EmberDraw.bold_font())
	return l


## "This turn ——————" heading.
static func section(title: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := label(title, 15, Palette.COLOR_TEXT_DIM)
	row.add_child(l)
	var line := HSeparator.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(line)
	return row


## Icon, title with subtitle below, optional value on the right; highlighted rows get a frame.
static func row(symbol: String, color: Color, title: String, subtitle: String, value := "",
		highlight := false) -> Control:
	var box := PanelContainer.new()
	var style := EmberDraw.box(Color(Palette.COLOR_SEAL, 0.28) if highlight else Color.TRANSPARENT,
			Palette.COLOR_ACCENT if highlight else Color.TRANSPARENT, 1, 4).duplicate()
	style.set_content_margin_all(6)
	box.add_theme_stylebox_override("panel", style)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	box.add_child(h)
	h.add_child(IconBadge.new(symbol, color))
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", -2)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_child(label(title, 17, Palette.COLOR_TEXT_BRIGHT, true))
	if subtitle != "":
		var sub := label(subtitle, 13, Palette.COLOR_TEXT_DIM)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(sub)
	h.add_child(texts)
	if value != "":
		h.add_child(label(value, 17, Palette.COLOR_HP_LOW, true))
	return box


static func close_button(on_close: Callable) -> Button:
	var b := Button.new()
	b.text = "×"
	b.flat = true
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(on_close)
	return b
