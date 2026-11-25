extends GutTest

const ScreenFrame := preload("res://scripts/ui/screen_frame.gd")


func test_no_offset_at_design_size() -> void:
	assert_eq(ScreenFrame.centering_offset(Vector2(1280, 720)), Vector2.ZERO)


func test_wide_window_centres_horizontally() -> void:
	assert_eq(ScreenFrame.centering_offset(Vector2(1622, 720)), Vector2(171, 0))


func test_tall_window_centres_vertically() -> void:
	assert_eq(ScreenFrame.centering_offset(Vector2(1280, 900)), Vector2(0, 90))
