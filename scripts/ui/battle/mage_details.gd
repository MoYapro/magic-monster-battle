class_name MageDetails
extends FramedPanel
## Details panel of one mage: portrait, HP with what is coming, attributes, afflictions and the
## monsters aiming at them. Opened by clicking a mage card while no wand is aiming.

const PANEL_RECT := Rect2(640, 44, 610, 620)


func setup(mage: MageData, ms: MageState, incoming: int, threats: Array[Dictionary], battles_won: int,
		on_close: Callable) -> void:
	position = PANEL_RECT.position
	custom_minimum_size = PANEL_RECT.size
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(_header(mage, ms, incoming, battles_won, on_close))
	v.add_child(DetailRows.section("Attributes"))
	v.add_child(_attributes(mage, ms))
	_add_afflictions(v, ms)
	_add_threats(v, threats)


func _header(mage: MageData, ms: MageState, incoming: int, battles: int, on_close: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	var badge := PortraitBadge.new()
	badge.custom_minimum_size = Vector2(120, 120)
	badge.color = MageColors.color_for(mage.name)
	badge.set_hp(ms.combatant.hp, mage.max_hp)
	h.add_child(badge)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(DetailRows.label(mage.name, 34, Palette.COLOR_TEXT_BRIGHT, true))
	info.add_child(DetailRows.label("%d battles won" % battles, 15, Palette.COLOR_ACCENT))
	info.add_child(_hp_bar(mage, ms, incoming))
	info.add_child(DetailRows.label(_hp_line(mage, ms, incoming), 14, Palette.COLOR_TEXT_DIM))
	h.add_child(info)
	var close := DetailRows.close_button(on_close)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(close)
	return h


func _hp_bar(mage: MageData, ms: MageState, incoming: int) -> HpBar:
	var bar := HpBar.new()
	bar.custom_minimum_size = Vector2(320, 10)
	for s in ms.combatant.statuses:
		if s.get_turn_damage() > 0:
			bar.status_losses.append(s.get_turn_damage())
			bar.status_colors.append(s.display_color)
	bar.set_values(ms.combatant.hp, mage.max_hp, incoming, ms.combatant.shield)
	return bar


static func _hp_line(mage: MageData, ms: MageState, incoming: int) -> String:
	var parts: Array[String] = ["%d/%d" % [ms.combatant.hp, mage.max_hp]]
	if incoming > 0:
		parts.append("−%d incoming" % incoming)
	for s in ms.combatant.statuses:
		if s.get_turn_damage() > 0:
			parts.append("−%d %s" % [s.get_turn_damage(), s.get_label().to_lower()])
	return "   ".join(parts)


func _attributes(mage: MageData, ms: MageState) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	var penalty := " (−%d from a backfire)" % mage.hp_penalty if mage.hp_penalty > 0 else ""
	grid.add_child(DetailRows.row("♥", Palette.COLOR_HP_LOW, "Max HP %d" % mage.max_hp, "Restored between battles" + penalty))
	var left := maxi(0, mage.mana_allowance - ms.mana_spent)
	grid.add_child(DetailRows.row("✦", Palette.COLOR_MANA, "Mana per turn %d" % mage.mana_allowance,
			"%d spent · %d left this turn" % [ms.mana_spent, left]))
	if mage.mana_debt > 0:
		grid.add_child(DetailRows.row("↯", Palette.COLOR_TEXT_DIM, "Mana debt %d" % mage.mana_debt, "From a fizzle"))
	if ms.combatant.shield > 0:
		grid.add_child(DetailRows.row("⛨", Palette.COLOR_SHIELD_EDGE, "Ward %d" % ms.combatant.shield, "Absorbs damage first"))
	for c in grid.get_children():
		(c as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return grid


func _add_afflictions(v: VBoxContainer, ms: MageState) -> void:
	var shown := ms.combatant.statuses.filter(func(s: StatusData) -> bool: return s.display_name != "")
	if shown.is_empty():
		return
	v.add_child(DetailRows.section("Afflictions"))
	for s: StatusData in shown:
		var dmg := s.get_turn_damage()
		var sub := "Takes %d damage at the end of the turn" % dmg if dmg > 0 else ""
		v.add_child(DetailRows.row(s.icon, s.display_color, s.get_label().capitalize(), sub))


func _add_threats(v: VBoxContainer, threats: Array[Dictionary]) -> void:
	if threats.is_empty():
		return
	v.add_child(DetailRows.section("Threats"))
	for t in threats:
		var action: MonsterActionData = t["action"]
		var dmg: int = t["damage"]
		v.add_child(DetailRows.row("⚔" if dmg > 0 else "✦", Palette.COLOR_ACCENT, "%s · %s" % [t["enemy"], action.name],
				ActionText.describe(action), str(dmg) if dmg > 0 else ""))
