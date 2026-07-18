extends Control

const CELL_WIDTH = 95.0
const START_X = 60.0
const GROUND_Y = 250.0

# Level obstacle mapping: cell -> required action
# Cell 3: Pit (Requires JUMP)
# Cell 7: Low Debris (Requires SLIDE or DUCK)
# Cell 10: High Wall (Requires CLIMB)
const OBSTACLES = {
	3: ["JUMP", "Fell into the toxic hazard pit!"],
	7: ["SLIDE", "DUCK", "Crashed head-first into the hanging concrete beam!"],
	10: ["CLIMB", "Slammed into the pile of fallen lockers!"]
}

var program_queue: Array[String] = []
var current_cell := 0
var is_executing := false
var execution_index := -1
var current_level := 1
var max_levels := 22

static var cutscene_shown := false
static var boss1_in_shown := false
static var boss2_in_shown := false
static var boss3_in_shown := false

@export_group("Intro Cutscene Subtitles")
@export var intro_cutscene_texts: Array[String] = [
	"ระบบหลักล้มเหลว! ประตูนิรภัยของสถานีรถไฟฟ้าใต้ดินปิดตัวลงแล้ว ฉันต้องหาทางหนีก่อนระบบชัตดาวน์จะขังฉันไว้ที่นี่...",
	"เส้นทางข้างหน้าเต็มไปด้วยกับดักและหุ่นยนต์สแกนเนอร์ แต่เครื่องแฮกเกอร์แบบคิวคำสั่งสามารถเจาะระบบได้...",
	"นี่คือโอกาสเดียวของฉัน มีทั้งหมด 22 ด่านกั้นระหว่างฉันกับภายนอก... มาเข้ารหัสเพื่อหนีไปด้วยกัน!"
]

@export_group("Boss 1 Cutscene Subtitles (Level 8)")
@export var boss1_in_texts: Array[String] = [
	"ประตูนิรภัยศูนย์วิจัยโรงเรียนถูกล็อคด้วยรหัสผ่านหลัก! ต้องถอดรหัสเพื่อเปิดประตูมุ่งหน้าสู่เขตเมือง..."
]
@export var boss1_out_texts: Array[String] = [
	"การถอดรหัสสำเร็จ! ระบบความปลอดภัยของโรงเรียนถูกปลดล็อคเรียบร้อยแล้ว...",
	"เส้นทางใหม่มุ่งหน้าสู่ใจกลางเมืองผุพัง... การผจญภัยในเซกเตอร์ใหม่กำลังจะเริ่มต้นขึ้น!"
]

@export_group("Boss 2 Cutscene Subtitles (Level 15)")
@export var boss2_in_texts: Array[String] = [
	"ระบบระบายความร้อนเตาปฏิกรณ์ของเมืองผุพังกำลังล้มเหลว! ต้องเชื่อมต่อท่อน้ำกู้ระบบก่อนจะเกิดการระเบิดใน 1 นาที..."
]
@export var boss2_out_texts: Array[String] = [
	"กระแสน้ำไหลเวียนสำเร็จ! เตาปฏิกรณ์กลับสู่ภาวะปกติ และเส้นทางเข้าสู่ป่าลึกถูกเปิดออกแล้ว..."
]

@export_group("Boss 3 Cutscene Subtitles (Level 22)")
@export var boss3_in_texts: Array[String] = [
	"เข้าสู่แกนกลางเมนเฟรมสุดท้ายในป่าลึก! จัดเรียงหอคอยฮานอยเพื่อปลดล็อคประตูทางออกสุดท้าย..."
]
@export var boss3_out_texts: Array[String] = [
	"ในที่สุด ประตูทางออกสุดท้ายก็เปิดออก... แสงสว่างจากโลกภายนอกสาดส่องเข้ามาในศูนย์วิจัยที่มืดมิด...",
	"การเดินทางอันยาวนานและท้าทายผ่าน 22 ด่านได้สิ้นสุดลง คุณทำภารกิจหลบหนีสำเร็จอย่างสมบูรณ์แบบ!"
]

@export_group("End Credits")
@export_multiline var end_credits_text: String = """
[ GAME & SYSTEM DESIGN ]
HCI Project Team

[ VISUAL ART & CUTSCENES ]
Cyberpunk & Retro Pixel Assets

[ AUDIO & SOUNDTRACK ]
Faster Lo-Fi, Darksynth Cyberpunk & Tribal Escape

[ SPECIAL THANKS ]
Human Computer Interaction (HCI)

==============================
THANK YOU FOR PLAYING!
==============================
"""

var is_cutscene_active := false
var cutscene_on_click_callback: Callable
var cutscene_skip_btn: Button
var cutscene_current_slide := 0
var cutscene_is_typing := false
var cutscene_active_tween: Tween = null

# 8-Puzzle Boss Level variables (after Level 5)
var is_boss_active := false
var boss_board: Array = []
var boss_grid_container: GridContainer = null
var boss_panel: ColorRect = null
var boss_gameplay_panel: PanelContainer = null

# Tower of Hanoi Boss Level variables (after Level 15)
var hanoi_panel: ColorRect = null
var hanoi_gameplay_panel: PanelContainer = null
var hanoi_control = null

# Pipe Mania Boss Level variables (after Level 14)
var pipe_panel: ColorRect = null
var pipe_gameplay_panel: PanelContainer = null
var pipe_control = null
var pipe_time_left := 60.0
var is_pipe_boss_active := false
var pipe_timer_label: Label = null

@onready var character = $SplitScreen/GameView/Character
@onready var queue_container = $SplitScreen/DeckArea/Margin/Layout/QueueScroll/QueueContainer
@onready var run_btn = $SplitScreen/DeckArea/Margin/Layout/ControlBar/RunButton
@onready var clear_btn = $SplitScreen/DeckArea/Margin/Layout/Header/ClearButton
@onready var reset_btn = $SplitScreen/DeckArea/Margin/Layout/Header/ResetButton
@onready var back_btn = $SplitScreen/DeckArea/Margin/Layout/ControlBar/BackButton
@onready var settings_btn = $SplitScreen/DeckArea/Margin/Layout/ControlBar/SettingsButton

@onready var win_overlay = $WinOverlay
@onready var lose_overlay = $LoseOverlay
@onready var lose_reason_label = $LoseOverlay/Panel/Margin/Layout/ReasonLabel

@onready var SoundManager = get_node("/root/SoundManager")

func _ready() -> void:
	# Initialize level from selection
	current_level = LevelManager.selected_level
	
	# Start game background music loop
	SoundManager.play_music("game")
	
	# Control buttons
	run_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_run_pressed()
	)
	clear_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_clear_pressed()
	)
	reset_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_reset_pressed()
	)
	back_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_back_pressed()
	)
	settings_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		SoundManager.open_settings()
	)
	
	# Overlays
	$WinOverlay/Panel/Margin/Layout/RetryButton.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_win_action_pressed()
	)
	$WinOverlay/Panel/Margin/Layout/MenuButton.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_back_pressed()
	)
	$LoseOverlay/Panel/Margin/Layout/RetryButton.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_reset_pressed()
	)
	$LoseOverlay/Panel/Margin/Layout/MenuButton.pressed.connect(func():
		SoundManager.play_sfx("click")
		_on_back_pressed()
	)
	
	# Hook hover arrow cursor indicators
	run_btn.mouse_entered.connect(func(): run_btn.text = "> RUN SEQUENCE AUTOMATICALLY >")
	run_btn.mouse_exited.connect(func(): run_btn.text = "  RUN SEQUENCE AUTOMATICALLY >")
	
	clear_btn.mouse_entered.connect(func(): clear_btn.text = "> CLEAR TIMELINE")
	clear_btn.mouse_exited.connect(func(): clear_btn.text = "  CLEAR TIMELINE")
	
	reset_btn.mouse_entered.connect(func(): reset_btn.text = "> RESET PLAYER")
	reset_btn.mouse_exited.connect(func(): reset_btn.text = "  RESET PLAYER")
	
	back_btn.mouse_entered.connect(func(): back_btn.text = "> < BACK TO SELECTION")
	back_btn.mouse_exited.connect(func(): back_btn.text = "  < BACK TO SELECTION")
	
	settings_btn.mouse_entered.connect(func(): settings_btn.text = "> ⚙️ SETTINGS")
	settings_btn.mouse_exited.connect(func(): settings_btn.text = "  ⚙️ SETTINGS")
	
	reset_game()
func _input(event: InputEvent) -> void:
	if is_cutscene_active and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if cutscene_skip_btn and is_instance_valid(cutscene_skip_btn) and cutscene_skip_btn.visible:
			if cutscene_skip_btn.get_global_rect().has_point(event.global_position):
				return
		if cutscene_on_click_callback.is_valid():
			cutscene_on_click_callback.call()

func _process(delta: float) -> void:
	if is_pipe_boss_active:
		pipe_time_left -= delta
		if pipe_timer_label:
			pipe_timer_label.text = "TIME REMAINING: %.1fs" % max(0.0, pipe_time_left)
			if pipe_time_left <= 10.0:
				pipe_timer_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2)) # Flash red
			else:
				pipe_timer_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15))
		if pipe_time_left <= 0.0:
			handle_pipe_fail()

func add_command(command: String) -> void:
	if is_executing:
		return
	if program_queue.size() >= 12: # Limit queue size
		return
	SoundManager.play_sfx("click")
	program_queue.append(command)
	update_queue_ui()

func remove_command(index: int) -> void:
	if is_executing:
		return
	SoundManager.play_sfx("click")
	program_queue.remove_at(index)
	update_queue_ui()

