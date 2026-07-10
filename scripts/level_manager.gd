# level_manager.gd - Manages level unlocks and star ratings
extends Node

# Path to progress JSON (stored in user_data folder)
const PROGRESS_PATH = "user://progress.json"

var progress = {}
var selected_level: int = 1

func _ready() -> void:
	load_progress()

func load_progress() -> void:
	if FileAccess.file_exists(PROGRESS_PATH):
		var file = FileAccess.open(PROGRESS_PATH, FileAccess.READ)
		if file:
			var data = file.get_as_text()
			file.close()
			var json_data = JSON.parse_string(data)
			if json_data is Dictionary:
				progress = json_data
			else:
				progress = {"levels": {"1": {"unlocked": true, "stars": 0}}}
		else:
			progress = {"levels": {"1": {"unlocked": true, "stars": 0}}}
	else:
		# Initialize with first level unlocked
		progress = {"levels": {"1": {"unlocked": true, "stars": 0}}}
		save_progress()

func save_progress() -> void:
	var file = FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(progress))
		file.close()

func reset_progress() -> void:
	progress = {"levels": {"1": {"unlocked": true, "stars": 0}}}
	save_progress()

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
	if not progress.get("levels", {}).has(level_id):
		if not progress.has("levels"):
			progress["levels"] = {}
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
