extends Node2D

const GROUND_Y = 250.0

# Animation parameters modified by tweening
var body_offset := Vector2.ZERO
var body_scale := Vector2.ONE
var body_rotation := 0.0
var leg_left_pos := Vector2(-8, 40)
var leg_right_pos := Vector2(8, 40)
var current_state := "IDLE"
var run_step_timer := 0.0

# Particle FX System
var fx_particles: Array = []

@onready var SoundManager = get_node("/root/SoundManager")

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	# Update active particles
	var active_particles = []
	for p in fx_particles:
		p.pos += p.vel * delta
		p.vel.y += p.gravity * delta
		p.life -= delta
		if p.life > 0.0:
			active_particles.append(p)
	fx_particles = active_particles
	
	# Spawn running footstep dust & trigger SFX
	if current_state == "RUN":
		if randf() < 0.12:
			spawn_particle(Vector2(-10, 42), Vector2(randf_range(-40, -10), randf_range(-15, -5)), Color(0.7, 0.7, 0.7, 0.4), 0.4, 4.0)
		run_step_timer += delta
		if run_step_timer >= 0.28:
			run_step_timer = 0.0
			SoundManager.play_sfx("run")
		
	# Spawn sliding sparks
	if current_state == "SLIDE" and randf() < 0.35:
		spawn_particle(Vector2(randf_range(-20, 10), 42), Vector2(randf_range(-80, -30), randf_range(-20, -50)), Color(1.0, 0.65, 0.2, 0.8), 0.35, 3.0, -80.0)
		
	# Fade out when running off-screen (to avoid showing the character in the grey aspect margin)
	if global_position.x > 1110.0:
		modulate.a = clamp(1.0 - (global_position.x - 1110.0) / 60.0, 0.0, 1.0)
		
	queue_redraw()

func spawn_particle(offset: Vector2, velocity: Vector2, color: Color, life: float, size: float, gravity: float = 0.0) -> void:
	fx_particles.append({
		"pos": offset,
		"vel": velocity,
		"color": color,
		"life_max": life,
		"life": life,
		"size": size,
		"gravity": gravity
	})

func spawn_impact_dust() -> void:
	# Spawn dust clouds expanding left and right on landing/impact
	for i in range(8):
		var dx = randf_range(30, 80)
		var angle = randf_range(-20, 20)
		# Left expansion
		spawn_particle(Vector2(-5, 42), Vector2(-dx, angle - 10), Color(0.65, 0.65, 0.68, 0.5), 0.5, randf_range(4.0, 8.0))
		# Right expansion
		spawn_particle(Vector2(5, 42), Vector2(dx, angle - 10), Color(0.65, 0.65, 0.68, 0.5), 0.5, randf_range(4.0, 8.0))

