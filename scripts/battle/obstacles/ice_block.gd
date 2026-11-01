class_name IceBlock extends ObstacleData

func _init() -> void:
	super("ice_block", "Ice Block", Vector2i(1, 1), Color(0.60, 0.80, 0.95), 80)
	is_blocking = true
	difficulty_rating = 13
	generation_weight = 12