func update_queue_ui(active_idx: int = -1) -> void:
	# Clear existing children
	for child in queue_container.get_children():
		child.queue_free()
		
	# Rebuild
	for i in range(program_queue.size()):
		var cmd = program_queue[i]
		
		# Create wrapper Control for safe HBoxContainer Y translation on hover
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(115, 60)
		queue_container.add_child(wrapper)
		
		# Create actual PanelContainer card
		var card := PanelContainer.new()
		card.size = Vector2(115, 60)
		card.position = Vector2.ZERO
		wrapper.add_child(card)
		
		# Set custom styles based on command card type
		var bg_color = Color(0.18, 0.22, 0.3)
		var border_color = Color(0.35, 0.4, 0.5)
		var display_text = cmd
		
		match cmd:
			"WAIT":
				bg_color = Color(0.18, 0.16, 0.12)
				border_color = Color(0.85, 0.45, 0.1)
				display_text = "⏱️ WAIT"
			"JUMP":
				bg_color = Color(0.1, 0.2, 0.35)
				border_color = Color(0.2, 0.5, 0.85)
				display_text = "🦘 JUMP"
			"SLIDE":
				bg_color = Color(0.32, 0.18, 0.08)
				border_color = Color(0.75, 0.4, 0.15)
				display_text = "🛹 SLIDE"
			"DUCK":
				bg_color = Color(0.3, 0.25, 0.08)
				border_color = Color(0.7, 0.6, 0.15)
				display_text = "⬇️ DUCK"
			"CLIMB":
				bg_color = Color(0.08, 0.26, 0.16)
				border_color = Color(0.2, 0.6, 0.35)
				display_text = "🧗 CLIMB"
		
		# Set card stylebox (sharp retro corners)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(0)
		style.content_margin_left = 12
		style.content_margin_right = 8
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		
		if i == active_idx:
			style.bg_color = Color(0.08, 0.3, 0.18) # active running green
			style.border_color = Color(0.3, 1.0, 0.6) # bright green neon
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.shadow_color = Color(0.3, 1.0, 0.6, 0.35)
			style.shadow_size = 12
			
			# Loop tween to pulse active executing card's glow
			var pulse_t = card.create_tween().set_loops()
			pulse_t.tween_property(style, "shadow_size", 4, 0.4).set_trans(Tween.TRANS_SINE)
			pulse_t.parallel().tween_property(style, "border_color", Color(0.15, 0.6, 0.35), 0.4).set_trans(Tween.TRANS_SINE)
			pulse_t.tween_property(style, "shadow_size", 12, 0.4).set_trans(Tween.TRANS_SINE)
			pulse_t.parallel().tween_property(style, "border_color", Color(0.3, 1.0, 0.6), 0.4).set_trans(Tween.TRANS_SINE)
		else:
			style.bg_color = bg_color
			style.border_color = border_color
			style.border_width_left = 1.5
			style.border_width_right = 1.5
			style.border_width_top = 1.5
			style.border_width_bottom = 1.5
			
		card.add_theme_stylebox_override("panel", style)
		
		# Hover animations for popup Y-translation effect
		card.mouse_entered.connect(func():
			var t = card.create_tween()
			t.tween_property(card, "position:y", -8.0, 0.12).set_trans(Tween.TRANS_SINE)
		)
		card.mouse_exited.connect(func():
			var t = card.create_tween()
			t.tween_property(card, "position:y", 0.0, 0.12).set_trans(Tween.TRANS_SINE)
		)
		
		# HBox layout
		var hbox := HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Command Label
		var label := Label.new()
		label.text = display_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(label)
		
		# Close button (only when not running)
		if not is_executing:
			var close_btn := Button.new()
			close_btn.text = "x"
			close_btn.flat = true
			close_btn.add_theme_color_override("font_color", Color(0.85, 0.4, 0.4))
			close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.5, 0.5))
			close_btn.pressed.connect(func(): remove_command(i))
			hbox.add_child(close_btn)
			
		card.add_child(hbox)
		
	# Update timeline title with live star rating feedback
	var min_commands = get_level_stages(current_level).size()
	var actual_commands = program_queue.size()
	var stars_est = 3
	var feedback_color = Color(0.3, 0.95, 0.5) # Green (3 stars)
	if actual_commands <= min_commands:
		stars_est = 3
		feedback_color = Color(0.3, 0.95, 0.5)
	elif actual_commands <= min_commands + 1:
		stars_est = 2
		feedback_color = Color(0.95, 0.8, 0.15) # Yellow (2 stars)
	else:
		stars_est = 1
		feedback_color = Color(0.95, 0.3, 0.3) # Red (1 star)
		
	var star_str = ""
	for s in range(3):
		if s < stars_est:
			star_str += "★"
		else:
			star_str += "☆"
			
	var title_node = $SplitScreen/DeckArea/Margin/Layout/Header/Title
	if title_node:
		title_node.text = "LEVEL %d: SEQUENCE BUDGET (%d/%d CARDS | %s)" % [current_level, actual_commands, min_commands, star_str]
		title_node.add_theme_color_override("font_color", feedback_color)

func reset_game() -> void:
	is_executing = false
	current_cell = 0
	execution_index = -1
	
	# Update active obstacles for LevelGraphics based on current level
	$SplitScreen/GameView/LevelGraphics.active_obstacles = get_level_obstacles(current_level)
	$SplitScreen/GameView/LevelGraphics.current_level = current_level
	$SplitScreen/GameView/LevelGraphics.queue_redraw()
	
	# Update level title text
	$SplitScreen/DeckArea/Margin/Layout/Header/Title.text = "LEVEL " + str(current_level) + ": ESCAPE SEQUENCE"
	
	character.global_position = Vector2(START_X, GROUND_Y)
	character.reset_pose()
	
	win_overlay.hide()
	lose_overlay.hide()
	
	update_queue_ui()
	set_deck_disabled(false)
	
	if current_level == 8 and not boss1_in_shown:
		boss1_in_shown = true
		set_deck_disabled(true)
		call_deferred("show_boss1_in_cutscene")
	elif current_level == 8:
		set_deck_disabled(true)
		call_deferred("show_boss_level")
	elif current_level == 15 and not boss2_in_shown:
		boss2_in_shown = true
		set_deck_disabled(true)
		call_deferred("show_boss2_in_cutscene")
	elif current_level == 15:
		set_deck_disabled(true)
		call_deferred("show_pipe_boss_level")
	elif current_level == 22 and not boss3_in_shown:
		boss3_in_shown = true
		set_deck_disabled(true)
		call_deferred("show_boss3_in_cutscene")
	elif current_level == 22:
		set_deck_disabled(true)
		call_deferred("show_hanoi_boss_level")
	elif current_level == 1 and not cutscene_shown:
		cutscene_shown = true
		set_deck_disabled(true)
		call_deferred("show_intro_cutscene")


func show_cutscene_dialogue(slides_data: Array, on_complete: Callable = Callable()) -> void:
	if slides_data.is_empty():
		if on_complete.is_valid():
			on_complete.call()
		return

	# Hide split screen temporarily so runner view doesn't peek through
	$SplitScreen.hide()
	
	var cutscene_layer = CanvasLayer.new()
	cutscene_layer.name = "CutsceneLayer"
	add_child(cutscene_layer)
	
	# Backdrop - receives full screen click inputs
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.05, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	cutscene_layer.add_child(bg)
	
	# TextureRect for comic slide
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.anchor_right = 1.0
	texture_rect.anchor_bottom = 1.0
	texture_rect.offset_right = 0
	texture_rect.offset_bottom = 0
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(texture_rect)
	
	# Dialogue box container
	var dialogue_panel = PanelContainer.new()
	dialogue_panel.custom_minimum_size = Vector2(800, 135)
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = -400
	dialogue_panel.offset_right = 400
	dialogue_panel.offset_top = -170
	dialogue_panel.offset_bottom = -30
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(dialogue_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Dialogue text label
	var label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)
	
	# Retro hint label
	var hint = Label.new()
	hint.text = "[ CLICK ANYWHERE ON SCREEN TO CONTINUE ]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", Color(0.4, 0.6, 0.8, 0.6))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(hint)
	
	var box_style = StyleBoxFlat.new()
	box_style.bg_color = Color(0.06, 0.07, 0.1, 0.9)
	box_style.border_width_left = 3
	box_style.border_width_right = 3
	box_style.border_width_top = 3
	box_style.border_width_bottom = 3
	box_style.border_color = Color(0.2, 0.5, 0.8)
	box_style.set_corner_radius_all(0)
	dialogue_panel.add_theme_stylebox_override("panel", box_style)
	
	# Skip Button (top-right)
	var skip_btn = Button.new()
	cutscene_skip_btn = skip_btn
	skip_btn.text = "  SKIP CINEMATIC >  "
	skip_btn.custom_minimum_size = Vector2(160, 36)
	skip_btn.position = Vector2(1280 - 180, 20)
	skip_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color(0.12, 0.15, 0.2, 0.5)
	skip_style.border_color = Color(0.4, 0.45, 0.5, 0.5)
	skip_style.border_width_left = 1
	skip_style.border_width_right = 1
	skip_style.border_width_top = 1
	skip_style.border_width_bottom = 1
	skip_style.set_corner_radius_all(0)
	skip_btn.add_theme_stylebox_override("normal", skip_style)
	
	var skip_style_hover = StyleBoxFlat.new()
	skip_style_hover.bg_color = Color(0.18, 0.22, 0.3, 0.8)
	skip_style_hover.border_color = Color(0.5, 0.7, 0.9)
	skip_style_hover.border_width_left = 1
	skip_style_hover.border_width_right = 1
	skip_style_hover.border_width_top = 1
	skip_style_hover.border_width_bottom = 1
	skip_style_hover.set_corner_radius_all(0)
	skip_btn.add_theme_stylebox_override("hover", skip_style_hover)
	bg.add_child(skip_btn)
	
	cutscene_current_slide = 0
	cutscene_is_typing = false
	cutscene_active_tween = null
	
	# Helper to show a slide
	var show_slide = func(idx: int):
		if idx >= slides_data.size():
			return
		
		var slide = slides_data[idx]
		var img_path: String = slide.get("img", "")
		
		# 1. Slide fade-in / image display
		if img_path != "" and ResourceLoader.exists(img_path):
			texture_rect.show()
			texture_rect.texture = load(img_path)
			texture_rect.modulate.a = 0.0
			var fade_in = create_tween()
			fade_in.tween_property(texture_rect, "modulate:a", 1.0, 0.3)
		else:
			texture_rect.hide()
			bg.color = Color(0.02, 0.02, 0.03, 1.0) # Dark screen for narration epilogues
		
		# 2. Typewriter subtitle effect
		label.text = slide.get("text", "")
		label.visible_ratio = 0.0
		cutscene_is_typing = true
		
		if cutscene_active_tween:
			cutscene_active_tween.kill()
		cutscene_active_tween = create_tween()
		var duration = float(label.text.length()) * 0.025
		cutscene_active_tween.tween_property(label, "visible_ratio", 1.0, duration)
		cutscene_active_tween.finished.connect(func():
			cutscene_is_typing = false
		)
		
		# Optional screen shake
		if slide.get("shake", false):
			SoundManager.play_sfx("fail")
			var shake_tween = create_tween()
			var amp := 20.0
			var step := 0.04
			for i in range(12):
				var offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
				shake_tween.tween_property(bg, "position", offset, step)
			shake_tween.tween_property(bg, "position", Vector2.ZERO, step)
			
	# Init slide 0
	show_slide.call(0)
	
	# Close helper
	var close_cutscene = func():
		is_cutscene_active = false
		cutscene_layer.queue_free()
		$SplitScreen.show()
		set_deck_disabled(false)
		if on_complete.is_valid():
			on_complete.call()
		
	# Define advance callback
	var advance_cutscene = func():
		if cutscene_is_typing:
			# Complete typewriter text instantly
			if cutscene_active_tween:
				cutscene_active_tween.kill()
			label.visible_ratio = 1.0
			cutscene_is_typing = false
		else:
			# Proceed to next slide
			SoundManager.play_sfx("click")
			cutscene_current_slide += 1
			if cutscene_current_slide < slides_data.size():
				show_slide.call(cutscene_current_slide)
			else:
				close_cutscene.call()
				
	# Enable cutscene active flag and callback
	is_cutscene_active = true
	cutscene_on_click_callback = advance_cutscene
	
	skip_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		close_cutscene.call()
	)

