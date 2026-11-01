class_name Stone extends ObstacleData

func _init() -> void:
	super("stone", "Stone", Vector2i(1, 1), Color(0.55, 0.55, 0.55), 50)
	is_blocking = true
	difficulty_rating = 8
	generation_weight = 15
