extends Control

# Debug preview of RuneIcon. Run: godot --path . res://scenes/debug/rune_preview.tscn
# Pass `-- --screenshot=<path>` to save a PNG and quit.

const SPELLS := [["F", "e0602a"], ["R", "40a6ff"], ["FRB", "e0602a"], ["IS", "6ab8f0"], ["TXN", "9a4fc0"], ["VN", "5fae4a"]]
const ALCHEMY := [["FR", "FR", "FRS", "d9d9d9"], ["FR", "EMB", "EMB", "ff4d00"], ["FP", "FRS", "FRS", "99d9ff"]]


func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 9
	grid.position = Vector2(24, 24)
	add_child(grid)
	for size in [104, 38]:
		for s in SPELLS:
			grid.add_child(_icon(size, Color(s[1]), s[0], "", "", ""))
		for a in ALCHEMY:
			grid.add_child(_icon(size, Color(a[3]), "", a[0], a[1], a[2]))
	_maybe_screenshot()


func _icon(px: int, col: Color, letters: String, cat: String, a: String, b: String) -> RuneIcon:
	var icon := RuneIcon.new()
	icon.custom_minimum_size = Vector2(px, px)
	icon.color = col
	icon.letters = letters
	icon.catalyst = cat
	icon.reactant_a = a
	icon.reactant_b = b
	return icon


func _maybe_screenshot() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(arg.trim_prefix("--screenshot="))
			get_tree().quit()