func _draw() -> void:
	# 1. Draw FX Particles (drawn relative to character position)
	for p in fx_particles:
		var ratio = p.life / p.life_max
		var draw_color = p.color
		draw_color.a = p.color.a * ratio
		draw_circle(p.pos, p.size * (0.4 + 0.6 * ratio), draw_color)

	# 2. Draw Shadow (changes scale based on character Y offset)
	var shadow_y = 45.0
	# Height is measured by local position offset relative to normal ground
	var current_height = -body_offset.y
	var shadow_scale = clamp(1.0 - (current_height / 150.0), 0.2, 1.0)
	var shadow_alpha = clamp(0.25 * shadow_scale, 0.0, 0.25)
	draw_ellipse(Vector2(0, shadow_y), 24.0 * shadow_scale, 4.0 * shadow_scale, Color(0, 0, 0, shadow_alpha))
	
	# Apply body scaling & rotation
	draw_set_transform(body_offset, body_rotation, body_scale)
	
	# 3. Classic Leather School Satchel Backpack with Pins (Matching the sheet)
	# Main brown backpack body
	draw_rect(Rect2(-26, -16, 14, 25), Color(0.48, 0.25, 0.1), true) 
	# Darker brown satchel flap
	draw_rect(Rect2(-27, -16, 15, 8), Color(0.28, 0.12, 0.05), true) 
	# Small pockets/belts on the satchel
	draw_line(Vector2(-23, -8), Vector2(-23, 6), Color(0.18, 0.08, 0.02), 2.0)
	draw_line(Vector2(-17, -8), Vector2(-17, 6), Color(0.18, 0.08, 0.02), 2.0)
	# Colorful pins/badges
	draw_circle(Vector2(-22, 2), 2.0, Color(0.85, 0.15, 0.15)) # Red pin
	draw_circle(Vector2(-16, 6), 2.0, Color(0.15, 0.5, 0.85)) # Blue pin
	draw_circle(Vector2(-20, 10), 2.0, Color(0.85, 0.75, 0.15)) # Yellow pin
	
	# 4. Plaid Pleated Skirt (Matching the sheet)
	var skirt_poly = PackedVector2Array([
		Vector2(-12, 10), Vector2(12, 10),
		Vector2(16, 21), Vector2(-16, 21)
	])
	draw_polygon(skirt_poly, [Color(0.22, 0.26, 0.35)]) # Slate blue base
	# Vertical pleat folds
	draw_line(Vector2(-8, 10), Vector2(-10, 21), Color(0.1, 0.12, 0.18), 1.5)
	draw_line(Vector2(-4, 10), Vector2(-5, 21), Color(0.1, 0.12, 0.18), 1.5)
	draw_line(Vector2(0, 10), Vector2(0, 21), Color(0.1, 0.12, 0.18), 1.5)
	draw_line(Vector2(4, 10), Vector2(5, 21), Color(0.1, 0.12, 0.18), 1.5)
	draw_line(Vector2(8, 10), Vector2(10, 21), Color(0.1, 0.12, 0.18), 1.5)
	# Horizontal plaid stripes
	draw_line(Vector2(-13, 14), Vector2(13, 14), Color(0.1, 0.12, 0.18, 0.4), 1.5)
	draw_line(Vector2(-15, 18), Vector2(15, 18), Color(0.1, 0.12, 0.18, 0.4), 1.5)
	
	# 5. Bare Legs & High Dark Socks (Matching the sheet)
	var draw_leg = func(start_joint: Vector2, end_joint: Vector2):
		var mid = start_joint.lerp(end_joint, 0.5)
		# Upper leg (skin)
		draw_line(start_joint, mid, Color(0.98, 0.82, 0.68), 7.0, true)
		# High school sock (dark grey)
		draw_line(mid, end_joint, Color(0.12, 0.12, 0.16), 7.0, true)
	
	draw_leg.call(Vector2(-6, 21), leg_left_pos)
	draw_leg.call(Vector2(6, 21), leg_right_pos)
	
	# Brown leather shoes (loafers)
	var draw_shoe = func(pos: Vector2):
		draw_rect(Rect2(pos.x - 4, pos.y - 4, 15, 8), Color(0.35, 0.2, 0.12), true) # loafer base
		draw_circle(pos + Vector2(2, -2), 3.0, Color(0.35, 0.2, 0.12)) # heel
	draw_shoe.call(leg_left_pos)
	draw_shoe.call(leg_right_pos)
	
	# 6. Torso (Blazer with tan sweater vest and red bow tie)
	draw_rect(Rect2(-12, -18, 24, 28), Color(0.15, 0.22, 0.3), true) # Slate navy blazer
	# Tan sweater vest peaking underneath
	draw_polygon(PackedVector2Array([Vector2(-5, -18), Vector2(5, -18), Vector2(0, -9)]), [Color(0.85, 0.75, 0.6)])
	# White shirt collar edges
	draw_polygon(PackedVector2Array([Vector2(-4, -18), Vector2(0, -14), Vector2(-1.5, -18)]), [Color(0.95, 0.95, 0.95)])
	draw_polygon(PackedVector2Array([Vector2(4, -18), Vector2(0, -14), Vector2(1.5, -18)]), [Color(0.95, 0.95, 0.95)])
	# Red Bow Tie/Ribbon
	draw_polygon(PackedVector2Array([Vector2(0, -14), Vector2(-4, -16), Vector2(-3, -12)]), [Color(0.85, 0.15, 0.15)]) # left wing
	draw_polygon(PackedVector2Array([Vector2(0, -14), Vector2(4, -16), Vector2(3, -12)]), [Color(0.85, 0.15, 0.15)]) # right wing
	draw_circle(Vector2(0, -14), 2.0, Color(0.75, 0.1, 0.1)) # center knot
	draw_line(Vector2(0, -14), Vector2(-2, -9), Color(0.85, 0.15, 0.15), 1.5) # left tail
	draw_line(Vector2(0, -14), Vector2(2, -9), Color(0.85, 0.15, 0.15), 1.5) # right tail
	
	# 7. Head & Messy Bob Hair (Matching the sheet)
	draw_circle(Vector2(0, -32), 14.0, Color(0.98, 0.82, 0.68)) # skin face
	
	# Black bob hair (length past ears)
	draw_circle(Vector2(0, -33), 15.5, Color(0.12, 0.12, 0.15)) # base back hair
	draw_rect(Rect2(-15, -34, 5, 13), Color(0.12, 0.12, 0.15), true) # left side bob
	draw_rect(Rect2(10, -34, 5, 13), Color(0.12, 0.12, 0.15), true) # right side bob
	# Spiky bob bangs/fringe
	draw_polygon(PackedVector2Array([
		Vector2(-14, -36), Vector2(14, -36), 
		Vector2(10, -22), Vector2(4, -28), 
		Vector2(0, -20), Vector2(-4, -28), 
		Vector2(-10, -22)
	]), [Color(0.12, 0.12, 0.15)])
	# Messy top spikes
	draw_polygon(PackedVector2Array([
		Vector2(-15, -35), Vector2(-8, -46), Vector2(-2, -37)
	]), [Color(0.12, 0.12, 0.15)])
	draw_polygon(PackedVector2Array([
		Vector2(-3, -37), Vector2(5, -47), Vector2(12, -36)
	]), [Color(0.12, 0.12, 0.15)])
	
	# Face features: Eye and brow
	draw_circle(Vector2(6, -33), 2.2, Color(0.08, 0.08, 0.08)) # Eye
	draw_line(Vector2(3, -37), Vector2(8, -37), Color(0.08, 0.08, 0.08), 1.5) # Eyebrow
	# Cheek band-aid
	draw_line(Vector2(4, -27), Vector2(8, -25), Color(0.92, 0.68, 0.48), 3.0)
	
	# 8. Arms
	var arm_pos := Vector2(10, 5)
	if current_state == "RUN":
		var swing = sin(Time.get_ticks_msec() * 0.015) * 10.0
		arm_pos = Vector2(8 + swing, 5 + abs(swing) * 0.4)
	elif current_state == "JUMP":
		arm_pos = Vector2(12, -16)
	elif current_state == "SLIDE":
		arm_pos = Vector2(18, 8)
	elif current_state == "DUCK":
		arm_pos = Vector2(8, 12) # Arm held down naturally while ducking
	elif current_state == "CLIMB":
		var swing = sin(Time.get_ticks_msec() * 0.025) * 12.0
		arm_pos = Vector2(6 + swing, -14 - abs(swing) * 0.2)
		
	# Draw blazer sleeve
	draw_line(Vector2(0, -8), arm_pos - (arm_pos - Vector2(0, -8)).normalized() * 4.0, Color(0.15, 0.22, 0.3), 8.0, true)
	# Draw skin hand
	draw_circle(arm_pos, 4.5, Color(0.98, 0.82, 0.68))
		
	# 10. Motion Blur Dash Lines on SLIDE (Close-Quarters Dash)
	if current_state == "SLIDE":
		var trail_offset = sin(Time.get_ticks_msec() * 0.02) * 6.0
		var trail_color = Color(0.2, 0.55, 0.85, 0.35)
		draw_line(Vector2(-35 + trail_offset, 15), Vector2(-15, 15), trail_color, 4.0)
		draw_line(Vector2(-45 + trail_offset, 25), Vector2(-20, 25), trail_color, 6.0)
		draw_line(Vector2(-40 + trail_offset, 5), Vector2(-18, 5), trail_color, 3.0)

