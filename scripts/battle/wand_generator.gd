class_name WandGenerator

# Generates a random directed graph wand where all edges point toward the tip.
#
# Strategy: build columns left-to-right. Each column's slots each connect to
# one slot in the next column. The final column is always a single tip slot.
# This guarantees the tip is the unique sink and the graph is acyclic.
#
# Column counts and row counts per column are randomised within bounds.

static func generate(rng: RandomNumberGenerator, min_cols: int = 2, max_cols: int = 3,
		min_rows: int = 1, max_rows: int = 3) -> WandData:
	var slots: Array[SpellSlotData] = []
	var col_count := rng.randi_range(min_cols, max_cols)
	# build body columns (everything left of the tip)
	var prev_ids: Array[String] = []
	for col in col_count:
		var row_count := rng.randi_range(min_rows, max_rows)
		var col_ids: Array[String] = []
		for row in row_count:
			var id := "s%d_%d" % [col, row]
			col_ids.append(id)
			# next_id assigned below once we know the next column's ids
			slots.append(SpellSlotData.new(id, col, row, ""))
		# wire previous column → this column
		_wire_columns(rng, slots, prev_ids, col_ids)
		prev_ids = col_ids

	# add tip as single final column
	var tip_row := _center_row(prev_ids, slots)
	var tip := SpellSlotData.new("tip", col_count, tip_row)
	slots.append(tip)
	_wire_columns(rng, slots, prev_ids, ["tip"])

	for slot in slots:
		slot.spell = _pick_tip_spell(rng) if slot.is_tip else _pick_body_spell(rng)

	return WandData.new(slots)


static func _pick_body_spell(rng: RandomNumberGenerator) -> SpellData:
	var spells: Array[SpellData] = [
		SpellData.new("Ember",   "Em",  ["fire"],    Color(1.00, 0.45, 0.10)),
		SpellData.new("Frost",   "Fr",  ["water"],   Color(0.25, 0.65, 1.00)),
		SpellData.new("Venom",   "Vn",  ["poison"],  Color(0.30, 0.85, 0.20)),
		SpellData.new("Amplify", "Amp", ["amplify"], Color(0.80, 0.30, 1.00)),
		SpellData.new("Shield",  "Sh",  ["shield"],  Color(0.65, 0.75, 0.90)),
	]
	return spells[rng.randi_range(0, spells.size() - 1)]


static func _pick_tip_spell(rng: RandomNumberGenerator) -> SpellData:
	var spells: Array[SpellData] = [
		SpellData.new("Single", "·",   ["tip", "single"], Color(0.90, 0.90, 0.90),
			[Vector2i(0, 0)], false),
		SpellData.new("Line",   "|||", ["tip", "line"],   Color(0.30, 0.80, 0.95),
			[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)], false),
		SpellData.new("Pierce", "→→",  ["tip", "pierce"], Color(0.95, 0.55, 0.20),
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], true),
		SpellData.new("Bomb",   "",    ["tip", "aoe"],    Color(0.25, 0.25, 0.28),
			[Vector2i(-1,-1), Vector2i(-1, 0), Vector2i(-1, 1),
			 Vector2i( 0,-1), Vector2i( 0, 0), Vector2i( 0, 1),
			 Vector2i( 1,-1), Vector2i( 1, 0), Vector2i( 1, 1)], true, "bomb"),
	]
	return spells[rng.randi_range(0, spells.size() - 1)]


# Assign each slot in prev_ids a next_id drawn from next_ids.
# Every slot in next_ids receives at least one incoming edge.
static func _wire_columns(rng: RandomNumberGenerator, slots: Array[SpellSlotData],
		prev_ids: Array[String], next_ids: Array[String]) -> void:
	if prev_ids.is_empty():
		return
	# guarantee every next slot has at least one incoming edge
	var assigned := prev_ids.duplicate()
	assigned.shuffle()
	for i in next_ids.size():
		_set_next(slots, assigned[i % assigned.size()], next_ids[i])
	# assign the remainder randomly
	for i in range(next_ids.size(), assigned.size()):
		_set_next(slots, assigned[i], next_ids[rng.randi_range(0, next_ids.size() - 1)])


static func _set_next(slots: Array[SpellSlotData], slot_id: String, next_id: String) -> void:
	for slot in slots:
		if slot.id == slot_id:
			slot.next_id = next_id
			slot.is_tip = false
			return


# Pick a grid row for the tip that sits near the vertical centre of the last column.
static func _center_row(prev_ids: Array[String], slots: Array[SpellSlotData]) -> int:
	if prev_ids.is_empty():
		return 0
	var total_row := 0
	var count := 0
	for slot in slots:
		if slot.id in prev_ids:
			total_row += slot.grid_row
			count += 1
	return roundi(float(total_row) / float(count))
