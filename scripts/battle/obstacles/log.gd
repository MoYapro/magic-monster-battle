class_name Log extends ObstacleData

func _init() -> void:
	super("log", "Log", Vector2i(2, 1), Color(0.45, 0.28, 0.12), 25)
	difficulty_rating = 10
	generation_weight = 12