func reset_pose() -> void:
	current_state = "IDLE"
	body_offset = Vector2.ZERO
	body_scale = Vector2.ONE
	body_rotation = 0.0
	leg_left_pos = Vector2(-8, 40)
	leg_right_pos = Vector2(8, 40)
	modulate = Color.WHITE
	queue_redraw()

func play_action(action_name: String, target_pos: Vector2, duration: float) -> Tween:
	current_state = action_name
	reset_pose()
	current_state = action_name
	
	match action_name:
		"RUN":
			var main_tween := create_tween().set_parallel(true)
			# Continuous forward lean
			main_tween.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			main_tween.tween_property(self, "body_rotation", deg_to_rad(12), 0.2)
			
			var bob_loops := int(max(1, duration / 0.14))
			var bob_tween := create_tween().set_loops(bob_loops)
			bob_tween.tween_property(self, "body_offset:y", -7.0, 0.07).set_trans(Tween.TRANS_SINE)
			bob_tween.tween_property(self, "body_offset:y", 0.0, 0.07).set_trans(Tween.TRANS_SINE)
			
			var leg_tween := create_tween().set_parallel(true).set_loops(bob_loops)
			leg_tween.tween_property(self, "leg_left_pos", Vector2(-16, 36), 0.07)
			leg_tween.tween_property(self, "leg_right_pos", Vector2(16, 42), 0.07)
			leg_tween.chain().tween_property(self, "leg_left_pos", Vector2(16, 42), 0.07)
			leg_tween.tween_property(self, "leg_right_pos", Vector2(-16, 36), 0.07)
			
			# Revert rotation at end
			var revert := create_tween()
			revert.tween_interval(duration - 0.15)
			revert.tween_property(self, "body_rotation", 0.0, 0.15)
			return main_tween
			
		"WAIT":
			# Stop and wait to observe timing/patterns (หยุดรอสังเกตจังหวะ)
			# First 70% of duration: stand still, bob head, look alert.
			# Last 30% of duration: run forward to the target_pos (across the obstacle!).
			var main_tween := create_tween()
			
			var wait_duration = duration * 0.7
			var dash_duration = duration * 0.3
			
			# Phase 1: Wait alertly
			var loops = int(max(1, wait_duration / 0.2))
			# Keep legs planted on the ground
			leg_left_pos = Vector2(-8, 40)
			leg_right_pos = Vector2(8, 40)
			
			# Squash & Stretch bobbing as if counting timing
			var bob_t = create_tween().set_loops(loops)
			bob_t.tween_property(self, "body_scale", Vector2(1.05, 0.92), 0.1).set_trans(Tween.TRANS_SINE)
			bob_t.tween_property(self, "body_scale", Vector2(0.95, 1.05), 0.1).set_trans(Tween.TRANS_SINE)
			
			# Wait interval
			main_tween.tween_interval(wait_duration)
			
			# Phase 2: Dash forward across the obstacle!
			main_tween.tween_callback(func():
				# Rotate body forward and stretch
				var dash_t = create_tween().set_parallel(true)
				dash_t.tween_property(self, "global_position", target_pos, dash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				dash_t.tween_property(self, "body_rotation", deg_to_rad(15), 0.05)
				dash_t.tween_property(self, "body_scale", Vector2(1.15, 0.9), 0.05)
				
				# Fast running leg motion
				var leg_t = create_tween().set_parallel(true).set_loops(3)
				leg_t.tween_property(self, "leg_left_pos", Vector2(-16, 36), 0.05)
				leg_t.tween_property(self, "leg_right_pos", Vector2(16, 42), 0.05)
				leg_t.chain().tween_property(self, "leg_left_pos", Vector2(16, 42), 0.05)
				leg_t.tween_property(self, "leg_right_pos", Vector2(-16, 36), 0.05)
			)
			main_tween.tween_interval(dash_duration)
			
			# Revert to normal
			var revert = create_tween().set_parallel(true)
			revert.tween_property(self, "body_rotation", 0.0, 0.1)
			revert.tween_property(self, "body_scale", Vector2.ONE, 0.1)
			revert.tween_property(self, "body_offset", Vector2.ZERO, 0.1)
			
			return main_tween
			
		"JUMP":
			SoundManager.play_sfx("jump")
			var jump_tween := create_tween().set_parallel(true)
			
			# X travel
			jump_tween.tween_property(self, "global_position:x", target_pos.x, duration).set_trans(Tween.TRANS_LINEAR)
			
			# Y gravity arc
			var start_y := global_position.y
			var apex_y := start_y - 120.0
			var y_curve := create_tween()
			y_curve.tween_property(self, "global_position:y", apex_y, duration * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			y_curve.tween_property(self, "global_position:y", target_pos.y, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			# Fluid rotations: tilt forward on ascent, tilt slightly down on descent
			var rot_curve := create_tween()
			rot_curve.tween_property(self, "body_rotation", deg_to_rad(18), duration * 0.4) # rise lean
			rot_curve.tween_property(self, "body_rotation", deg_to_rad(-10), duration * 0.5) # dive tilt
			rot_curve.tween_property(self, "body_rotation", 0.0, duration * 0.1) # land straighten
			
			# Squash & Stretch
			var scale_curve := create_tween()
			scale_curve.tween_property(self, "body_scale", Vector2(0.8, 1.35), duration * 0.15) # launch stretch
			scale_curve.tween_property(self, "body_scale", Vector2(1.0, 1.0), duration * 0.3)
			scale_curve.tween_property(self, "body_scale", Vector2(1.4, 0.55), duration * 0.25).set_trans(Tween.TRANS_SINE) # land squash
			scale_curve.tween_property(self, "body_scale", Vector2.ONE, duration * 0.3).set_trans(Tween.TRANS_ELASTIC) # rebound
			
			# Leg tuck
			leg_left_pos = Vector2(-4, 25)
			leg_right_pos = Vector2(4, 25)
			
			# Spawn impact dust at the landing point
			var trigger_dust := create_tween()
			trigger_dust.tween_interval(duration * 0.7)
			trigger_dust.tween_callback(spawn_impact_dust)
			
			return jump_tween
			
		"SLIDE":
			SoundManager.play_sfx("slide")
			var main_tween := create_tween().set_parallel(true)
			# Glide along the ground, leaning backward (negative angle) with legs forward
			main_tween.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			main_tween.tween_property(self, "body_scale", Vector2(1.15, 0.72), 0.15)
			main_tween.tween_property(self, "body_offset:y", 22.0, 0.15)
			main_tween.tween_property(self, "body_rotation", deg_to_rad(-28), 0.15) # Lean backward!
			
			leg_left_pos = Vector2(25, 38)  # Left leg forward
			leg_right_pos = Vector2(10, 42) # Right leg trailing/support
			
			# Recover at end with a small slide recovery pop
			var recover := create_tween().set_parallel(true)
			recover.tween_interval(duration - 0.18)
			recover.chain().tween_property(self, "body_scale", Vector2(0.9, 1.15), 0.1) # small stretch
			recover.tween_property(self, "body_offset:y", 0.0, 0.1)
			recover.tween_property(self, "body_rotation", 0.0, 0.1)
			recover.chain().tween_property(self, "body_scale", Vector2.ONE, 0.08) # settle
			return main_tween
			
		"DUCK":
			SoundManager.play_sfx("duck")
			var main_tween := create_tween().set_parallel(true)
			# Duck run - crouched body leaning slightly forward for momentum
			main_tween.tween_property(self, "global_position", target_pos, duration).set_trans(Tween.TRANS_SINE)
			main_tween.tween_property(self, "body_scale", Vector2(1.02, 0.68), 0.12)
			main_tween.tween_property(self, "body_offset:y", 16.0, 0.12)
			main_tween.tween_property(self, "body_rotation", deg_to_rad(14), 0.12) # Leaning forward
			
			# Leg shuffles - tight tuck close to the ground
			var duck_loops := int(max(1, duration / 0.12))
			var leg_tween := create_tween().set_parallel(true).set_loops(duck_loops)
			leg_tween.tween_property(self, "leg_left_pos", Vector2(-10, 32), 0.06)
			leg_tween.tween_property(self, "leg_right_pos", Vector2(8, 36), 0.06)
			leg_tween.chain().tween_property(self, "leg_left_pos", Vector2(8, 36), 0.06)
			leg_tween.tween_property(self, "leg_right_pos", Vector2(-10, 32), 0.06)
			
			var recover := create_tween().set_parallel(true)
			recover.tween_interval(duration - 0.15)
			recover.chain().tween_property(self, "body_scale", Vector2.ONE, 0.15)
			recover.tween_property(self, "body_offset:y", 0.0, 0.15)
			recover.tween_property(self, "body_rotation", 0.0, 0.15)
			return main_tween
			
		"CLIMB":
			SoundManager.play_sfx("climb")
			var path := create_tween()
			var start_pos := global_position
			
			# Run to rope (reach)
			path.tween_property(self, "global_position", Vector2(start_pos.x + 75, start_pos.y), duration * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			# Climb straight up rope (lift)
			path.tween_property(self, "global_position", Vector2(start_pos.x + 75, start_pos.y - 120), duration * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Drop down on the other side (vault)
			path.tween_property(self, "global_position", target_pos, duration * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			
			# Custom scale overrides during climbing phases
			var scale_curve := create_tween()
			scale_curve.tween_property(self, "body_scale", Vector2(1.0, 1.0), duration * 0.15)
			scale_curve.tween_property(self, "body_scale", Vector2(0.75, 1.45), duration * 0.55).set_trans(Tween.TRANS_SINE) # stretch on vertical climb
			scale_curve.tween_property(self, "body_scale", Vector2(1.4, 0.65), duration * 0.18).set_trans(Tween.TRANS_SINE) # land squash
			scale_curve.tween_property(self, "body_scale", Vector2.ONE, duration * 0.12)
			
			# Swing body rotation to simulate climbing force
			var rot_curve := create_tween()
			rot_curve.tween_property(self, "body_rotation", deg_to_rad(-18), duration * 0.25) # lean back to grab
			rot_curve.tween_property(self, "body_rotation", deg_to_rad(12), duration * 0.45) # swing legs as climbing
			rot_curve.tween_property(self, "body_rotation", 0.0, duration * 0.3) # straighten on drop
			
			# Animate climbing leg poses dynamically (alternating legs on vertical climb)
			var leg_tween := create_tween()
			# Phase 1: reach and hold rope
			leg_tween.tween_property(self, "leg_left_pos", Vector2(-4, 25), duration * 0.25)
			leg_tween.parallel().tween_property(self, "leg_right_pos", Vector2(4, 25), duration * 0.25)
			# Phase 2: cycle legs (scramble up)
			var climb_cycles := int(max(1, (duration * 0.45) / 0.12))
			var leg_cycle := create_tween().set_parallel(true).set_loops(climb_cycles)
			leg_cycle.tween_property(self, "leg_left_pos", Vector2(-6, 16), 0.06)
			leg_cycle.tween_property(self, "leg_right_pos", Vector2(6, 32), 0.06)
			leg_cycle.chain().tween_property(self, "leg_left_pos", Vector2(-6, 32), 0.06)
			leg_cycle.tween_property(self, "leg_right_pos", Vector2(6, 16), 0.06)
			# Phase 3: drop legs straight for landing
			var recover_legs := create_tween().set_parallel(true)
			recover_legs.tween_interval(duration * 0.7)
			recover_legs.chain().tween_property(self, "leg_left_pos", Vector2(-8, 40), duration * 0.3)
			recover_legs.parallel().tween_property(self, "leg_right_pos", Vector2(8, 40), duration * 0.3)
			
			# Impact dust at landing point
			var trigger_dust := create_tween()
			trigger_dust.tween_interval(duration * 0.8)
			trigger_dust.tween_callback(spawn_impact_dust)
			
			return path
			
	return create_tween()

func play_death(death_type: String) -> Tween:
	current_state = "DEATH"
	var death_tween = create_tween().set_parallel(true)
	
	match death_type:
		"PIT":
			# Plummets down, spins, and fades out
			death_tween.tween_property(self, "global_position:y", global_position.y + 120.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			death_tween.tween_property(self, "body_rotation", deg_to_rad(180), 0.55)
			death_tween.tween_property(self, "modulate:a", 0.0, 0.55)
			
		"SLAM":
			# Slam, bounce back, fall flat on back
			death_tween.tween_property(self, "global_position:x", global_position.x - 50.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			death_tween.tween_property(self, "global_position:y", GROUND_Y + 15.0, 0.35)
			death_tween.tween_property(self, "body_rotation", deg_to_rad(-90), 0.3)
			death_tween.tween_property(self, "body_scale", Vector2(1.3, 0.5), 0.3)
			
			var fade = create_tween()
			fade.tween_interval(0.35)
			fade.tween_property(self, "modulate:a", 0.0, 0.3)
			
		"CRUSH":
			# Shakes from structural rumble, gets crushed flat, turns stone grey, and dissolves
			var shake_loops := 6
			var shake := create_tween().set_loops(shake_loops)
			shake.tween_property(self, "body_offset:x", -5.0, 0.04)
			shake.tween_property(self, "body_offset:x", 5.0, 0.04)
			
			death_tween.tween_property(self, "modulate", Color(0.25, 0.25, 0.28), 0.2)
			death_tween.tween_property(self, "body_scale", Vector2(1.7, 0.22), 0.25).set_trans(Tween.TRANS_BOUNCE)
			death_tween.tween_property(self, "body_offset:y", 30.0, 0.25)
			
			var fade = create_tween()
			fade.tween_interval(0.3)
			fade.tween_property(self, "modulate:a", 0.0, 0.25)
			
	return death_tween
