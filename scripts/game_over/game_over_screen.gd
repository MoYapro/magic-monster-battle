extends Node2D

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const MAGE_GAP := 180.0


func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var seal := WaxSealButton.new()
	seal.line1 = "BEGIN"
	seal.line2 = "ANEW"
	seal.position = Vector2(SCREEN_W / 2.0 - 46.0, SCREEN_H - 112.0)
	seal.pressed.connect(_on_play_again)
	layer.add_child(seal)


func _draw() -> void:
	EmberDraw.backdrop(self)
	EmberDraw.glow(self, Vector2(SCREEN_W / 2.0, 300), 260, 0.25, Color("#6a4a2a"))
	EmberDraw.text_centered(self, SCREEN_W / 2.0, 130, "The Embers Fade", 64, Color("#c9a070"), true)
	EmberDraw.text_centered(self, SCREEN_W / 2.0, 178, "All mages have fallen.", 20, Palette.COLOR_TEXT_DIM)
	_draw_brazier(Vector2(SCREEN_W / 2.0, 300))
	_draw_fallen()
	EmberDraw.text_centered(self, SCREEN_W / 2.0, 596, _summary(), 17, Palette.COLOR_ACCENT)


## A cold brazier with a last spark and a few rising ash motes.
func _draw_brazier(c: Vector2) -> void:
	var line := Color("#6b4a2a")
	var bowl := PackedVector2Array([c + Vector2(-80, 0), c + Vector2(80, 0), c + Vector2(50, 50), c + Vector2(-50, 50)])
	draw_colored_polygon(bowl, Color("#2a1c14"))
	draw_polyline(bowl + PackedVector2Array([bowl[0]]), line, 2.0, true)
	draw_rect(Rect2(c + Vector2(-20, 50), Vector2(40, 38)), line, false, 2.0)
	EmberDraw.rounded_rect(self, Rect2(c + Vector2(-50, 88), Vector2(100, 12)), Color.TRANSPARENT, line, 2, 3)
	draw_circle(c + Vector2(-15, -2), 3.5, Palette.COLOR_MANA)
	for m in [Vector2(-30, -20), Vector2(0, -50), Vector2(25, -28), Vector2(12, -80), Vector2(-14, -105)]:
		draw_circle(c + m, 4.0 if m.y > -60 else 3.0, Color("#7a5a40", 0.45))


func _draw_fallen() -> void:
	var mages: Array = GameState.mages
	for i in mages.size():
		var x := SCREEN_W / 2.0 + (i - (mages.size() - 1) / 2.0) * MAGE_GAP
		EmberDraw.medallion(self, Vector2(x, 468), 34, MageColors.color_for(mages[i].name), false, true)
		EmberDraw.text_centered(self, x, 528, mages[i].name, 17, Palette.COLOR_TEXT_DIM, true)
		EmberDraw.text_centered(self, x, 549, "fallen", 13, Palette.COLOR_INNER_BORDER.lightened(0.2))


func _summary() -> String:
	var parts: Array[String] = ["Battles won: %d" % GameState.battle_count]
	var furthest := ""
	var most := 0
	for biome_name: String in GameState.battle_count_by_biome:
		if int(GameState.battle_count_by_biome[biome_name]) > most:
			most = GameState.battle_count_by_biome[biome_name]
			furthest = biome_name
	if furthest != "":
		parts.append("Furthest: %s, approach %d" % [furthest, most])
	return " · ".join(parts)


func _on_play_again() -> void:
	GameState.reset_to_new_game()
	get_tree().change_scene_to_file("res://scenes/loot/loot_screen.tscn")