func show_intro_cutscene() -> void:
	var slides = []
	for i in range(min(3, intro_cutscene_texts.size())):
		var img_path = "res://assets/cuts/cut%d.png" % (i + 1)
		slides.append({
			"img": img_path,
			"text": intro_cutscene_texts[i],
			"shake": (i == 1)
		})
	show_cutscene_dialogue(slides)

func show_boss1_in_cutscene() -> void:
	var slides = []
	for txt in boss1_in_texts:
		slides.append({"img": "res://assets/cuts/cutBoss1in.png", "text": txt})
	show_cutscene_dialogue(slides, func(): show_boss_level())

func show_boss2_in_cutscene() -> void:
	var slides = []
	for txt in boss2_in_texts:
		slides.append({"img": "res://assets/cuts/cutBoss2.png", "text": txt})
	show_cutscene_dialogue(slides, func(): show_pipe_boss_level())

func show_boss3_in_cutscene() -> void:
	var slides = []
	for txt in boss3_in_texts:
		slides.append({"img": "res://assets/cuts/cutBoss3.png", "text": txt})
	show_cutscene_dialogue(slides, func(): show_hanoi_boss_level())

func show_end_credits() -> void:
	# Hide split screen
	$SplitScreen.hide()
	
	var credits_layer = CanvasLayer.new()
	credits_layer.name = "CreditsLayer"
	add_child(credits_layer)
	
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	credits_layer.add_child(bg)
	
	var center = CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.offset_right = 0
	center.offset_bottom = 0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "🏆 ESCAPE COMPLETE 🏆\n--- END CREDITS ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	vbox.add_child(title)
	
	var credits_lbl = Label.new()
	credits_lbl.text = end_credits_text
	credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_lbl.add_theme_font_size_override("font_size", 12)
	credits_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vbox.add_child(credits_lbl)
	
	var hint = Label.new()
	hint.text = "[ CLICK ANYWHERE TO RETURN TO MAIN MENU ]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0, 0.7))
	vbox.add_child(hint)
	
	# Slow blinking hint effect
	var blink = create_tween().set_loops()
	blink.tween_property(hint, "modulate:a", 0.2, 0.8)
	blink.tween_property(hint, "modulate:a", 1.0, 0.8)
	
	SoundManager.play_sfx("win")
	
	# Return to main menu callback
	var is_closing := false
	var return_to_menu = func():
		if is_closing:
			return
		is_closing = true
		SoundManager.play_sfx("click")
		is_cutscene_active = false
		cutscene_on_click_callback = Callable()
		get_tree().change_scene_to_file("res://main_menu.tscn")
		
	is_cutscene_active = true
	cutscene_on_click_callback = return_to_menu
	cutscene_skip_btn = null

func set_deck_disabled(disable: bool) -> void:
	run_btn.disabled = disable
	clear_btn.disabled = disable
	settings_btn.disabled = disable
	for card in $SplitScreen/DeckArea/Margin/Layout/Deck.get_children():
		if card is Control:
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE if disable else Control.MOUSE_FILTER_PASS

func _on_run_pressed() -> void:
	if is_executing:
		return
		
	is_executing = true
	set_deck_disabled(true)
	current_cell = 0
	execution_index = -1
	update_queue_ui()
	
	# Fetch stages dynamically based on current level
	var stages = get_level_stages(current_level)
	
	for stage_idx in range(stages.size()):
		if not is_executing:
			return
			
		var stage = stages[stage_idx]
		
		# 1. Run automatically to the obstacle
		var run_tween = character.play_action("RUN", Vector2(stage.run_to_x, GROUND_Y), stage.run_duration)
		await run_tween.finished
		
		if not is_executing:
			return
			
		# 2. Check the command card
		var card_idx = stage.card_idx
		var card_cmd = ""
		if card_idx < program_queue.size():
			card_cmd = program_queue[card_idx]
			execution_index = card_idx
			update_queue_ui(card_idx)
		else:
			execution_index = -1
			update_queue_ui()
			
		# 3. Verify action
		var is_success = false
		for sol in stage.solutions:
			if sol == card_cmd:
				is_success = true
				break
				
		if is_success:
			var target_y = stage.get("cross_to_y", GROUND_Y)
			var cross_tween = character.play_action(card_cmd, Vector2(stage.cross_to_x, target_y), stage.cross_duration)
			await cross_tween.finished
			current_cell = stage.obstacle_cell
		else:
			# Failure
			var crash_tween = character.play_action("RUN", Vector2(stage.run_to_x + 30.0, GROUND_Y), 0.35)
			await crash_tween.finished
			handle_failure(stage.obstacle_cell, stage.fail_reason)
			return
			
	# Win level!
	if is_executing:
		var gate_x = START_X + 11 * CELL_WIDTH
		if current_level >= 8 and current_level <= 14: # City levels (Decaying City)
			gate_x = 1250.0
			
		if character.global_position.x < gate_x:
			var remaining_dist = gate_x - character.global_position.x
			var run_time = max(0.2, (remaining_dist / CELL_WIDTH) * 0.16)
			var final_run_tween = character.play_action("RUN", Vector2(gate_x, character.global_position.y), run_time)
			await final_run_tween.finished
			
		if is_executing:
			current_cell = 11
			handle_win()

func make_stage(card_idx: int, cur_cell: int, obs_cell: int, solutions: Array, fail_reason: String, target_y: float = GROUND_Y) -> Dictionary:
	var run_cells = obs_cell - 1 - cur_cell
	var run_to_x = START_X + (obs_cell - 1) * CELL_WIDTH
	var cross_to_x = START_X + (obs_cell + 1) * CELL_WIDTH
	
	# If it's a climb stage, make it land on the raised platform
	var cross_to_y = target_y
	if "CLIMB" in solutions:
		cross_to_y = GROUND_Y - 80.0
		
	return {
		"run_to_x": run_to_x,
		"run_duration": max(0.2, run_cells * 0.16),
		"obstacle_cell": obs_cell,
		"card_idx": card_idx,
		"solutions": solutions,
		"fail_reason": fail_reason,
		"cross_to_x": cross_to_x,
		"cross_to_y": cross_to_y,
		"cross_duration": 0.85
	}

func get_level_obstacles(level: int) -> Dictionary:
	match level:
		1: return { 5: ["PIT"] } # tutorial jump
		2: return { 5: ["RUBBLE"] } # tutorial duck
		3: return { 5: ["STEAM"] } # tutorial slide
		4: return { 10: ["CLIMB"] } # tutorial climb
		5: return { 5: ["WAIT"] } # tutorial wait
		6: return { 5: ["DRONE"] } # tutorial drone
		7: return { 3: ["PIT"], 7: ["RUBBLE"] }
		8: return {} # Level 8 BOSS: 8-Puzzle
		9: return { 3: ["RUBBLE"], 7: ["STEAM"] }
		10: return { 3: ["STEAM"], 10: ["CLIMB"] }
		11: return { 3: ["PIT"], 10: ["CLIMB"] }
		12: return { 3: ["WAIT"], 7: ["RUBBLE"] }
		13: return { 3: ["WAIT"], 7: ["STEAM"] }
		14: return { 3: ["DRONE"], 7: ["PIT"] }
		15: return {} # Level 15 BOSS: Pipe Mania
		16: return { 3: ["DRONE"], 10: ["CLIMB"] }
		17: return { 3: ["PIT"], 6: ["RUBBLE"], 10: ["CLIMB"] }
		18: return { 3: ["STEAM"], 7: ["PIT"], 10: ["CLIMB"] }
		19: return { 3: ["WAIT"], 7: ["RUBBLE"], 10: ["CLIMB"] }
		20: return { 3: ["DRONE"], 7: ["STEAM"], 10: ["CLIMB"] }
		21: return { 2: ["WAIT"], 5: ["DRONE"], 8: ["STEAM"], 10: ["CLIMB"] } # Last Gauntlet
		22: return {} # Level 22 BOSS: Tower of Hanoi
	return {}

