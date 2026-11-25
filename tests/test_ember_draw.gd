extends GutTest


func test_hp_segments_full_hp_no_loss() -> void:
	assert_eq(EmberDraw.hp_segments(30, 0, []), PackedInt32Array([30, 30]))


func test_hp_segments_incoming_hit() -> void:
	assert_eq(EmberDraw.hp_segments(22, 5, []), PackedInt32Array([17, 22]))


func test_hp_segments_incoming_then_status() -> void:
	assert_eq(EmberDraw.hp_segments(22, 5, [2]), PackedInt32Array([15, 20, 22]))


func test_hp_segments_clip_to_current_hp() -> void:
	assert_eq(EmberDraw.hp_segments(6, 9, [2]), PackedInt32Array([0, 6, 6]))
