extends Control

# Expose properties to set in inspector or script
@export var command_name: String = "WAIT"
@export var card_color: Color = Color(0.2, 0.5, 0.8)
@export var desc_text: String = "MOVE FORWARD"

# Drag & Drop source implementation
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Create a visual preview under the mouse
	var preview = Control.new()
	var preview_panel = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(100, 140)
	
	# Match the card styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.8)
	style.border_color = card_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(8)
	preview_panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = command_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 16)
	preview_panel.add_child(label)
	
	preview.add_child(preview_panel)
	# Center the preview on cursor
	preview_panel.position = -preview_panel.custom_minimum_size / 2.0
	
	set_drag_preview(preview)
	return command_name

func _ready() -> void:
	# Set pivot center for hover scaling
	pivot_offset = size / 2.0
	
	# Setup card click action (fallback to click-to-add)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	queue_redraw()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		# Tell game stage to add this command on mouse button release (click)
		var game_stage = get_tree().current_scene
		if game_stage and game_stage.has_method("add_command"):
			game_stage.add_command(command_name)

func _on_mouse_entered() -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "modulate", Color(1.1, 1.1, 1.1), 0.1)

func _on_mouse_exited() -> void:
	var t = create_tween().set_parallel(true)
	t.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "modulate", Color.WHITE, 0.1)

