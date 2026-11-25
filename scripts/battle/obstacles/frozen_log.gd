class_name FrozenLog extends ObstacleData

func _init() -> void:
	super("frozen_log", "Frozen Log", Vector2i(2, 1), Color(0.55, 0.65, 0.75), 38)
	difficulty_rating = 9
	generation_weight = 12
