class_name StatusFrozen extends StatusData


func _init() -> void:
	display_name = "FROZEN"
	display_color = Color(0.55, 0.80, 0.95)


func blocks_action() -> bool:
	return true


func on_add_status(target: StatusTarget, incoming: StatusData) -> void:
	if incoming is StatusFire:
		incoming.stacks = 0
		target.remove_status(self)