func get_level_stages(level: int) -> Array:
	match level:
		1: return [
			make_stage(0, 0, 5, ["JUMP"], "Fell into the toxic hazard pit! You must JUMP over it.")
		]
		2: return [
			make_stage(0, 0, 5, ["DUCK", "SLIDE"], "Hit concrete ceiling rubble! You must DUCK or SLIDE under it.")
		]
		3: return [
			make_stage(0, 0, 5, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under.")
		]
		4: return [
			make_stage(0, 0, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		5: return [
			make_stage(0, 0, 5, ["WAIT"], "Sliced by the swinging pendulum blade! You must WAIT for it to swing away.")
		]
		6: return [
			make_stage(0, 0, 5, ["DUCK", "SLIDE"], "Spotted by the ruined security sentry drone! DUCK or SLIDE to evade detection.")
		]
		7: return [
			make_stage(0, 0, 3, ["JUMP"], "Fell into the toxic hazard pit! You must JUMP over it."),
			make_stage(1, 4, 7, ["DUCK", "SLIDE"], "Hit concrete ceiling rubble! You must DUCK or SLIDE under it.")
		]
		8: return [
			make_stage(0, 0, 11, ["WAIT"], "Hack the security gate to proceed!")
		]
		9: return [
			make_stage(0, 0, 3, ["DUCK", "SLIDE"], "Hit concrete ceiling rubble! You must DUCK or SLIDE under it."),
			make_stage(1, 4, 7, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under.")
		]
		10: return [
			make_stage(0, 0, 3, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under."),
			make_stage(1, 4, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		11: return [
			make_stage(0, 0, 3, ["JUMP"], "Fell into the toxic hazard pit! You must JUMP over it."),
			make_stage(1, 4, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		12: return [
			make_stage(0, 0, 3, ["WAIT"], "Sliced by the swinging pendulum blade! You must WAIT for it to swing away."),
			make_stage(1, 4, 7, ["DUCK", "SLIDE"], "Hit concrete ceiling rubble! You must DUCK or SLIDE under it.")
		]
		13: return [
			make_stage(0, 0, 3, ["WAIT"], "Crushed by the timed hydraulic press! You must WAIT for it to lift."),
			make_stage(1, 4, 7, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under.")
		]
		14: return [
			make_stage(0, 0, 3, ["DUCK", "SLIDE"], "Spotted by the ruined security sentry drone! DUCK or SLIDE to evade detection."),
			make_stage(1, 4, 7, ["JUMP"], "Fell into the toxic hazard pit! You must JUMP over it.")
		]
		15: return [
			make_stage(0, 0, 11, ["WAIT"], "Connect the water coolant pipes to prevent meltdown!")
		]
		16: return [
			make_stage(0, 0, 3, ["DUCK", "SLIDE"], "Spotted by the ruined security sentry drone! DUCK or SLIDE to evade detection."),
			make_stage(1, 4, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		17: return [
			make_stage(0, 0, 3, ["JUMP"], "Fell into the toxic hazard pit! You must JUMP over it."),
			make_stage(1, 4, 6, ["DUCK", "SLIDE"], "Hit concrete ceiling rubble! You must DUCK or SLIDE under it."),
			make_stage(2, 7, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		18: return [
			make_stage(0, 0, 3, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under."),
			make_stage(1, 4, 7, ["JUMP"], "Fell into the toxic hazard pit! You must JUMP over it."),
			make_stage(2, 8, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		19: return [
			make_stage(0, 0, 3, ["WAIT"], "Sliced by the swinging pendulum blade! You must WAIT for it to swing away."),
			make_stage(1, 4, 7, ["DUCK", "SLIDE"], "Hit concrete ceiling rubble! You must DUCK or SLIDE under it."),
			make_stage(2, 8, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		20: return [
			make_stage(0, 0, 3, ["DUCK", "SLIDE"], "Spotted by the ruined security sentry drone! DUCK or SLIDE to evade detection."),
			make_stage(1, 4, 7, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under."),
			make_stage(2, 8, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		21: return [
			make_stage(0, 0, 2, ["WAIT"], "Sliced by the swinging pendulum blade! You must WAIT for it to swing away."),
			make_stage(1, 3, 5, ["DUCK", "SLIDE"], "Spotted by the ruined security sentry drone! DUCK or SLIDE to evade detection."),
			make_stage(2, 6, 8, ["SLIDE"], "Got scalded by a hot steam leak! You must SLIDE quickly to slip under."),
			make_stage(3, 9, 10, ["CLIMB"], "Slammed into the climbing net! You must CLIMB over it.")
		]
		22: return [
			make_stage(0, 0, 11, ["WAIT"], "Decrypt the mainframe core!")
		]
	return []

func handle_failure(cell: int, reason: String) -> void:
	is_executing = false
	SoundManager.play_sfx("fail")
	
	var active_stages = get_level_stages(current_level)
	var crash_stage = null
	for s in active_stages:
		if s.obstacle_cell == cell:
			crash_stage = s
			break
			
	var death_type = "SLAM"
	if crash_stage != null:
		if "JUMP" in crash_stage.solutions:
			death_type = "PIT"
		elif "WAIT" in crash_stage.solutions:
			death_type = "CRUSH"
			
	var fail_tween = character.play_death(death_type)
	await fail_tween.finished
	
	lose_reason_label.text = reason
	lose_overlay.show()

func calculate_stars() -> int:
	var min_commands = get_level_stages(current_level).size()
	var actual_commands = program_queue.size()
	if actual_commands <= min_commands:
		return 3
	elif actual_commands <= min_commands + 1:
		return 2
	else:
		return 1

func handle_win() -> void:
	is_executing = false
	SoundManager.play_sfx("win")
	
	var min_commands = get_level_stages(current_level).size()
	var actual_commands = program_queue.size()
	
	# Calculate star accomplishments
	var star1_ok = true
	var star2_ok = (actual_commands <= min_commands + 1)
	var star3_ok = (actual_commands <= min_commands)
	
	var stars = 1
	if star2_ok:
		stars += 1
	if star3_ok:
		stars += 1
		
	LevelManager.set_stars(str(current_level), stars)
	
	# Play cute cheering bob
	var win_tween := create_tween()
	win_tween.tween_property(character, "body_offset:y", -20.0, 0.15)
	win_tween.chain().tween_property(character, "body_offset:y", 0.0, 0.15)
	win_tween.set_loops(3)
	await win_tween.finished
	
	# Build Diagnostic Checklist Report
	var report = "DIAGNOSTIC SYSTEM REPORT:\n\n"
	report += "[✓] ESCAPE CORRIDOR: (+1 ★)\n"
	
	if star2_ok:
		report += "[✓] COMPACT QUEUE (<= %d CARDS): (+1 ★)\n" % [min_commands + 1]
	else:
		report += "[ ] COMPACT QUEUE (<= %d CARDS): (MORE OPTIMIZATION NEEDED)\n" % [min_commands + 1]
		
	if star3_ok:
		report += "[✓] OPTIMAL QUEUE (<= %d CARDS): (+1 ★)\n" % [min_commands]
	else:
		report += "[ ] OPTIMAL QUEUE (<= %d CARDS): (MORE OPTIMIZATION NEEDED)\n" % [min_commands]
		
	report += "\nTOTAL RATING: "
	for s in range(3):
		if s < stars:
			report += "★ "
		else:
			report += "☆ "
			
	var desc_node = $WinOverlay/Panel/Margin/Layout/Desc
	desc_node.text = report
	
	# Dynamically update overlay text based on level
	if current_level < max_levels:
		$WinOverlay/Panel/Margin/Layout/Title.text = "🏆 LEVEL " + str(current_level) + " COMPLETE"
		$WinOverlay/Panel/Margin/Layout/RetryButton.text = "NEXT LEVEL >"
	else:
		$WinOverlay/Panel/Margin/Layout/Title.text = "🏆 CAMPAIGN ESCAPED"
		$WinOverlay/Panel/Margin/Layout/RetryButton.text = "REPLAY CAMPAIGN"
		
	win_overlay.show()

func _on_win_action_pressed() -> void:
	if current_level < max_levels:
		current_level += 1
		LevelManager.selected_level = current_level
		program_queue.clear()
		reset_game()
	else:
		current_level = 1
		LevelManager.selected_level = current_level
		program_queue.clear()
		reset_game()

# ==============================================================================
# 8-PUZZLE BOSS LEVEL IMPLEMENTATION (AFTER LEVEL 5)
# ==============================================================================

func init_boss_puzzle() -> void:
	boss_board = [1, 2, 3, 4, 5, 6, 7, 8, 0] # 0 represents empty space
	var empty_idx = 8
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(80):
		var r = empty_idx / 3
		var c = empty_idx % 3
		var moves = []
		if r > 0: moves.append(empty_idx - 3)
		if r < 2: moves.append(empty_idx + 3)
		if c > 0: moves.append(empty_idx - 1)
		if c < 2: moves.append(empty_idx + 1)
		
		var next_idx = moves[rng.randi_range(0, moves.size() - 1)]
		boss_board[empty_idx] = boss_board[next_idx]
		boss_board[next_idx] = 0
		empty_idx = next_idx

func show_boss_level() -> void:
	is_boss_active = true
	
	# Hide the main runner split screen to show only the boss hacking screen
	$SplitScreen.hide()
	
	# Create overlay backdrop
	boss_panel = ColorRect.new()
	boss_panel.color = Color(0.03, 0.04, 0.06, 1.0)
	boss_panel.anchor_left = 0.0
	boss_panel.anchor_top = 0.0
	boss_panel.anchor_right = 1.0
	boss_panel.anchor_bottom = 1.0
	boss_panel.offset_left = 0
	boss_panel.offset_right = 0
	boss_panel.offset_top = 0
	boss_panel.offset_bottom = 0
	add_child(boss_panel)
	
	# Add background decorations for hacker mainframe theme
	add_terminal_decorations()
	
	# Show the Intro Warning screen first
	show_boss_intro_screen()

func add_terminal_decorations() -> void:
	# Top bar
	var top_bar = Panel.new()
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 0
	top_bar.offset_right = 0
	top_bar.offset_top = 0
	top_bar.offset_bottom = 30
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.06, 0.08, 0.12)
	bar_style.border_width_bottom = 2
	bar_style.border_color = Color(1.0, 0.45, 0.1, 0.3)
	top_bar.add_theme_stylebox_override("panel", bar_style)
	boss_panel.add_child(top_bar)
	
	var top_lbl = Label.new()
	top_lbl.text = " TERMINAL SHELL: SECURE BYPASS MODULE v4.7  |  PORT: 8080  |  STATUS: LINK_ESTABLISHED"
	top_lbl.add_theme_font_size_override("font_size", 9)
	top_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1, 0.6))
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.anchor_left = 0.0
	top_lbl.anchor_right = 1.0
	top_lbl.offset_left = 10
	top_lbl.offset_right = 0
	top_lbl.offset_top = 0
	top_lbl.offset_bottom = 30
	top_bar.add_child(top_lbl)
	
	# Left decoration (memory dump)
	var left_lbl = Label.new()
	left_lbl.text = "0x00F0: 4A 9E 12 0B C5 D1\n0x00F8: 90 FF 00 23 A1 B2\n0x0100: FF FE FD FC 99 88\n0x0108: 11 22 33 44 55 66\n0x0110: AA BB CC DD EE FF\n\n[ SYSTEM OVERLAY LOCK ]\nTARGET_IP: 192.168.1.5"
	left_lbl.add_theme_font_size_override("font_size", 10)
	left_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1, 0.15))
	left_lbl.anchor_left = 0.0
	left_lbl.anchor_top = 0.0
	left_lbl.offset_left = 40
	left_lbl.offset_top = 80
	boss_panel.add_child(left_lbl)
	
	# Right decoration (diagnostics status)
	var right_lbl = Label.new()
	right_lbl.text = "DIAGNOSTICS:\n- ENGINE: CRITICAL\n- SEC_GRID: LOCKED\n- OVERRIDES: ACTIVE\n- TIMEOUT: NONE\n- BYPASS: ATTEMPT_01\n\n[ SECURE GATE KEEPER v2 ]"
	right_lbl.add_theme_font_size_override("font_size", 10)
	right_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1, 0.15))
	right_lbl.anchor_left = 1.0
	right_lbl.anchor_top = 0.0
	right_lbl.offset_left = -240
	right_lbl.offset_top = 80
	boss_panel.add_child(right_lbl)

func show_boss_intro_screen() -> void:
	# Create a full-screen CenterContainer to ensure perfect centering
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0.0
	center_container.anchor_top = 0.0
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	center_container.offset_left = 0
	center_container.offset_right = 0
	center_container.offset_top = 0
	center_container.offset_bottom = 0
	boss_panel.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 360)
	center_container.add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.35, 0.1) # Glowing boss orange
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 24)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)
	
	# Warning icon/title
	var title = Label.new()
	title.text = "⚠️ WARNING: SECURE GATE ENCRYPTED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15)) # Neon red-orange
	layout.add_child(title)
	
	# Instructions/Story
	var desc = Label.new()
	desc.text = "Ruin sector gate firewall is active!\nTo force open the exit gate, you must hack the core node.\n\nTask: Arrange the encryption key matrix [1-8]\ninto correct numerical order."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	layout.add_child(desc)
	
	# Start hack button
	var start_btn = Button.new()
	start_btn.text = "[ INITIATE DECRYPT SEQUENCE ]"
	start_btn.custom_minimum_size = Vector2(250, 48)
	start_btn.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
	start_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		center_container.queue_free() # Remove intro container and panel
		show_boss_gameplay_screen() # Load 8-puzzle game board
	)
	layout.add_child(start_btn)

func show_boss_gameplay_screen() -> void:
	# Create a full-screen CenterContainer to ensure perfect centering
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0.0
	center_container.anchor_top = 0.0
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	center_container.offset_left = 0
	center_container.offset_right = 0
	center_container.offset_top = 0
	center_container.offset_bottom = 0
	boss_panel.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 430)
	center_container.add_child(panel)
	
	boss_gameplay_panel = panel
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.45, 0.1) # Glowing boss orange
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 15)
	margin.add_child(layout)
	
	# Title
	var title = Label.new()
	title.text = "👾 BOSS BATTLE: GATE SECURITY HACK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15))
	layout.add_child(title)
	
	# Subtitle instructions
	var subtitle = Label.new()
	subtitle.text = "Slide tiles 1-8 into numerical order\nto bypass security firewall!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85))
	layout.add_child(subtitle)
	
	# Grid Container for the 3x3 tiles
	boss_grid_container = GridContainer.new()
	boss_grid_container.columns = 3
	boss_grid_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	boss_grid_container.add_theme_constant_override("h_separation", 10)
	boss_grid_container.add_theme_constant_override("v_separation", 10)
	layout.add_child(boss_grid_container)
	
	# Initialize board state
	init_boss_puzzle()
	
	# Populate tiles
	draw_boss_tiles()
	
	# Bottom controls HBox
	var ctrl_hbox = HBoxContainer.new()
	ctrl_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl_hbox.add_theme_constant_override("separation", 20)
	layout.add_child(ctrl_hbox)
	
	# Reset button
	var reset_btn_boss = Button.new()
	reset_btn_boss.text = "🔄 SHUFFLE"
	reset_btn_boss.custom_minimum_size = Vector2(120, 38)
	reset_btn_boss.pressed.connect(func():
		SoundManager.play_sfx("click")
		init_boss_puzzle()
		draw_boss_tiles()
	)
	ctrl_hbox.add_child(reset_btn_boss)
	
	# Forfeit button
	var quit_btn_boss = Button.new()
	quit_btn_boss.text = "🚪 FORFEIT"
	quit_btn_boss.custom_minimum_size = Vector2(120, 38)
	quit_btn_boss.pressed.connect(func():
		SoundManager.play_sfx("click")
		is_boss_active = false
		boss_panel.queue_free()
		$SplitScreen.show() # Show runner view again
		_on_back_pressed() # Exit to level select
	)
	ctrl_hbox.add_child(quit_btn_boss)

func draw_boss_tiles() -> void:
	# Clear old tiles
	for child in boss_grid_container.get_children():
		child.queue_free()
		
	for i in range(9):
		var val = boss_board[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.add_theme_font_size_override("font_size", 24)
		
		# Style
		var style_normal = StyleBoxFlat.new()
		style_normal.set_corner_radius_all(0)
		style_normal.border_width_left = 2
		style_normal.border_width_top = 2
		style_normal.border_width_right = 2
		style_normal.border_width_bottom = 2
		
		if val == 0:
			btn.text = ""
			btn.flat = true
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			btn.text = str(val)
			style_normal.bg_color = Color(0.12, 0.15, 0.22)
			style_normal.border_color = Color(0.2, 0.5, 0.8) # neon blue
			btn.add_theme_stylebox_override("normal", style_normal)
			
			var style_hover = style_normal.duplicate()
			style_hover.bg_color = Color(0.18, 0.22, 0.32)
			style_hover.border_color = Color(0.3, 0.7, 1.0)
			btn.add_theme_stylebox_override("hover", style_hover)
			
			var click_idx = i
			btn.pressed.connect(func():
				on_boss_tile_pressed(click_idx)
			)
			
		boss_grid_container.add_child(btn)

func on_boss_tile_pressed(click_idx: int) -> void:
	var empty_idx = boss_board.find(0)
	
	var r_click = click_idx / 3
	var c_click = click_idx % 3
	var r_empty = empty_idx / 3
	var c_empty = empty_idx % 3
	
	var dist = abs(r_click - r_empty) + abs(c_click - c_empty)
	if dist == 1:
		SoundManager.play_sfx("click")
		boss_board[empty_idx] = boss_board[click_idx]
		boss_board[click_idx] = 0
		
		draw_boss_tiles()
		
		if check_boss_solved():
			handle_boss_win()

func check_boss_solved() -> bool:
	return boss_board == [1, 2, 3, 4, 5, 6, 7, 8, 0]

func handle_boss_win() -> void:
	is_boss_active = false
	SoundManager.play_sfx("win")
	
	for child in boss_grid_container.get_children():
		if child is Button:
			child.disabled = true
			
	var success_overlay = PanelContainer.new()
	var win_style = StyleBoxFlat.new()
	win_style.bg_color = Color(0.05, 0.15, 0.05, 0.95)
	win_style.set_corner_radius_all(0)
	success_overlay.add_theme_stylebox_override("panel", win_style)
	boss_gameplay_panel.add_child(success_overlay)
	
	var center = CenterContainer.new()
	success_overlay.add_child(center)
	
	var win_lbl = Label.new()
	win_lbl.text = "🔓 ACCESS GRANTED!\n\nBOSS DEFEATED\nSECURITY BYPASSED!"
	win_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_lbl.add_theme_font_size_override("font_size", 16)
	win_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5))
	center.add_child(win_lbl)
	
	LevelManager.unlock_level("9")
	
	var timer = get_tree().create_timer(2.2)
	await timer.timeout
	
	boss_panel.queue_free()
	
	var slides = [
		{"img": "res://assets/cuts/cutBoss1out.png", "text": boss1_out_texts[0] if boss1_out_texts.size() > 0 else ""},
		{"img": "res://assets/cuts/cut4.png", "text": boss1_out_texts[1] if boss1_out_texts.size() > 1 else ""}
	]
	show_cutscene_dialogue(slides, func():
		current_level = 9
		LevelManager.selected_level = current_level
		program_queue.clear()
		reset_game()
	)

func _on_clear_pressed() -> void:
	if is_executing:
		return
	program_queue.clear()
	update_queue_ui()

func _on_reset_pressed() -> void:
	reset_game()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/level_select.tscn")

func show_hanoi_boss_level() -> void:
	is_boss_active = true
	
	# Hide runner split screen
	$SplitScreen.hide()
	
	# Create full screen overlay backdrop
	hanoi_panel = ColorRect.new()
	hanoi_panel.color = Color(0.03, 0.04, 0.06, 1.0)
	hanoi_panel.anchor_left = 0.0
	hanoi_panel.anchor_top = 0.0
	hanoi_panel.anchor_right = 1.0
	hanoi_panel.anchor_bottom = 1.0
	hanoi_panel.offset_left = 0
	hanoi_panel.offset_right = 0
	hanoi_panel.offset_top = 0
	hanoi_panel.offset_bottom = 0
	add_child(hanoi_panel)
	
	# Add hacker decorations
	add_hanoi_terminal_decorations()
	
	# Show Hanoi Warning Intro first
	show_hanoi_intro_screen()

func add_hanoi_terminal_decorations() -> void:
	# Top bar
	var top_bar = Panel.new()
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_left = 0
	top_bar.offset_right = 0
	top_bar.offset_top = 0
	top_bar.offset_bottom = 30
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.06, 0.08, 0.12)
	bar_style.border_width_bottom = 2
	bar_style.border_color = Color(0.2, 0.75, 0.4, 0.3) # Green boss color
	top_bar.add_theme_stylebox_override("panel", bar_style)
	hanoi_panel.add_child(top_bar)
	
	var top_lbl = Label.new()
	top_lbl.text = " MAINFRAME DECRYPTOR SHELL v1.2  |  DECRYPTING CORE SECTOR  |  STATUS: INITIALIZING_BYPASS"
	top_lbl.add_theme_font_size_override("font_size", 9)
	top_lbl.add_theme_color_override("font_color", Color(0.2, 0.75, 0.4, 0.6))
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.anchor_left = 0.0
	top_lbl.anchor_right = 1.0
	top_lbl.offset_left = 10
	top_lbl.offset_right = 0
	top_lbl.offset_top = 0
	top_lbl.offset_bottom = 30
	top_bar.add_child(top_lbl)
	
	# Left dump
	var left_lbl = Label.new()
	left_lbl.text = "ADDR_INIT:\n0x40A0: AA FF EE DD\n0x40A4: 00 11 22 33\n0x40A8: 99 88 77 66\n0x40AC: B5 B6 B7 B8\n\n[ OVERRIDE CODES ]\nPEGS_ACTIVE: 3\nDISKS_LOADED: 4"
	left_lbl.add_theme_font_size_override("font_size", 10)
	left_lbl.add_theme_color_override("font_color", Color(0.2, 0.75, 0.4, 0.15))
	left_lbl.anchor_left = 0.0
	left_lbl.anchor_top = 0.0
	left_lbl.offset_left = 40
	left_lbl.offset_top = 80
	hanoi_panel.add_child(left_lbl)
	
	# Right dump
	var right_lbl = Label.new()
	right_lbl.text = "CORE_DECRYPT_LOG:\n- SECTOR_15: COMPLETE\n- HANOI_FIREWALL: ON\n- ENCRYPTION: T_OF_H\n- RETRIES: INFINITE\n- BYPASS_STATUS: PENDING\n\n[ CITY EXIT SECURITY GATE ]"
	right_lbl.add_theme_font_size_override("font_size", 10)
	right_lbl.add_theme_color_override("font_color", Color(0.2, 0.75, 0.4, 0.15))
	right_lbl.anchor_left = 1.0
	right_lbl.anchor_top = 0.0
	right_lbl.offset_left = -240
	right_lbl.offset_top = 80
	hanoi_panel.add_child(right_lbl)

func show_hanoi_intro_screen() -> void:
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0.0
	center_container.anchor_top = 0.0
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	center_container.offset_left = 0
	center_container.offset_right = 0
	center_container.offset_top = 0
	center_container.offset_bottom = 0
	hanoi_panel.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 360)
	center_container.add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.09) # Dark green hacking style
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.2, 0.8, 0.4) # Green accent
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 24)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)
	
	# Warning title
	var title = Label.new()
	title.text = "⚠️ WARNING: HANOI CORE CYCLING LOCK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	layout.add_child(title)
	
	# Instructions
	var desc = Label.new()
	desc.text = "Mainframe firewall is locked by a Hanoi Tower algorithm!\nTo proceed to deep forest, decrypt the core node.\n\nTask: Move all 4 disks from the left peg\nto the right peg. No larger disk may go on top of a smaller disk."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.8, 0.9, 0.85))
	layout.add_child(desc)
	
	# Button
	var start_btn = Button.new()
	start_btn.text = "[ DECRYPT MAINFRAME HANOI ]"
	start_btn.custom_minimum_size = Vector2(250, 48)
	start_btn.add_theme_color_override("font_color", Color(0.2, 0.85, 0.45))
	start_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		center_container.queue_free()
		show_hanoi_gameplay_screen()
	)
	layout.add_child(start_btn)

