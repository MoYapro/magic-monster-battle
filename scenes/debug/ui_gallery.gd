extends Control
## Shows every Ember UI component and draw primitive for visual review (not part of the game flow).

const SPELL_IDS := ["ember", "frost", "venom", "amplify", "fire_catalyst", "single", "bolt_ne", "bomb"]


func _ready() -> void:
	var panel := FramedPanel.new()
	panel.position = Vector2(40, 40)
	panel.size = Vector2(360, 200)
	add_child(panel)
	var label := Label.new()
	label.text = "Framed panel"
	label.theme_type_variation = &"HeaderLabel"
	panel.add_child(label)
	_add_slots()
	_add_badges()
	_add_bars()
	_add_buttons()


func _spells() -> Array[SpellData]:
	var by_id := {}
	for s in SpellRegistry.all_body_spells() + SpellRegistry.all_tip_spells():
		by_id[s.spell_id] = s
	var out: Array[SpellData] = []
	for id in SPELL_IDS:
		out.append(by_id[id])
	out.append(AlchemyTable._steam())
	return out


func _add_slots() -> void:
	var spells := _spells()
	for i in spells.size():
		var slot := SpellSlot.new()
		slot.radius = 22.0
		slot.spell = spells[i]
		slot.charged = i % 2
		slot.is_tip = spells[i].spell_type == "tip"
		slot.highlighted = i == 0
		slot.position = Vector2(440 + i * 64, 50)
		add_child(slot)
	var empty := SpellSlot.new()
	empty.radius = 22.0
	empty.position = Vector2(440 + spells.size() * 64, 50)
	add_child(empty)


func _add_badges() -> void:
	var data := [[Color("#d9a032"), 22, 30, ["☠2"]], [Color("#6aa0d8"), 30, 30, []], [Color("#9a6ad0"), 0, 30, []]]
	for i in data.size():
		var b := PortraitBadge.new()
		b.color = data[i][0]
		b.set_hp(data[i][1], data[i][2])
		b.statuses.assign(data[i][3])
		b.selected = i == 0
		b.position = Vector2(440 + i * 110, 160)
		b.size = Vector2(90, 90)
		add_child(b)


func _add_bars() -> void:
	var cases := [[30, 30, 0, 0], [22, 30, 5, 0], [18, 30, 5, 4], [6, 30, 9, 0]]
	for i in cases.size():
		var bar := HpBar.new()
		bar.position = Vector2(40, 300 + i * 26)
		bar.size = Vector2(240, 10)
		bar.set_values(cases[i][0], cases[i][1], cases[i][2], cases[i][3])
		if i == 3:
			bar.status_losses.assign([2])
			bar.status_colors.assign([Palette.COLOR_STATUS_POISON])
		add_child(bar)


func _add_buttons() -> void:
	var seal := WaxSealButton.new()
	seal.position = Vector2(1120, 560)
	add_child(seal)
	var claim := WaxSealButton.new()
	claim.line1 = "CLAIM"
	claim.line2 = "SPOILS"
	claim.position = Vector2(980, 560)
	add_child(claim)
	var off := WaxSealButton.new()
	off.disabled = true
	off.position = Vector2(840, 560)
	add_child(off)
	var btn := Button.new()
	btn.text = "↶ Undo"
	btn.position = Vector2(40, 440)
	add_child(btn)
	var dis := Button.new()
	dis.text = "Codex"
	dis.disabled = true
	dis.position = Vector2(160, 440)
	add_child(dis)
	var canvas := _PrimitiveCanvas.new()
	canvas.position = Vector2(40, 500)
	add_child(canvas)


class _PrimitiveCanvas:
	extends Node2D

	func _draw() -> void:
		EmberDraw.title_plate(self, Rect2(0, 0, 400, 40), "Mossy Caverns")
		EmberDraw.mana_pips(self, Vector2(10, 70), 6, 10)
		EmberDraw.staff(self, Vector2(0, 100), 420)
		EmberDraw.medallion(self, Vector2(480, 60), 28, Color("#d9a032"), true)
		EmberDraw.medallion(self, Vector2(560, 60), 28, Color("#6aa0d8"), false, true)
