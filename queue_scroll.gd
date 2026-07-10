extends ScrollContainer

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Only accept String command data (e.g. "RUN", "JUMP")
	return data is String

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Delegate command adding to the game stage
	var game_stage = get_tree().current_scene
	if game_stage and game_stage.has_method("add_command"):
		game_stage.add_command(data)
