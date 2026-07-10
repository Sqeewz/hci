# level_select.gd - Level selection UI controller
extends Control

@onready var LevelContainer = $ScrollContainer/GridContainer
@onready var BackBtn = $BackButton
@onready var SoundManager = get_node("/root/SoundManager")

const THEME_SCRIPT = preload("res://ui/theme.gd")

func _ready() -> void:
	# Play menu music
	SoundManager.play_music("menu")
	
	# Apply theme styling
	var theme_inst = THEME_SCRIPT.new()
	theme_inst.apply_theme(self)
	
	BackBtn.pressed.connect(func():
		SoundManager.play_sfx("click")
		get_tree().change_scene_to_file("res://main_menu.tscn")
	)
	
	BackBtn.mouse_entered.connect(func():
		BackBtn.text = "> BACK TO MAIN MENU"
	)
	BackBtn.mouse_exited.connect(func():
		BackBtn.text = "< BACK TO MAIN MENU"
	)
	
	# Update Subtitle to show total stars
	var total_stars = LevelManager.get_total_stars()
	$Header/Subtitle.text = "TOTAL ESCAPE STAR RECORDS: " + str(total_stars) + "/66 ★ | SYSTEM SECURITY OVERRIDE ACTIVE"
	
	# Populate level nodes
	rebuild_level_select()

func rebuild_level_select() -> void:
	# Clear grid
	for child in LevelContainer.get_children():
		child.queue_free()
		
	# Create 20 levels divided into 3 environmental zones
	# 1-8: School (Yellow/Green alert theme, includes Level 6 Boss)
	# 9-15: City (Orange/Neon danger theme)
	# 16-21: Forest (Green/Red biohazard theme)
	
	for lvl in range(1, 23):
		var lvl_str = str(lvl)
		var unlocked = LevelManager.is_unlocked(lvl_str)
		var stars = LevelManager.get_stars(lvl_str)
		
		# Define environment zone details
		var zone_name = ""
		var zone_color = Color(1.0, 0.47, 0.0) # default accent
		if lvl == 8 or lvl == 15 or lvl == 22:
			zone_name = "BOSS BATTLE"
			zone_color = Color(1.0, 0.35, 0.15) # Boss orange/red
		elif lvl <= 8:
			zone_name = "SCHOOL RUINS"
			zone_color = Color(0.3, 0.65, 1.0) # Cyber blue
		elif lvl <= 15:
			zone_name = "DECAYING CITY"
			zone_color = Color(1.0, 0.5, 0.1) # Neon hazard orange
		else:
			zone_name = "DEEP FOREST"
			zone_color = Color(0.2, 0.8, 0.4) # Biohazard green
			
		# Container for the level node
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 160)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Inner Layout
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 8)
		card.add_child(vbox)
		
		# Sector header
		var zone_label = Label.new()
		zone_label.text = zone_name
		zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		zone_label.add_theme_font_size_override("font_size", 9)
		zone_label.add_theme_color_override("font_color", zone_color * 0.75)
		vbox.add_child(zone_label)
		
		# Level Number
		var lvl_label = Label.new()
		if lvl == 8:
			lvl_label.text = "BOSS: 8-PUZZLE HACK"
			lvl_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
		elif lvl == 15:
			lvl_label.text = "BOSS: PIPE MANIA"
			lvl_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
		elif lvl == 22:
			lvl_label.text = "BOSS: HANOI DECRYPT"
			lvl_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
		else:
			lvl_label.text = "LEVEL " + lvl_str
		lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(lvl_label)
		
		# Status / Stars / Lock
		if unlocked:
			# Draw vector stars
			var stars_container = HBoxContainer.new()
			stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
			stars_container.add_theme_constant_override("separation", 6)
			vbox.add_child(stars_container)
			
			for s in range(3):
				var star_icon = Label.new()
				if s < stars:
					star_icon.text = "★"
					star_icon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
				else:
					star_icon.text = "☆"
					star_icon.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3))
				star_icon.add_theme_font_size_override("font_size", 16)
				stars_container.add_child(star_icon)
				
			# Stylize unlocked card
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.08, 0.09, 0.12, 0.85)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = zone_color
			style.set_corner_radius_all(6)
			card.add_theme_stylebox_override("panel", style)
			
			# Make card interactive using custom input handler
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			
			var level_run = lvl # copy value for closure
			card.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					SoundManager.play_sfx("click")
					LevelManager.selected_level = level_run
					get_tree().change_scene_to_file("res://game_stage.tscn")
			)
			
			# Hover animations
			card.mouse_entered.connect(func():
				var hover_style = style.duplicate()
				hover_style.border_color = Color.WHITE
				hover_style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
				card.add_theme_stylebox_override("panel", hover_style)
				# Subtle scaling
				var tween = create_tween()
				tween.tween_property(card, "scale", Vector2(1.04, 1.04), 0.1)
				card.pivot_offset = card.size / 2
			)
			card.mouse_exited.connect(func():
				card.add_theme_stylebox_override("panel", style)
				var tween = create_tween()
				tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
			)
			
		else:
			# Determine specific lock reason
			var lock_msg = "[ RESTRICTED ]"
			var default_unlocked = LevelManager.progress.get("levels", {}).get(lvl_str, {}).get("unlocked", false)
			var total_stars_collected = LevelManager.get_total_stars()
			if default_unlocked:
				if lvl >= 9 and lvl <= 15 and total_stars_collected < 12:
					lock_msg = "NEED 12 ★"
				elif lvl >= 16 and total_stars_collected < 26:
					lock_msg = "NEED 26 ★"
			else:
				lock_msg = "[ LOCKED ]"
				
			# Locked Level styling
			var lock_label = Label.new()
			lock_label.text = lock_msg
			lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_label.add_theme_font_size_override("font_size", 9)
			lock_label.add_theme_color_override("font_color", Color(0.85, 0.25, 0.25))
			vbox.add_child(lock_label)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.2, 0.1, 0.1)
			style.set_corner_radius_all(6)
			card.add_theme_stylebox_override("panel", style)
			
			card.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					SoundManager.play_sfx("fail") # Play error sound
					card.pivot_offset = card.size / 2
					var tween = create_tween()
					tween.tween_property(card, "rotation", 0.08, 0.04)
					tween.chain().tween_property(card, "rotation", -0.08, 0.04)
					tween.chain().tween_property(card, "rotation", 0.04, 0.04)
					tween.chain().tween_property(card, "rotation", -0.04, 0.04)
					tween.chain().tween_property(card, "rotation", 0.0, 0.04)
			)
			
		LevelContainer.add_child(card)
