extends Node

# Global volume settings (linear scale 0.0 to 1.0)
var music_volume: float = 0.7
var sfx_volume: float = 0.8

# Audio stream players
var music_player: AudioStreamPlayer
var sfx_player_pool: Array[AudioStreamPlayer] = []
var max_pool_size := 6

# Loaded wav references
var menu_music: AudioStream
var school_music: AudioStream
var city_music: AudioStream
var forest_music: AudioStream

var sfx_library: Dictionary = {}

func _ready() -> void:
	# Setup audio players
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	
	for i in range(max_pool_size):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_player_pool.append(p)
		
	# Generate procedural audio loops and effects
	generate_procedural_audio()
	
	# Apply initial volumes
	update_volumes()

func update_volumes() -> void:
	music_player.volume_db = linear_to_db(music_volume)
	if music_volume <= 0.001:
		music_player.volume_db = -80.0
		
	for p in sfx_player_pool:
		p.volume_db = linear_to_db(sfx_volume)
		if sfx_volume <= 0.001:
			p.volume_db = -80.0

func set_music_volume(val: float) -> void:
	music_volume = clamp(val, 0.0, 1.0)
	update_volumes()

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	update_volumes()
	# Play a tiny test beep so they hear the volume change
	play_sfx("click")

func play_sfx(sfx_name: String) -> void:
	if not sfx_library.has(sfx_name):
		return
		
	# Find an idle player in the pool
	for p in sfx_player_pool:
		if not p.playing:
			p.stream = sfx_library[sfx_name]
			p.play()
			return
			
	# Fallback: steal the first player
	var first = sfx_player_pool[0]
	first.stream = sfx_library[sfx_name]
	first.play()

func play_music(type: String) -> void:
	var stream: AudioStream = null
	if type == "menu":
		stream = menu_music
	elif type == "game":
		var lvl = LevelManager.selected_level
		if lvl <= 8:
			stream = school_music
		elif lvl <= 15:
			stream = city_music
		else:
			stream = forest_music
		
	if stream == null:
		music_player.stop()
		return
		
	if music_player.stream == stream and music_player.playing:
		return
		
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

