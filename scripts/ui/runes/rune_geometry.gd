class_name RuneGeometry

# Pure geometry for spell runes: letters -> cleaned stroke segments in unit space.
# One letter yields its glyph; several letters are overlaid on a shared stem (bind-rune),
# then near-parallel, close strokes collapse into one and nearly-touching ends snap together.

const MERGE_TOLERANCE := 0.15
const MERGE_MAX_ANGLE_DEG := 22.0
const SNAP_TOLERANCE := 0.06
const STEM_MIN_LENGTH := 0.45


static func normalize(letters: String) -> PackedStringArray:
	var out := PackedStringArray()
	for c in letters.to_upper():
		if c != " " and RuneAlphabet.has_glyph(c):
			out.append(c)
	return out


static func segments(letters: String) -> Array[PackedVector2Array]:
	var segs := to_segments(overlay(normalize(letters)))
	var merged: Array[PackedVector2Array] = []
	for group in clusters(segs, _similar):
		merged.append(merge_group(group))
	return snap_ends(merged)


static func stem_x(glyph: Array[PackedVector2Array]) -> float:
	var best := NAN
	var best_len := STEM_MIN_LENGTH
	for line: PackedVector2Array in glyph:
		for i in line.size() - 1:
			var d := line[i + 1] - line[i]
			if absf(d.x) < 0.15 and absf(d.y) > best_len:
				best = (line[i].x + line[i + 1].x) / 2.0
				best_len = absf(d.y)
	return best


static func overlay(chars: PackedStringArray) -> Array[PackedVector2Array]:
	var lines: Array[PackedVector2Array] = []
	for c in chars:
		var glyph := RuneAlphabet.glyph(c)
		var sx := stem_x(glyph)
		var dx := 0.0 if is_nan(sx) else 0.5 - sx
		for line: PackedVector2Array in glyph:
			lines.append(_shift(line, dx))
	return lines


static func to_segments(lines: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var segs: Array[PackedVector2Array] = []
	for line in lines:
		for i in line.size() - 1:
			if line[i] != line[i + 1]:
				segs.append(PackedVector2Array([line[i], line[i + 1]]))
	return segs


static func similar(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	var da := (a[1] - a[0]).normalized()
	var db := (b[1] - b[0]).normalized()
	if absf(da.dot(db)) < cos(deg_to_rad(MERGE_MAX_ANGLE_DEG)):
		return false
	var n := Vector2(-da.y, da.x)
	for p in b:
		if absf((p - a[0]).dot(n)) > MERGE_TOLERANCE:
			return false
	var ta := _sorted_pair((a[0] - a[0]).dot(da), (a[1] - a[0]).dot(da))
	var tb := _sorted_pair((b[0] - a[0]).dot(da), (b[1] - a[0]).dot(da))
	return minf(ta.y, tb.y) - maxf(ta.x, tb.x) > -MERGE_TOLERANCE


static func clusters(items: Array, same: Callable) -> Array:
	var parent: Array[int] = []
	for i in items.size():
		parent.append(i)
	for i in items.size():
		for j in range(i + 1, items.size()):
			if same.call(items[i], items[j]):
				parent[_root(parent, i)] = _root(parent, j)
	var groups := {}
	for i in items.size():
		var r := _root(parent, i)
		if not groups.has(r):
			groups[r] = []
		groups[r].append(items[i])
	return groups.values()


static func merge_group(group: Array) -> PackedVector2Array:
	var base: PackedVector2Array = group[0]
	for s: PackedVector2Array in group:
		if s[0].distance_to(s[1]) > base[0].distance_to(base[1]):
			base = s
	var o := base[0]
	var d := (base[1] - base[0]).normalized()
	var n := Vector2(-d.y, d.x)
	var t_min := INF
	var t_max := -INF
	var off := 0.0
	for s: PackedVector2Array in group:
		for p in s:
			var t := (p - o).dot(d)
			t_min = minf(t_min, t)
			t_max = maxf(t_max, t)
			off += (p - o).dot(n)
	off /= group.size() * 2.0
	return PackedVector2Array([o + d * t_min + n * off, o + d * t_max + n * off])


static func snap_ends(segs: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var ends: Array = []
	for s in segs:
		ends.append_array([s[0], s[1]])
	var where := {}
	for group in clusters(ends, func(a: Vector2, b: Vector2) -> bool: return a.distance_to(b) < SNAP_TOLERANCE):
		var avg := Vector2.ZERO
		for p: Vector2 in group:
			avg += p
		for p: Vector2 in group:
			where[p] = avg / group.size()
	var out: Array[PackedVector2Array] = []
	for s in segs:
		out.append(PackedVector2Array([where[s[0]], where[s[1]]]))
	return out


static func bounds(segs: Array[PackedVector2Array]) -> Rect2:
	var r := Rect2(segs[0][0], Vector2.ZERO)
	for s in segs:
		r = r.expand(s[0]).expand(s[1])
	return r


static func fit(segs: Array[PackedVector2Array], center: Vector2, size: float) -> Array[PackedVector2Array]:
	var b := bounds(segs)
	var k := size / maxf(maxf(b.size.x, b.size.y), 0.000001)
	var out: Array[PackedVector2Array] = []
	for s in segs:
		out.append(PackedVector2Array([center + (s[0] - b.get_center()) * k, center + (s[1] - b.get_center()) * k]))
	return out


static func _similar(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	return similar(a, b)


static func _shift(line: PackedVector2Array, dx: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in line:
		out.append(p + Vector2(dx, 0.0))
	return out


static func _sorted_pair(a: float, b: float) -> Vector2:
	return Vector2(minf(a, b), maxf(a, b))


static func _root(parent: Array[int], i: int) -> int:
	while parent[i] != i:
		i = parent[i]
	return i
