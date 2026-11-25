extends GutTest


func _seg(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a, b])


# --- normalize ---

func test_normalize_uppercases_and_drops_spaces() -> void:
	assert_eq(RuneGeometry.normalize("f r b"), PackedStringArray(["F", "R", "B"]))


func test_normalize_drops_characters_without_rune() -> void:
	assert_eq(RuneGeometry.normalize("A?!"), PackedStringArray(["A"]))


func test_normalize_accepts_digits() -> void:
	assert_eq(RuneGeometry.normalize("7"), PackedStringArray(["7"]))


# --- stem ---

func test_stem_x_finds_long_vertical_stroke() -> void:
	assert_almost_eq(RuneGeometry.stem_x(RuneAlphabet.glyph("R")), 0.2, 0.001)


func test_stem_x_is_nan_without_vertical_stroke() -> void:
	assert_true(is_nan(RuneGeometry.stem_x(RuneAlphabet.glyph("V"))))


func test_overlay_aligns_stems_on_centre_line() -> void:
	var lines := RuneGeometry.overlay(PackedStringArray(["R"]))
	assert_almost_eq(lines[0][0].x, 0.5, 0.001)


# --- merging ---

func test_similar_true_for_close_parallel_overlapping_strokes() -> void:
	assert_true(RuneGeometry.similar(_seg(Vector2(0, 0), Vector2(1, 0)), _seg(Vector2(0.2, 0.05), Vector2(0.8, 0.05))))


func test_similar_false_for_distant_parallel_strokes() -> void:
	assert_false(RuneGeometry.similar(_seg(Vector2(0, 0), Vector2(1, 0)), _seg(Vector2(0, 0.5), Vector2(1, 0.5))))


func test_similar_false_for_crossing_strokes() -> void:
	assert_false(RuneGeometry.similar(_seg(Vector2(0, 0), Vector2(1, 1)), _seg(Vector2(0, 1), Vector2(1, 0))))


func test_merge_group_spans_all_members() -> void:
	var merged := RuneGeometry.merge_group([_seg(Vector2(0, 0), Vector2(0.6, 0)), _seg(Vector2(0.4, 0), Vector2(1, 0))])
	assert_almost_eq(merged[0].distance_to(merged[1]), 1.0, 0.001)


func test_snap_ends_joins_nearly_touching_endpoints() -> void:
	var snapped := RuneGeometry.snap_ends([_seg(Vector2(0, 0), Vector2(1, 0)), _seg(Vector2(1.02, 0), Vector2(1, 1))])
	assert_eq(snapped[0][1], snapped[1][0])


# --- whole runes ---

func test_single_letter_keeps_its_stroke_count() -> void:
	assert_eq(RuneGeometry.segments("O").size(), 4)


func test_duplicate_letters_collapse_to_one_rune() -> void:
	assert_eq(RuneGeometry.segments("RR").size(), RuneGeometry.segments("R").size())


func test_shared_stem_is_drawn_once() -> void:
	var stems := RuneGeometry.segments("RS").filter(
		func(s: PackedVector2Array) -> bool: return absf(s[0].x - s[1].x) < 0.01)
	assert_eq(stems.size(), 1)


func test_unknown_letters_yield_no_segments() -> void:
	assert_eq(RuneGeometry.segments("?").size(), 0)


func test_fit_scales_into_box_around_centre() -> void:
	var fitted := RuneGeometry.fit([_seg(Vector2(0, 0), Vector2(1, 0.5))], Vector2(10, 10), 20.0)
	assert_eq(fitted[0][0], Vector2(0, 5))
	assert_eq(fitted[0][1], Vector2(20, 15))
