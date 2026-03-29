class_name BonePile extends ObstacleData

func _init() -> void:
	super("bone_pile", "Bone Pile", Vector2i(2, 1), Color(0.85, 0.82, 0.75), 18)
	difficulty_rating = 5
	generation_weight = 12
