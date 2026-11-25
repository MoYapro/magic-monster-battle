class_name MonsterDetails
extends FramedPanel
## Details panel of one monster: art, HP, what it does this turn, what else it can do, its traits
## and what it may drop. Opened by clicking a monster while no wand is aiming.

const PANEL_RECT := Rect2(90, 56, 560, 610)


func setup(enemy: EnemyData, es: EnemyState, area: String, target_name: String, on_close: Callable) -> void:
	position = PANEL_RECT.position
	custom_minimum_size = PANEL_RECT.size
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	add_child(v)
	v.add_child(_header(enemy, es, area, on_close))
	var current: int = es.intent.get("action_index", -1)
	if current >= 0 and current < enemy.action_pool.size():
		v.add_child(DetailRows.section("This turn"))
		v.add_child(_action_row(enemy.action_pool[current], target_name, true))
	_add_other_actions(v, enemy, current)
	_add_traits(v, enemy)
	_add_drops(v, enemy)


func _header(enemy: EnemyData, es: EnemyState, area: String, on_close: Callable) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	h.add_child(_portrait(enemy))
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(DetailRows.label(enemy.display_name, 34, Palette.COLOR_TEXT_BRIGHT, true))
	info.add_child(DetailRows.label(_role(enemy) + " · " + area, 15, Palette.COLOR_ACCENT))
	var bar := HpBar.new()
	bar.custom_minimum_size = Vector2(300, 10)
	bar.fill = Palette.COLOR_HP_LOW
	bar.set_values(es.combatant.hp, enemy.max_hp, 0, es.combatant.shield)
	info.add_child(bar)
	info.add_child(DetailRows.label("%d/%d   %s" % [es.combatant.hp, enemy.max_hp, _status_text(es)], 14, Palette.COLOR_TEXT_DIM))
	if enemy.description != "":
		var d := DetailRows.label("“%s”" % enemy.description, 14, Palette.COLOR_TEXT_STAT)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(d)
	h.add_child(info)
	var close := DetailRows.close_button(on_close)
	close.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(close)
	return h


## The animated monster, scaled so its footprint fits a 170 x 170 box.
func _portrait(enemy: EnemyData) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(170, 170)
	var width := minf(165.0, 165.0 * enemy.grid_size.x / float(enemy.grid_size.y))
	var m := ProceduralMonster.create(MonsterRig.art_id_for(enemy), Vector2(width, 0))
	if m != null:
		m.position = Vector2(85, 168)
		holder.add_child(m)
	return holder


func _add_other_actions(v: VBoxContainer, enemy: EnemyData, current: int) -> void:
	var others := range(enemy.action_pool.size()).filter(func(i: int) -> bool: return i != current)
	if others.is_empty():
		return
	v.add_child(DetailRows.section("Might also"))
	for i: int in others:
		v.add_child(_action_row(enemy.action_pool[i], "", false))


func _action_row(action: MonsterActionData, target: String, highlight: bool) -> Control:
	var dmg := ActionText.damage(action)
	var title := action.name + (" → " + target if target != "" else "")
	return DetailRows.row(_action_symbol(action), Palette.COLOR_ACCENT, title, ActionText.describe(action),
			str(dmg) if dmg > 0 else "", highlight)


func _add_traits(v: VBoxContainer, enemy: EnemyData) -> void:
	if enemy.traits.is_empty():
		return
	v.add_child(DetailRows.section("Nature"))
	for t in enemy.traits:
		v.add_child(DetailRows.row("✦", Palette.COLOR_TEXT_DIM, t.label, ""))


func _add_drops(v: VBoxContainer, enemy: EnemyData) -> void:
	if enemy.drop_pool.is_empty():
		return
	var h := HBoxContainer.new()
	h.alignment = BoxContainer.ALIGNMENT_END
	h.add_child(DetailRows.label("May drop:", 15, Palette.COLOR_TEXT_DIM))
	for spell in enemy.drop_pool.slice(0, 6):
		var slot := SpellSlot.new()
		slot.radius = 16.0
		slot.spell = spell
		h.add_child(slot)
	v.add_child(h)


static func _action_symbol(action: MonsterActionData) -> String:
	if ActionText.damage(action) > 0:
		return "⚔"
	if action is MonsterActionHeal:
		return "✚"
	return "✦"


static func _role(enemy: EnemyData) -> String:
	if enemy.main_role == MonsterRole.Type.NONE:
		return "Monster"
	return String(MonsterRole.Type.keys()[enemy.main_role]).capitalize()


static func _status_text(es: EnemyState) -> String:
	var parts: Array[String] = []
	for s in es.combatant.statuses:
		if s.display_name != "":
			parts.append(s.get_label().capitalize())
	return " · ".join(parts)