func show_hanoi_gameplay_screen() -> void:
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0.0
	center_container.anchor_top = 0.0
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	center_container.offset_left = 0
	center_container.offset_right = 0
	center_container.offset_top = 0
	center_container.offset_bottom = 0
	hanoi_panel.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440, 460)
	center_container.add_child(panel)
	
	hanoi_gameplay_panel = panel
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.07)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.2, 0.75, 0.4)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 15)
	margin.add_child(layout)
	
	# Title
	var title = Label.new()
	title.text = "🧙‍♂️ BOSS BATTLE: DECRYPT HANOI CORE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	layout.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Click pegs to select/move disk.\nMove all disks from left to right peg!"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.85, 0.75))
	layout.add_child(subtitle)
	
	# Hanoi Game Control node
	hanoi_control = HanoiControl.new()
	hanoi_control.parent_stage = self
	layout.add_child(hanoi_control)
	
	# Bottom buttons
	var ctrl_hbox = HBoxContainer.new()
	ctrl_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl_hbox.add_theme_constant_override("separation", 20)
	layout.add_child(ctrl_hbox)
	
	# Reset
	var reset_btn_hanoi = Button.new()
	reset_btn_hanoi.text = "🔄 RESTART"
	reset_btn_hanoi.custom_minimum_size = Vector2(120, 38)
	reset_btn_hanoi.pressed.connect(func():
		SoundManager.play_sfx("click")
		hanoi_control.pegs = [[4, 3, 2, 1], [], []]
		hanoi_control.selected_peg = -1
		hanoi_control.queue_redraw()
	)
	ctrl_hbox.add_child(reset_btn_hanoi)
	
	# Forfeit
	var quit_btn_hanoi = Button.new()
	quit_btn_hanoi.text = "🚪 FORFEIT"
	quit_btn_hanoi.custom_minimum_size = Vector2(120, 38)
	quit_btn_hanoi.pressed.connect(func():
		SoundManager.play_sfx("click")
		is_boss_active = false
		hanoi_panel.queue_free()
		$SplitScreen.show()
		_on_back_pressed()
	)
	ctrl_hbox.add_child(quit_btn_hanoi)

