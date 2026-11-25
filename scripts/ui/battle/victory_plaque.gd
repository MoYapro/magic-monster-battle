class_name VictoryPlaque
extends Control
## "Victory" plaque shown when a battle is won; the wax seal claims the spoils.

signal claimed

const RECT := Rect2(340, 190, 600, 300)


func setup(area: String, turns: int, foes_slain: int, lost: Array[String]) -> void:
	position = RECT.position
	size = RECT.size
	var panel := FramedPanel.new()
	panel.selected = true
	panel.size = RECT.size
	add_child(panel)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	_add_centered(v, DetailRows.label("Victory", 54, Palette.COLOR_ACCENT, true))
	_add_centered(v, DetailRows.label("%s falls silent." % area, 19, Palette.COLOR_TEXT_BRIGHT))
	v.add_child(HSeparator.new())
	v.add_child(_stats(turns, foes_slain, lost))
	_add_seal()


func _stats(turns: int, foes: int, lost: Array[String]) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 40)
	var rows := [["Turns", str(turns), Palette.COLOR_TEXT_BRIGHT], ["Foes slain", str(foes), Palette.COLOR_TEXT_BRIGHT],
			["Lost", ", ".join(lost) if not lost.is_empty() else "no one", Palette.COLOR_HP_LOW if not lost.is_empty() else Palette.COLOR_TEXT_DIM]]
	for r in rows:
		var name_label := DetailRows.label(r[0], 17, Palette.COLOR_TEXT_DIM)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(name_label)
		grid.add_child(DetailRows.label(r[1], 17, r[2], true))
	return grid


func _add_seal() -> void:
	var seal := WaxSealButton.new()
	seal.line1 = "CLAIM"
	seal.line2 = "SPOILS"
	seal.radius = 40.0
	seal.position = Vector2(RECT.size.x / 2.0 - 52.0, RECT.size.y - 52.0)
	seal.pressed.connect(func() -> void: claimed.emit())
	add_child(seal)


static func _add_centered(v: VBoxContainer, l: Label) -> void:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
