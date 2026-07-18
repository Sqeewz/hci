extends Control

@onready var SoundManager = get_node("/root/SoundManager")

var continue_sub_btn: Button
var new_game_sub_btn: Button

func _ready() -> void:
	SoundManager.play_music("menu")
	
	var play_btn = $MarginContainer/VBoxContainer/ButtonsContainer/PlayButton
	var settings_btn = $MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton
	var exit_btn = $MarginContainer/VBoxContainer/ButtonsContainer/ExitButton
	var container = $MarginContainer/VBoxContainer/ButtonsContainer
	
	# Create Continue sub-button
	continue_sub_btn = Button.new()
	continue_sub_btn.text = "   ├   CONTINUE ESCAPE"
	continue_sub_btn.visible = false
	continue_sub_btn.custom_minimum_size = Vector2(0, 36)
	
	var sub_style = StyleBoxFlat.new()
	sub_style.bg_color = Color(0.06, 0.08, 0.12, 0.8)
	sub_style.border_color = Color(0.2, 0.4, 0.6, 0.6)
	sub_style.border_width_left = 1
	sub_style.border_width_right = 1
	sub_style.border_width_top = 1
	sub_style.border_width_bottom = 1
	sub_style.set_corner_radius_all(0)
	continue_sub_btn.add_theme_stylebox_override("normal", sub_style)
	
	var sub_style_hover = StyleBoxFlat.new()
	sub_style_hover.bg_color = Color(0.12, 0.16, 0.24, 0.9)
	sub_style_hover.border_color = Color(0.3, 0.6, 0.9)
	sub_style_hover.border_width_left = 1
	sub_style_hover.border_width_right = 1
	sub_style_hover.border_width_top = 1
	sub_style_hover.border_width_bottom = 1
	sub_style_hover.set_corner_radius_all(0)
	continue_sub_btn.add_theme_stylebox_override("hover", sub_style_hover)
	continue_sub_btn.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	
	# Create New Game sub-button
	new_game_sub_btn = Button.new()
	new_game_sub_btn.text = "   └   NEW GAME"
	new_game_sub_btn.visible = false
	new_game_sub_btn.custom_minimum_size = Vector2(0, 36)
	
	var danger_sub_style = StyleBoxFlat.new()
	danger_sub_style.bg_color = Color(0.15, 0.06, 0.06, 0.8)
	danger_sub_style.border_color = Color(0.5, 0.2, 0.2, 0.6)
	danger_sub_style.border_width_left = 1
	danger_sub_style.border_width_right = 1
	danger_sub_style.border_width_top = 1
	danger_sub_style.border_width_bottom = 1
	danger_sub_style.set_corner_radius_all(0)
	new_game_sub_btn.add_theme_stylebox_override("normal", danger_sub_style)
	
	var danger_sub_style_hover = StyleBoxFlat.new()
	danger_sub_style_hover.bg_color = Color(0.24, 0.08, 0.08, 0.9)
	danger_sub_style_hover.border_color = Color(0.8, 0.3, 0.3)
	danger_sub_style_hover.border_width_left = 1
	danger_sub_style_hover.border_width_right = 1
	danger_sub_style_hover.border_width_top = 1
	danger_sub_style_hover.border_width_bottom = 1
	danger_sub_style_hover.set_corner_radius_all(0)
	new_game_sub_btn.add_theme_stylebox_override("hover", danger_sub_style_hover)
	new_game_sub_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	
	# Add to container
	container.add_child(continue_sub_btn)
	container.add_child(new_game_sub_btn)
	container.move_child(continue_sub_btn, 1)
	container.move_child(new_game_sub_btn, 2)
	
	# Connect PlayButton
	play_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_flash_and_execute(play_btn, func():
			var show_subs = not continue_sub_btn.visible
			continue_sub_btn.visible = show_subs
			new_game_sub_btn.visible = show_subs
		)
	)
	play_btn.mouse_entered.connect(func():
		play_btn.text = "> START ESCAPE (PLAY)"
	)
	play_btn.mouse_exited.connect(func():
		play_btn.text = "  START ESCAPE (PLAY)"
	)
	
	# Connect sub-buttons hover/press
	continue_sub_btn.mouse_entered.connect(func():
		continue_sub_btn.text = "   ├ > CONTINUE ESCAPE"
	)
	continue_sub_btn.mouse_exited.connect(func():
		continue_sub_btn.text = "   ├   CONTINUE ESCAPE"
	)
	continue_sub_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_flash_and_execute(continue_sub_btn, func():
			get_tree().change_scene_to_file("res://ui/level_select.tscn")
		)
	)
	
	new_game_sub_btn.mouse_entered.connect(func():
		new_game_sub_btn.text = "   └ > NEW GAME"
	)
	new_game_sub_btn.mouse_exited.connect(func():
		new_game_sub_btn.text = "   └   NEW GAME"
	)
	new_game_sub_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_flash_and_execute(new_game_sub_btn, func():
			LevelManager.reset_progress()
			LevelManager.selected_level = 1
			var game_stage_script = load("res://game_stage.gd")
			if game_stage_script:
				game_stage_script.cutscene_shown = false
				game_stage_script.boss1_in_shown = false
				game_stage_script.boss2_in_shown = false
				game_stage_script.boss3_in_shown = false
			get_tree().change_scene_to_file("res://game_stage.tscn")
		)
	)
	
	# Connect other buttons
	settings_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_flash_and_execute(settings_btn, func(): _on_settings_pressed())
	)
	settings_btn.mouse_entered.connect(func():
		settings_btn.text = "> SETTINGS"
	)
	settings_btn.mouse_exited.connect(func():
		settings_btn.text = "  SETTINGS"
	)
	
	exit_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_flash_and_execute(exit_btn, func(): _on_exit_pressed())
	)
	exit_btn.mouse_entered.connect(func():
		exit_btn.text = "> QUIT"
	)
	exit_btn.mouse_exited.connect(func():
		exit_btn.text = "  QUIT"
	)

func _flash_and_execute(btn: Button, action: Callable) -> void:
	# Disable all menu buttons
	$MarginContainer/VBoxContainer/ButtonsContainer/PlayButton.disabled = true
	$MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton.disabled = true
	$MarginContainer/VBoxContainer/ButtonsContainer/ExitButton.disabled = true
	if continue_sub_btn:
		continue_sub_btn.disabled = true
	if new_game_sub_btn:
		new_game_sub_btn.disabled = true
		
	# Flash 3 times slowly (0.24s per cycle)
	for i in range(3):
		btn.modulate.a = 0.3
		await get_tree().create_timer(0.12).timeout
		btn.modulate.a = 1.0
		await get_tree().create_timer(0.12).timeout
		
	# Re-enable menu buttons
	$MarginContainer/VBoxContainer/ButtonsContainer/PlayButton.disabled = false
	$MarginContainer/VBoxContainer/ButtonsContainer/SettingsButton.disabled = false
	$MarginContainer/VBoxContainer/ButtonsContainer/ExitButton.disabled = false
	if continue_sub_btn:
		continue_sub_btn.disabled = false
	if new_game_sub_btn:
		new_game_sub_btn.disabled = false
	
	action.call()

func _on_settings_pressed() -> void:
	SoundManager.open_settings()

func _on_exit_pressed() -> void:
	get_tree().quit()