func handle_hanoi_win() -> void:
	is_boss_active = false
	SoundManager.play_sfx("win")
	
	hanoi_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var success_overlay = PanelContainer.new()
	var win_style = StyleBoxFlat.new()
	win_style.bg_color = Color(0.05, 0.15, 0.05, 0.95)
	win_style.set_corner_radius_all(0)
	success_overlay.add_theme_stylebox_override("panel", win_style)
	hanoi_gameplay_panel.add_child(success_overlay)
	
	var center = CenterContainer.new()
	success_overlay.add_child(center)
	
	var win_lbl = Label.new()
	win_lbl.text = "🔓 CYCLING BYPASSED!\n\nMAINFRAME COMPROMISED\nCORE SHUTTING DOWN..."
	win_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_lbl.add_theme_font_size_override("font_size", 16)
	win_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5))
	center.add_child(win_lbl)
	
	var timer = get_tree().create_timer(2.2)
	await timer.timeout
	
	hanoi_panel.queue_free()
	
	var slides = []
	for txt in boss3_out_texts:
		slides.append({"img": "", "text": txt})
	show_cutscene_dialogue(slides, func():
		show_end_credits()
	)

# Inner class representing the Hanoi game board control
class HanoiControl extends Control:
	var pegs: Array = [[4, 3, 2, 1], [], []]
	var selected_peg := -1
	var parent_stage = null
	
	func _ready() -> void:
		custom_minimum_size = Vector2(400, 270)
		mouse_filter = Control.MOUSE_FILTER_STOP
		
	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var click_x = event.position.x
			var clicked_peg = 0
			if click_x < 140:
				clicked_peg = 0
			elif click_x >= 140 and click_x < 260:
				clicked_peg = 1
			else:
				clicked_peg = 2
				
			handle_click(clicked_peg)
			
	func handle_click(clicked_peg: int) -> void:
		if selected_peg == -1:
			# Try to select
			if pegs[clicked_peg].size() > 0:
				selected_peg = clicked_peg
				parent_stage.SoundManager.play_sfx("click")
		else:
			# Try to move
			if selected_peg == clicked_peg:
				# Deselect
				selected_peg = -1
				parent_stage.SoundManager.play_sfx("click")
			else:
				# Check move validity
				var source_stack = pegs[selected_peg]
				var dest_stack = pegs[clicked_peg]
				
				var can_move = false
				if dest_stack.size() == 0:
					can_move = true
				else:
					var moving_disk = source_stack.back()
					var top_disk = dest_stack.back()
					if moving_disk < top_disk:
						can_move = true
						
				if can_move:
					var disk = source_stack.pop_back()
					dest_stack.append(disk)
					parent_stage.SoundManager.play_sfx("click")
					
					# Check win condition: all disks on Peg 2
					if pegs[2] == [4, 3, 2, 1]:
						parent_stage.handle_hanoi_win()
				else:
					parent_stage.SoundManager.play_sfx("fail")
					
				selected_peg = -1
				
		queue_redraw()
		
	func _draw() -> void:
		# Draw platform
		draw_rect(Rect2(10, 240, 380, 15), Color(0.2, 0.22, 0.25), true)
		# Draw rods
		draw_rect(Rect2(76, 80, 8, 160), Color(0.3, 0.32, 0.35), true)
		draw_rect(Rect2(196, 80, 8, 160), Color(0.3, 0.32, 0.35), true)
		draw_rect(Rect2(316, 80, 8, 160), Color(0.3, 0.32, 0.35), true)
		
		# Draw selection arrow
		if selected_peg != -1:
			var sel_x = 80 if selected_peg == 0 else (200 if selected_peg == 1 else 320)
			draw_polygon(PackedVector2Array([
				Vector2(sel_x - 8, 50),
				Vector2(sel_x + 8, 50),
				Vector2(sel_x, 62)
			]), [Color(1.0, 0.5, 0.1)])
			
		# Draw disks
		for p in range(3):
			var stack = pegs[p]
			for i in range(stack.size()):
				var disk_size = stack[i]
				var peg_x = 80 if p == 0 else (200 if p == 1 else 320)
				var disk_y = 240 - (i + 1) * 20
				var w = 30 + disk_size * 22
				
				var color = Color(0.2, 0.5, 0.8) # default blue
				match disk_size:
					1: color = Color(1.0, 0.35, 0.15) # orange-red
					2: color = Color(1.0, 0.65, 0.15) # yellow-orange
					3: color = Color(0.2, 0.75, 0.4)  # green
					4: color = Color(0.2, 0.5, 0.8)   # blue
					
				# Draw disk
				draw_rect(Rect2(peg_x - w/2.0, disk_y, w, 18), color, true)
				draw_rect(Rect2(peg_x - w/2.0, disk_y, w, 18), Color(0.05, 0.05, 0.05), false, 1.5)
				
				# Disk value string
				var font = ThemeDB.fallback_font
				draw_string(font, Vector2(peg_x - 5, disk_y + 13), str(disk_size), HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.WHITE)