func _draw() -> void:
	# Draw card background
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.06, 0.08, 0.12)
	bg_style.border_color = card_color
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.set_corner_radius_all(0)
	bg_style.shadow_size = 0
	
	draw_style_box(bg_style, Rect2(Vector2.ZERO, size))
	
	# Draw Title text (Header)
	var title_font = ThemeDB.fallback_font
	draw_string(title_font, Vector2(10, 22), command_name, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 15, card_color)
	
	# Draw separator line
	draw_line(Vector2(8, 28), Vector2(size.x - 8, 28), Color(card_color.r, card_color.g, card_color.b, 0.3), 1.0)
	
	# Draw vector stick-figure icons and action indicators in center
	var center = Vector2(size.x / 2.0, 68)
	var icon_color = card_color
	
	match command_name:
		"WAIT":
			# Draw stopwatch/clock timer icon (orange/amber)
			# Outer circle
			draw_arc(center, 18.0, 0, PI * 2, 32, icon_color, 2.5)
			# Stop button on top
			draw_rect(Rect2(center.x - 4, center.y - 25, 8, 4), icon_color, true)
			# Side winding knob
			draw_circle(center + Vector2(14, -14), 2.5, icon_color)
			# Hour/Minute hands replaced with prominent PAUSE symbol inside for extreme clarity
			draw_rect(Rect2(center.x - 5, center.y - 7, 3, 14), icon_color, true)
			draw_rect(Rect2(center.x + 2, center.y - 7, 3, 14), icon_color, true)
			
		"JUMP":
			# Draw ground line with spike pit gap (pit obstacle context)
			draw_line(center + Vector2(-28, 22), center + Vector2(-12, 22), icon_color, 2.0)
			draw_line(center + Vector2(12, 22), center + Vector2(28, 22), icon_color, 2.0)
			# Spikes in the pit
			draw_line(center + Vector2(-12, 22), center + Vector2(-6, 28), icon_color, 1.5)
			draw_line(center + Vector2(-6, 28), center + Vector2(0, 22), icon_color, 1.5)
			draw_line(center + Vector2(0, 22), center + Vector2(6, 28), icon_color, 1.5)
			draw_line(center + Vector2(6, 28), center + Vector2(12, 22), icon_color, 1.5)
			
			# Dotted jump trajectory arc arrow
			for t in range(6):
				var ratio = t / 5.0
				var px = -22 + ratio * 44
				var py = 18 - sin(ratio * PI) * 26
				draw_circle(center + Vector2(px, py), 1.5, icon_color)
			
			# Jumping figure at apex
			draw_circle(center + Vector2(0, -14), 4.0, icon_color)
			draw_line(center + Vector2(0, -10), center + Vector2(0, -1), icon_color, 3.0)
			draw_line(center + Vector2(0, -7), center + Vector2(-8, -15), icon_color, 2.0)
			draw_line(center + Vector2(0, -7), center + Vector2(8, -15), icon_color, 2.0)
			draw_line(center + Vector2(0, -1), center + Vector2(-6, 5), icon_color, 2.5)
			draw_line(center + Vector2(0, -1), center + Vector2(6, 5), icon_color, 2.5)
			
		"SLIDE":
			# Low ceiling line and ground line (slide context)
			draw_line(center + Vector2(-28, 22), center + Vector2(28, 22), icon_color, 2.0)
			draw_line(center + Vector2(-28, -6), center + Vector2(28, -6), icon_color, 2.0)
			
			# Sliding figure lying low
			draw_circle(center + Vector2(-12, 12), 3.5, icon_color)
			draw_line(center + Vector2(-8, 15), center + Vector2(10, 16), icon_color, 3.0)
			draw_line(center + Vector2(-2, 15), center + Vector2(12, 10), icon_color, 2.0)
			draw_line(center + Vector2(-8, 15), center + Vector2(-22, 13), icon_color, 2.5)
			
			# Forward motion arrow pointing right
			draw_line(center + Vector2(-24, 2), center + Vector2(24, 2), icon_color, 2.0)
			draw_line(center + Vector2(24, 2), center + Vector2(18, -2), icon_color, 2.0)
			draw_line(center + Vector2(24, 2), center + Vector2(18, 6), icon_color, 2.0)
			
		"DUCK":
			# Medium ceiling and ground line (crouch context)
			draw_line(center + Vector2(-28, 22), center + Vector2(28, 22), icon_color, 2.0)
			draw_line(center + Vector2(-28, -2), center + Vector2(28, -2), icon_color, 2.0)
			
			# Crouch figure
			draw_circle(center + Vector2(0, 6), 4.0, icon_color)
			draw_line(center + Vector2(0, 10), center + Vector2(-6, 17), icon_color, 3.0)
			draw_line(center + Vector2(-6, 17), center + Vector2(4, 18), icon_color, 2.5)
			draw_line(center + Vector2(4, 18), center + Vector2(-2, 22), icon_color, 2.0)
			
			# Downward arrow showing duck motion
			draw_line(center + Vector2(0, -22), center + Vector2(0, -8), icon_color, 2.0)
			draw_line(center + Vector2(0, -8), center + Vector2(-5, -13), icon_color, 2.0)
			draw_line(center + Vector2(0, -8), center + Vector2(5, -13), icon_color, 2.0)
			
		"CLIMB":
			# High concrete platform ledge (climb context)
			draw_line(center + Vector2(-28, 22), center + Vector2(2, 22), icon_color, 2.0)
			draw_line(center + Vector2(2, 22), center + Vector2(2, -6), icon_color, 2.0)
			draw_line(center + Vector2(2, -6), center + Vector2(28, -6), icon_color, 2.0)
			
			# Ladder steps on vertical face
			for r in range(4):
				var ry = 16 - r * 6
				draw_line(center + Vector2(-4, ry), center + Vector2(2, ry), Color(icon_color.r, icon_color.g, icon_color.b, 0.5), 1.5)
			
			# Climbing figure
			draw_circle(center + Vector2(-4, -4), 4.0, icon_color)
			draw_line(center + Vector2(-4, 0), center + Vector2(-6, 10), icon_color, 3.0)
			draw_line(center + Vector2(-4, -1), center + Vector2(2, -6), icon_color, 2.0)
			draw_line(center + Vector2(-6, 10), center + Vector2(-12, 16), icon_color, 2.5)
			draw_line(center + Vector2(-6, 10), center + Vector2(-2, 14), icon_color, 2.5)
			
			# Upward arrow showing climb motion
			draw_line(center + Vector2(18, 16), center + Vector2(18, -12), icon_color, 2.0)
			draw_line(center + Vector2(18, -12), center + Vector2(13, -7), icon_color, 2.0)
			draw_line(center + Vector2(18, -12), center + Vector2(23, -7), icon_color, 2.0)

	# Draw description text (Footer)
	draw_line(Vector2(8, 114), Vector2(size.x - 8, 114), Color(card_color.r, card_color.g, card_color.b, 0.2), 1.0)
	var desc_font = ThemeDB.fallback_font
	draw_string(desc_font, Vector2(10, 128), desc_text, HORIZONTAL_ALIGNMENT_CENTER, size.x - 20, 10, Color(0.65, 0.7, 0.8))
