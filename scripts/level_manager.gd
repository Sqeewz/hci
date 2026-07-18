# level_manager.gd - Manages level unlocks, star ratings, and 2-day save expiry
extends Node

const PROGRESS_PATH = "user://progress.json"
const SAVE_EXPIRE_SECONDS: float = 172800.0 # 2 days = 48 hours * 3600 seconds

var progress: Dictionary = {}
var selected_level: int = 1

func _ready() -> void:
	load_progress()

func load_progress() -> bool:
	if not FileAccess.file_exists(PROGRESS_PATH):
		reset_progress_internal()
		return false
		
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if not file:
		reset_progress_internal()
		return false
		
	var data_str = file.get_as_text()
	file.close()
	
	var json_data = JSON.parse_string(data_str)
	if not json_data is Dictionary:
		delete_save_file()
		reset_progress_internal()
		return false
		
	# Check 2-day timestamp expiry (172,800 seconds)
	var saved_time: float = float(json_data.get("timestamp", 0.0))
	var current_time: float = Time.get_unix_time_from_system()
	var time_diff: float = current_time - saved_time
	
	if saved_time <= 0.0 or time_diff > SAVE_EXPIRE_SECONDS or time_diff < 0:
		# Save data expired (> 2 days) or invalid - delete save file & reset to Level 1
		delete_save_file()
		reset_progress_internal()
		return false
		
	progress = json_data
	selected_level = int(progress.get("selected_level", 1))
	return true

func save_progress() -> void:
	progress["timestamp"] = Time.get_unix_time_from_system()
	progress["selected_level"] = selected_level
	if not progress.has("levels"):
		progress["levels"] = {"1": {"unlocked": true, "stars": 0}}
		
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(progress))
		file.close()

func has_valid_save() -> bool:
	return load_progress()

func delete_save_file() -> void:
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(PROGRESS_PATH)

func reset_progress() -> void:
	delete_save_file()
	reset_progress_internal()
	save_progress()

func reset_progress_internal() -> void:
	progress = {
		"timestamp": Time.get_unix_time_from_system(),
		"selected_level": 1,
		"levels": {"1": {"unlocked": true, "stars": 0}}
	}
	selected_level = 1

func get_total_stars() -> int:
	var total := 0
	var levels = progress.get("levels", {})
	for lvl_id in levels.keys():
		total += int(levels[lvl_id].get("stars", 0))
	return total

func is_unlocked(level_id: String) -> bool:
	var lvl = int(level_id)
	var default_unlocked = progress.get("levels", {}).get(level_id, {}).get("unlocked", false)
	if not default_unlocked:
		return false
		
	# Enforce sector requirements
	var stars = get_total_stars()
	if lvl >= 9 and lvl <= 15:
		return stars >= 12
	elif lvl >= 16:
		return stars >= 26
		
	return true

func get_stars(level_id: String) -> int:
	return int(progress.get("levels", {}).get(level_id, {}).get("stars", 0))

func unlock_level(level_id: String) -> void:
	if not progress.has("levels"):
		progress["levels"] = {}
	if not progress["levels"].has(level_id):
		progress["levels"][level_id] = {"unlocked": true, "stars": 0}
	else:
		progress["levels"][level_id]["unlocked"] = true
	save_progress()

func set_stars(level_id: String, stars: int) -> void:
	if not progress.has("levels"):
		progress["levels"] = {}
	if not progress["levels"].has(level_id):
		progress["levels"][level_id] = {"unlocked": true, "stars": stars}
	else:
		var current_stars = int(progress["levels"][level_id].get("stars", 0))
		progress["levels"][level_id]["stars"] = max(current_stars, stars)
	
	# unlock next level
	var next_id = str(int(level_id) + 1)
	if not progress["levels"].has(next_id):
		progress["levels"][next_id] = {"unlocked": true, "stars": 0}
	else:
		progress["levels"][next_id]["unlocked"] = true
	
	save_progress()

func get_all_levels() -> Dictionary:
	return progress.get("levels", {})