func show_pipe_boss_level() -> void:
	is_boss_active = true
	is_pipe_boss_active = true
	pipe_time_left = 60.0
	
	# Hide runner split screen
	$SplitScreen.hide()
	
	# Create full screen overlay backdrop
	pipe_panel = ColorRect.new()
	pipe_panel.color = Color(0.04, 0.03, 0.06, 1.0)
	pipe_panel.anchor_left = 0.0
	pipe_panel.anchor_top = 0.0
	pipe_panel.anchor_right = 1.0
	pipe_panel.anchor_bottom = 1.0
	add_child(pipe_panel)
	
	# Add decorations
	add_pipe_terminal_decorations()
	
	# Show Pipe Intro Screen
	show_pipe_intro_screen()

func add_pipe_terminal_decorations() -> void:
	# Top bar
	var top_bar = Panel.new()
	top_bar.anchor_left = 0.0
	top_bar.anchor_right = 1.0
	top_bar.anchor_top = 0.0
	top_bar.anchor_bottom = 0.0
	top_bar.offset_bottom = 30
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.08, 0.05, 0.1)
	bar_style.border_width_bottom = 2
	bar_style.border_color = Color(0.9, 0.5, 0.15, 0.3) # Orange theme
	top_bar.add_theme_stylebox_override("panel", bar_style)
	pipe_panel.add_child(top_bar)
	
	var top_lbl = Label.new()
	top_lbl.text = " COOLANT SHIELD PROTOCOL v2.8  |  CITY COOLING GRID  |  WARNING: MELTDOWN_DANGER"
	top_lbl.add_theme_font_size_override("font_size", 9)
	top_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15, 0.6))
	top_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_lbl.anchor_left = 0.0
	top_lbl.anchor_right = 1.0
	top_lbl.offset_left = 10
	top_lbl.offset_bottom = 30
	top_bar.add_child(top_lbl)
	
	# Left dump
	var left_lbl = Label.new()
	left_lbl.text = "SYS_GRID_DUMP:\nTEMP: 98.4C -> DANGER\nFLOW_RATE: 0.0 L/s\nCORES_ACTIVE: 5\n\n[ PROTOCOL ]\nCONNECT SOURCE (L)\nTO DRAIN (R)\nROTATE SECTORS!"
	left_lbl.add_theme_font_size_override("font_size", 10)
	left_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15, 0.15))
	left_lbl.anchor_left = 0.0
	left_lbl.anchor_top = 0.0
	left_lbl.offset_left = 40
	left_lbl.offset_top = 80
	pipe_panel.add_child(left_lbl)
	
	# Right dump
	var right_lbl = Label.new()
	right_lbl.text = "MAINFRAME_LOGS:\n- HYDRAULICS: LOCKED\n- VALVE_BYPASS: ON\n- TEMP_SENSORS: RED\n- EMERGENCY: ACTIVE\n\n[ COMPACT PIPE LABYRINTH ]"
	right_lbl.add_theme_font_size_override("font_size", 10)
	right_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15, 0.15))
	right_lbl.anchor_left = 1.0
	right_lbl.anchor_top = 0.0
	right_lbl.offset_left = -240
	right_lbl.offset_top = 80
	pipe_panel.add_child(right_lbl)

func show_pipe_intro_screen() -> void:
	var center_container = CenterContainer.new()
	center_container.anchor_left = 0.0
	center_container.anchor_top = 0.0
	center_container.anchor_right = 1.0
	center_container.anchor_bottom = 1.0
	pipe_panel.add_child(center_container)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 360)
	center_container.add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.08) # Dark reddish orange hacking style
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.5, 0.15) # Orange accent
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 24)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(layout)
	
	var title = Label.new()
	title.text = "⚠️ WARNING: REACTOR TEMPERATURE DANGER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.15))
	layout.add_child(title)
	
	var desc = Label.new()
	desc.text = "Emergency coolant grid is scrambled!\nTo unlock the exit gate, bypass the coolant valves.\n\nTask: Connect a continuous flow of water pipes\nfrom the left source to the right drain.\n\nWarning: Reactor meltdown in 60 seconds!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_font_size_override("font_size", 11)
	desc.add_theme_color_override("font_color", Color(0.95, 0.9, 0.85))
	layout.add_child(desc)
	
	var start_btn = Button.new()
	start_btn.text = "[ ENGAGE BYPASS GRID ]"
	start_btn.custom_minimum_size = Vector2(250, 48)
	start_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15))
	start_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		center_container.queue_free()
		start_pipe_gameplay()
	)
	layout.add_child(start_btn)

func start_pipe_gameplay() -> void:
	# Outer VBox for layout
	var main_vbox = VBoxContainer.new()
	main_vbox.anchor_left = 0.0
	main_vbox.anchor_top = 0.0
	main_vbox.anchor_right = 1.0
	main_vbox.anchor_bottom = 1.0
	main_vbox.offset_top = 40
	main_vbox.offset_bottom = -20
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 15)
	pipe_panel.add_child(main_vbox)
	
	# Timer display label
	pipe_timer_label = Label.new()
	pipe_timer_label.text = "TIME REMAINING: 60.0s"
	pipe_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pipe_timer_label.add_theme_font_size_override("font_size", 14)
	pipe_timer_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.15))
	main_vbox.add_child(pipe_timer_label)
	
	# Gameplay board container panel
	pipe_gameplay_panel = PanelContainer.new()
	pipe_gameplay_panel.custom_minimum_size = Vector2(480, 420)
	pipe_gameplay_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(pipe_gameplay_panel)
	
	var frame_style = StyleBoxFlat.new()
	frame_style.bg_color = Color(0.06, 0.06, 0.08)
	frame_style.border_width_left = 4
	frame_style.border_width_top = 4
	frame_style.border_width_right = 4
	frame_style.border_width_bottom = 4
	frame_style.border_color = Color(0.25, 0.28, 0.35)
	frame_style.set_corner_radius_all(0)
	pipe_gameplay_panel.add_theme_stylebox_override("panel", frame_style)
	
	var board_margin = MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 20)
	board_margin.add_theme_constant_override("margin_right", 20)
	board_margin.add_theme_constant_override("margin_top", 20)
	board_margin.add_theme_constant_override("margin_bottom", 20)
	pipe_gameplay_panel.add_child(board_margin)
	
	# Instantiate PipeControl
	pipe_control = PipeControl.new()
	pipe_control.parent_stage = self
	board_margin.add_child(pipe_control)
	
	# Bottom controls (Forfeit)
	var ctrl_hbox = HBoxContainer.new()
	ctrl_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(ctrl_hbox)
	
	var quit_btn = Button.new()
	quit_btn.text = "🚪 FORFEIT"
	quit_btn.custom_minimum_size = Vector2(120, 38)
	quit_btn.pressed.connect(func():
		SoundManager.play_sfx("click")
		is_boss_active = false
		is_pipe_boss_active = false
		pipe_panel.queue_free()
		$SplitScreen.show()
		_on_back_pressed()
	)
	ctrl_hbox.add_child(quit_btn)