# Helper tone generator
func generate_tone(freq_start: float, freq_end: float, duration: float, type: String = "sine") -> AudioStreamWAV:
	var mix_rate := 22050
	var total_samples := int(duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase := 0.0
	for i in range(total_samples):
		var t = float(i) / mix_rate
		var progress = t / duration
		var freq = lerp(freq_start, freq_end, progress)
		
		var sample := 0.0
		if type == "sine":
			sample = sin(phase)
		elif type == "square":
			sample = 1.0 if sin(phase) >= 0 else -1.0
		elif type == "triangle":
			sample = abs(fmod(phase / PI + 1.0, 2.0) - 1.0) * 2.0 - 1.0
		elif type == "noise":
			sample = randf_range(-1.0, 1.0)
			
		var envelope := 1.0
		if progress > 0.8:
			envelope = lerp(1.0, 0.0, (progress - 0.8) / 0.2)
		
		sample *= envelope * 0.3 # Dampen to prevent clipping
		
		var val := int(sample * 32767.0)
		var byte_idx = i * 2
		bytes[byte_idx] = val & 0xFF
		bytes[byte_idx + 1] = (val >> 8) & 0xFF
		
		phase += 2.0 * PI * freq / mix_rate
		
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

# Helper sequence/arpeggio generator
func generate_sequence(notes: Array, note_duration: float, type: String = "sine") -> AudioStreamWAV:
	var mix_rate := 22050
	var total_samples := int(notes.size() * note_duration * mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var byte_idx := 0
	for note_idx in range(notes.size()):
		var freq = notes[note_idx]
		var phase := 0.0
		var note_samples = int(note_duration * mix_rate)
		for i in range(note_samples):
			var progress = float(i) / note_samples
			var sample := 0.0
			if type == "sine":
				sample = sin(phase)
			elif type == "triangle":
				sample = abs(fmod(phase / PI + 1.0, 2.0) - 1.0) * 2.0 - 1.0
			
			var envelope = 1.0
			if progress > 0.7:
				envelope = lerp(1.0, 0.0, (progress - 0.7) / 0.3)
			
			sample *= envelope * 0.25
			var val = int(sample * 32767.0)
			
			bytes[byte_idx] = val & 0xFF
			bytes[byte_idx + 1] = (val >> 8) & 0xFF
			byte_idx += 2
			phase += 2.0 * PI * freq / mix_rate
			
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

# Music loop generator (Polyphonic melody + bassline)
func generate_music_loop(notes: Array, bass: Array, tempo_bpm: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var step_duration = 60.0 / tempo_bpm / 4.0 # 16th step
	var total_steps = notes.size()
	var step_samples = int(step_duration * mix_rate)
	var total_samples = total_steps * step_samples
	
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)
	
	var phase_melody := 0.0
	var phase_bass := 0.0
	
	for step in range(total_steps):
		var m_freq = notes[step]
		var b_freq = bass[step]
		var start_sample = step * step_samples
		
		for i in range(step_samples):
			var sample_idx = start_sample + i
			var progress = float(i) / step_samples
			
			# Melody (Sine)
			var m_sample = 0.0
			if m_freq > 0:
				m_sample = sin(phase_melody)
				var env = 1.0
				if progress > 0.6:
					env = lerp(1.0, 0.0, (progress - 0.6) / 0.4)
				m_sample *= env * 0.12
				phase_melody += 2.0 * PI * m_freq / mix_rate
			
			# Bass (Triangle)
			var b_sample = 0.0
			if b_freq > 0:
				b_sample = abs(fmod(phase_bass / PI + 1.0, 2.0) - 1.0) * 2.0 - 1.0
				var env = 1.0
				if progress > 0.8:
					env = lerp(1.0, 0.0, (progress - 0.8) / 0.2)
				b_sample *= env * 0.18
				phase_bass += 2.0 * PI * b_freq / mix_rate
				
			var mixed = m_sample + b_sample
			var val = int(mixed * 32767.0)
			
			var byte_idx = sample_idx * 2
			bytes[byte_idx] = val & 0xFF
			bytes[byte_idx + 1] = (val >> 8) & 0xFF
			
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = total_samples
	wav.data = bytes
	return wav

func generate_procedural_audio() -> void:
	# 1. SFX Library
	# Jump SFX: rising sweep (260Hz -> 820Hz)
	sfx_library["jump"] = generate_tone(260.0, 820.0, 0.35, "sine")
	
	# Slide SFX: white noise friction sweep
	sfx_library["slide"] = generate_tone(180.0, 90.0, 0.42, "noise")
	
	# Duck SFX: diving quick sweep
	sfx_library["duck"] = generate_tone(320.0, 160.0, 0.22, "sine")
	
	# Climb SFX: two alternating quick taps
	sfx_library["climb"] = generate_sequence([350.0, 440.0], 0.14, "triangle")
	
	# Run SFX: extremely quick triangle tick
	sfx_library["run"] = generate_tone(140.0, 140.0, 0.05, "triangle")
	
	# Win SFX: happy rising C-Major arpeggio
	sfx_library["win"] = generate_sequence([261.63, 329.63, 392.00, 523.25], 0.12, "triangle")
	
	# Fail SFX: sad buzzing decline
	sfx_library["fail"] = generate_tone(380.0, 100.0, 0.65, "square")
	
	# Click SFX: short clean high beep
	sfx_library["click"] = generate_tone(580.0, 780.0, 0.04, "sine")

	# 2. Loop Music
	# Menu music (Loaded from external file)
	menu_music = load("res://assets/sound/main.mp3")

	# School Ruins: Faster Lo-fi Hip Hop loop (peppy, jazzy minor 7th chord feel)
	var school_m = [329.63, 0, 392.00, 440.00, 0, 523.25, 0, 440.00, 392.00, 0, 329.63, 293.66, 0, 329.63, 0, 0]
	var school_b = [110.00, 0, 110.00, 0, 146.83, 0, 146.83, 0, 98.00, 0, 98.00, 0, 73.42, 0, 82.41, 0]
	school_music = generate_music_loop(school_m, school_b, 108.0)

	# Decaying City: Darksynth / Cyberpunk (heavy industrial saw bass + phrygian lead flat-5ths)
	var city_m = [440.0, 440.0, 466.16, 440.0, 0, 523.25, 440.0, 392.0, 440.0, 440.0, 466.16, 440.0, 0, 311.13, 329.63, 0]
	var city_b = [110.0, 110.0, 110.0, 110.0, 110.0, 110.0, 110.0, 110.0, 82.41, 82.41, 82.41, 82.41, 77.78, 77.78, 82.41, 0]
	city_music = generate_music_loop(city_m, city_b, 132.0)

	# Deep Forest: Tribal Chase / Escape (galloping tribal rhythm + staccato flute-like minor scale)
	var forest_m = [587.33, 622.25, 0, 698.46, 0, 783.99, 698.46, 622.25, 587.33, 0, 493.88, 523.25, 0, 587.33, 0, 0]
	var forest_b = [146.83, 0, 146.83, 146.83, 0, 110.00, 0, 110.00, 146.83, 0, 146.83, 146.83, 0, 196.00, 0, 196.00]
	forest_music = generate_music_loop(forest_m, forest_b, 145.0)

func open_settings() -> void:
	# Avoid duplicate popups
	if get_tree().root.has_node("SettingsPopup"):
		return
		
	var popup = CanvasLayer.new()
	popup.name = "SettingsPopup"
	
	# Dark overlay background
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	popup.add_child(bg)
	
	# Centered Settings Panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 280)
	panel.anchors_preset = Control.PRESET_CENTER
	panel.position = Vector2(1280/2.0 - 210, 720/2.0 - 140)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	style.border_color = Color(0.2, 0.5, 0.8, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 25
	panel.add_theme_stylebox_override("panel", style)
	bg.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 35)
	margin.add_theme_constant_override("margin_right", 35)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)
	
	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)
	
	# Title Label
	var title = Label.new()
	title.text = "⚙️ AUDIO SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	layout.add_child(title)
	
	# Music Volume Slider HBox
	var m_vbox = VBoxContainer.new()
	m_vbox.add_theme_constant_override("separation", 4)
	var m_label = Label.new()
	m_label.text = "MUSIC VOLUME: " + str(int(music_volume * 100)) + "%"
	m_label.add_theme_font_size_override("font_size", 14)
	m_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	m_vbox.add_child(m_label)
	
	var m_slider = HSlider.new()
	m_slider.min_value = 0.0
	m_slider.max_value = 1.0
	m_slider.step = 0.05
	m_slider.value = music_volume
	m_slider.value_changed.connect(func(val):
		set_music_volume(val)
		m_label.text = "MUSIC VOLUME: " + str(int(val * 100)) + "%"
	)
	m_vbox.add_child(m_slider)
	layout.add_child(m_vbox)
	
	# SFX Volume Slider HBox
	var s_vbox = VBoxContainer.new()
	s_vbox.add_theme_constant_override("separation", 4)
	var s_label = Label.new()
	s_label.text = "SFX VOLUME: " + str(int(sfx_volume * 100)) + "%"
	s_label.add_theme_font_size_override("font_size", 14)
	s_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	s_vbox.add_child(s_label)
	
	var s_slider = HSlider.new()
	s_slider.min_value = 0.0
	s_slider.max_value = 1.0
	s_slider.step = 0.05
	s_slider.value = sfx_volume
	s_slider.value_changed.connect(func(val):
		set_sfx_volume(val)
		s_label.text = "SFX VOLUME: " + str(int(val * 100)) + "%"
	)
	s_vbox.add_child(s_slider)
	layout.add_child(s_vbox)
	
	# Close Button
	var close_btn = Button.new()
	close_btn.text = "SAVE & CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 38)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.15, 0.2)
	btn_style.border_color = Color(0.3, 0.45, 0.6)
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.set_corner_radius_all(0)
	close_btn.add_theme_stylebox_override("normal", btn_style)
	
	var btn_style_hover = StyleBoxFlat.new()
	btn_style_hover.bg_color = Color(0.18, 0.22, 0.3)
	btn_style_hover.border_color = Color(0.4, 0.65, 0.9)
	btn_style_hover.border_width_left = 1
	btn_style_hover.border_width_right = 1
	btn_style_hover.border_width_top = 1
	btn_style_hover.border_width_bottom = 1
	btn_style_hover.set_corner_radius_all(0)
	close_btn.add_theme_stylebox_override("hover", btn_style_hover)
	
	close_btn.pressed.connect(func():
		play_sfx("click")
		popup.queue_free()
	)
	layout.add_child(close_btn)
	
	get_tree().root.add_child(popup)