func handle_pipe_win() -> void:
	is_boss_active = false
	is_pipe_boss_active = false
	SoundManager.play_sfx("win")
	
	pipe_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var success_overlay = PanelContainer.new()
	var win_style = StyleBoxFlat.new()
	win_style.bg_color = Color(0.05, 0.15, 0.05, 0.95)
	win_style.set_corner_radius_all(0)
	success_overlay.add_theme_stylebox_override("panel", win_style)
	pipe_gameplay_panel.add_child(success_overlay)
	
	var center = CenterContainer.new()
	success_overlay.add_child(center)
	
	var win_lbl = Label.new()
	win_lbl.text = "🔓 VALVE FLOW BYPASSED!\n\nCOOLING SYSTEMS ONLINE\nSECURE GATE UNLOCKED!"
	win_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_lbl.add_theme_font_size_override("font_size", 15)
	win_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 0.5))
	center.add_child(win_lbl)
	
	LevelManager.unlock_level("16")
	
	var timer = get_tree().create_timer(2.2)
	await timer.timeout
	
	pipe_panel.queue_free()
	
	var slides = []
	for txt in boss2_out_texts:
		slides.append({"img": "res://assets/cuts/cutBoss2o.png", "text": txt})
	show_cutscene_dialogue(slides, func():
		current_level = 16
		LevelManager.selected_level = current_level
		program_queue.clear()
		reset_game()
	)

func handle_pipe_fail() -> void:
	is_boss_active = false
	is_pipe_boss_active = false
	SoundManager.play_sfx("fail")
	
	pipe_panel.queue_free()
	$SplitScreen.show() # Restore runner screen
	
	lose_reason_label.text = "Reactor cooling grid melted down! You ran out of time."
	lose_overlay.show()

# Inner class representing the Pipe Mania game board control
class PipeControl extends Control:
	var pipe_grid: Array = []
	var parent_stage = null
	
	func _ready() -> void:
		custom_minimum_size = Vector2(400, 380)
		mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Generate 5x5 grid
		pipe_grid.clear()
		for y in range(5):
			var row = []
			for x in range(5):
				row.append({
					"type": 0,       # 0: Straight, 1: Corner
					"rotation": 0,   # 0 to 3 (clockwise rotations)
					"is_connected": false
				})
			pipe_grid.append(row)
			
		# Scramble grid and seed dummy distraction pipes
		# Seed dummy pipes of random types
		for y in range(5):
			for x in range(5):
				pipe_grid[y][x].type = randi() % 2
				pipe_grid[y][x].rotation = randi() % 4
				
		# Define the solution path elements explicitly to guarantee solvability
		# Path: (0,2) -> (0,1) -> (1,1) -> (2,1) -> (3,1) -> (3,2) -> (3,3) -> (4,3) -> (4,2)
		set_path_pipe(0, 2, 1, randi() % 4) # Corner (UP/LEFT target)
		set_path_pipe(0, 1, 1, randi() % 4) # Corner (DOWN/RIGHT target)
		set_path_pipe(1, 1, 0, randi() % 4) # Straight (H target)
		set_path_pipe(2, 1, 0, randi() % 4) # Straight (H target)
		set_path_pipe(3, 1, 1, randi() % 4) # Corner (LEFT/DOWN target)
		set_path_pipe(3, 2, 0, randi() % 4) # Straight (V target)
		set_path_pipe(3, 3, 1, randi() % 4) # Corner (UP/RIGHT target)
		set_path_pipe(4, 3, 1, randi() % 4) # Corner (LEFT/UP target)
		set_path_pipe(4, 2, 1, randi() % 4) # Corner (DOWN/RIGHT target)
		
		update_connections()

	func set_path_pipe(x: int, y: int, type: int, rotation: int) -> void:
		pipe_grid[y][x].type = type
		pipe_grid[y][x].rotation = rotation

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var cell_w = 400.0 / 5.0
			var cell_h = 380.0 / 5.0
			var grid_x = int(event.position.x / cell_w)
			var grid_y = int(event.position.y / cell_h)
			
			if grid_x >= 0 and grid_x < 5 and grid_y >= 0 and grid_y < 5:
				rotate_cell(grid_x, grid_y)

	func rotate_cell(x: int, y: int) -> void:
		pipe_grid[y][x].rotation = (pipe_grid[y][x].rotation + 1) % 4
		parent_stage.SoundManager.play_sfx("click")
		update_connections()
		queue_redraw()

	func update_connections() -> void:
		# Reset connections
		for y in range(5):
			for x in range(5):
				pipe_grid[y][x].is_connected = false
				
		# DFS propagation starting from source at (0, 2)
		var visited = []
		for i in range(5):
			var r = []
			for j in range(5):
				r.append(false)
			visited.append(r)
			
		# Check if source connects left
		if connects_direction(0, 2, 3): # LEFT
			dfs_connect(0, 2, visited)
			
		# Check win condition: (4, 2) connected AND connects right
		if pipe_grid[2][4].is_connected and connects_direction(4, 2, 1): # RIGHT
			parent_stage.handle_pipe_win()

	func dfs_connect(x: int, y: int, visited: Array) -> void:
		visited[y][x] = true
		pipe_grid[y][x].is_connected = true
		
		# Directions: UP=0, RIGHT=1, DOWN=2, LEFT=3
		var dx = [0, 1, 0, -1]
		var dy = [-1, 0, 1, 0]
		
		for d in range(4):
			if connects_direction(x, y, d):
				var nx = x + dx[d]
				var ny = y + dy[d]
				if nx >= 0 and nx < 5 and ny >= 0 and ny < 5:
					if not visited[ny][nx]:
						# Check if neighbor connects back
						var opp_direction = (d + 2) % 4
						if connects_direction(nx, ny, opp_direction):
							dfs_connect(nx, ny, visited)

	func connects_direction(x: int, y: int, d: int) -> bool:
		var cell = pipe_grid[y][x]
		if cell.type == 0: # Straight
			if cell.rotation % 2 == 0: # Horizontal
				return d == 1 or d == 3
			else: # Vertical
				return d == 0 or d == 2
		else: # Corner
			# rotation 0 connects LEFT (3) and DOWN (2)
			# rotation 1 connects UP (0) and LEFT (3)
			# rotation 2 connects RIGHT (1) and UP (0)
			# rotation 3 connects DOWN (2) and RIGHT (1)
			match cell.rotation:
				0: return d == 3 or d == 2
				1: return d == 0 or d == 3
				2: return d == 1 or d == 0
				3: return d == 2 or d == 1
		return false

	func _draw() -> void:
		# Draw outer panel background
		draw_rect(Rect2(0, 0, 400, 380), Color(0.04, 0.04, 0.05), true)
		
		var cell_w = 400.0 / 5.0
		var cell_h = 380.0 / 5.0
		
		# Draw source on left
		draw_rect(Rect2(-16, 2 * cell_h + 10, 16, cell_h - 20), Color(0.1, 0.8, 0.3), true)
		# Draw drain on right
		draw_rect(Rect2(400, 2 * cell_h + 10, 16, cell_h - 20), Color(0.1, 0.8, 0.3), true)
		
		for y in range(5):
			for x in range(5):
				var cx = x * cell_w + cell_w / 2.0
				var cy = y * cell_h + cell_h / 2.0
				
				# Cell bevel border
				draw_rect(Rect2(x * cell_w + 3, y * cell_h + 3, cell_w - 6, cell_h - 6), Color(0.08, 0.09, 0.12), true)
				draw_rect(Rect2(x * cell_w + 3, y * cell_h + 3, cell_w - 6, cell_h - 6), Color(0.2, 0.22, 0.28), false, 1.5)
				
				# Draw pipe
				var pipe = pipe_grid[y][x]
				var pipe_color = Color(0.2, 0.75, 1.0) if pipe.is_connected else Color(0.35, 0.4, 0.45)
				var thickness = 16.0
				
				# Set canvas transform to cell center with rotation
				draw_set_transform(Vector2(cx, cy), pipe.rotation * (PI / 2.0), Vector2.ONE)
				
				if pipe.type == 0: # Straight
					# Horizontal pipe
					draw_line(Vector2(-cell_w/2.0 + 3, 0), Vector2(cell_w/2.0 - 3, 0), pipe_color, thickness)
					# Flanges
					draw_rect(Rect2(-cell_w/2.0 + 3, -12, 5, 24), pipe_color * 1.2, true)
					draw_rect(Rect2(cell_w/2.0 - 8, -12, 5, 24), pipe_color * 1.2, true)
				else: # Corner
					# Left to Down corner
					draw_line(Vector2(-cell_w/2.0 + 3, 0), Vector2(0, 0), pipe_color, thickness)
					draw_line(Vector2(0, 0), Vector2(0, cell_h/2.0 - 3), pipe_color, thickness)
					# Center elbow joint circle
					draw_circle(Vector2.ZERO, thickness / 2.0, pipe_color)
					# Flanges
					draw_rect(Rect2(-cell_w/2.0 + 3, -12, 5, 24), pipe_color * 1.2, true)
					draw_rect(Rect2(-12, cell_h/2.0 - 8, 24, 5), pipe_color * 1.2, true)
					
				# Reset transform
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
