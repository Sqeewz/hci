# level_graphics.gd - Environment rendering with stage-specific styles
extends Node2D

const CELL_WIDTH = 95.0
const START_X = 60.0
const GROUND_Y = 250.0

# Expose active obstacles dictionary (passed from game_stage.gd)
var active_obstacles := {}
var current_level := 1

# Particle systems
var dust_particles: Array = []
var spark_particles: Array = []
var gate_glow_angle := 0.0
var warning_glow_time := 0.0

func _ready() -> void:
	# Initialize ambient dust/ash particles
	for i in range(25):
		dust_particles.append({
			"pos": Vector2(randf_range(0, 1280), randf_range(20, 320)),
			"speed": randf_range(10, 30),
			"angle": randf_range(0, PI * 2),
			"size": randf_range(1.5, 3.5),
			"alpha": randf_range(0.15, 0.45)
		})
	
	# Initialize sparking positions
	for i in range(5):
		spark_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.ZERO,
			"life": 0.0
		})

func _process(delta: float) -> void:
	# 1. Update dust particles
	for p in dust_particles:
		p.angle += randf_range(-0.5, 0.5) * delta
		var dir = Vector2(cos(p.angle), sin(p.angle))
		p.pos += dir * p.speed * delta
		if p.pos.x < 0: p.pos.x = 1280
		if p.pos.x > 1280: p.pos.x = 0
		if p.pos.y < 0: p.pos.y = 350
		if p.pos.y > 350: p.pos.y = 0
		
	# Find if there is any steam or debris cell to anchor sparks
	var spark_cell := -1
	for cell in active_obstacles.keys():
		if "SLIDE" in active_obstacles[cell] or "STEAM" in active_obstacles[cell]:
			spark_cell = cell
			break
			
	# 2. Update sparks
	if spark_cell != -1:
		var spark_origin_x = START_X + spark_cell * CELL_WIDTH - 15
		for s in spark_particles:
			if s.life <= 0:
				if randf() < 0.15:
					s.pos = Vector2(spark_origin_x + randf_range(-10, 10), GROUND_Y - 75)
					s.vel = Vector2(randf_range(-60, 60), randf_range(-20, 150))
					s.life = randf_range(0.2, 0.5)
			else:
				s.pos += s.vel * delta
				s.vel.y += 120 * delta
				s.life -= delta
	else:
		for s in spark_particles:
			s.life = 0.0
			
	gate_glow_angle += 2.0 * delta
	warning_glow_time += 4.5 * delta
	
	queue_redraw()

func get_draw_width() -> float:
	return maxf(1600.0, get_viewport_rect().size.x + 300.0)

func get_theme_name() -> String:
	if current_level <= 8:
		return "SCHOOL"
	elif current_level <= 15:
		return "CITY"
	else:
		return "FOREST"

func _draw() -> void:
	var theme = get_theme_name()
	var w = get_draw_width()
	
	# Draw background sky & structures based on theme
	match theme:
		"SCHOOL":
			# Dark slate background
			draw_rect(Rect2(0, 0, w, 350), Color(0.06, 0.07, 0.1))
			
			# Class windows
			for i in range(6):
				var wx = 80 + i * 220
				draw_rect(Rect2(wx, 50, 80, 120), Color(0.03, 0.03, 0.05), true)
				# light ray shafts
				var light_pts = PackedVector2Array([
					Vector2(wx, 50), Vector2(wx + 80, 50),
					Vector2(wx + 180, 350), Vector2(wx + 20, 350)
				])
				draw_polygon(light_pts, [Color(0.25, 0.35, 0.5, 0.03)])
				# window frames
				draw_line(Vector2(wx + 40, 50), Vector2(wx + 40, 170), Color(0.12, 0.14, 0.18), 3.0)
				draw_line(Vector2(wx, 110), Vector2(wx + 80, 110), Color(0.12, 0.14, 0.18), 3.0)
				
			# Brick lines
			var brick_color = Color(0.15, 0.18, 0.25, 0.1)
			for r in range(7):
				var y = 20 + r * 45
				var shift = 25 if r % 2 == 0 else 0
				for c in range(15):
					draw_rect(Rect2(shift + c * 100, y, 60, 20), brick_color, false, 1.0)
					
		"CITY":
			# Post-apocalyptic sunset sky (orange/purple gradient)
			for y in range(0, 350, 10):
				var ratio = float(y) / 350.0
				var sky_color = Color(0.08, 0.05, 0.12).lerp(Color(0.24, 0.1, 0.08), ratio)
				draw_rect(Rect2(0, y, w, 10), sky_color, true)
				
			# Ruined skyscraper silhouettes
			var bld_color = Color(0.04, 0.03, 0.06)
			var buildings = [
				[50, 180, 260], [180, 100, 300], [280, 220, 200], [450, 140, 280],
				[580, 90, 320], [700, 240, 180], [820, 120, 290], [980, 200, 240],
				[1140, 220, 270], [1320, 150, 310]
			]
			for b in buildings:
				# building rect
				draw_rect(Rect2(b[0], 350 - b[2], b[1], b[2]), bld_color, true)
				# Draw simple dark window slots
				var cols = b[1] / 30
				var rows = b[2] / 40
				for c in range(1, cols):
					for r in range(1, rows):
						if randf() < 0.2: # Some glowing amber lights remaining in city
							draw_rect(Rect2(b[0] + c*30 - 5, 350 - b[2] + r*40 - 5, 10, 10), Color(0.8, 0.45, 0.15, 0.2), true)
							
		"FOREST":
			# Forest background (deep moss-green/black gradient)
			for y in range(0, 350, 10):
				var ratio = float(y) / 350.0
				var forest_sky = Color(0.02, 0.04, 0.03).lerp(Color(0.08, 0.12, 0.06), ratio)
				draw_rect(Rect2(0, y, w, 10), forest_sky, true)
				
			# Draw massive tree silhouettes and hanging branches
			var tree_color = Color(0.02, 0.03, 0.02)
			draw_circle(Vector2(200, -50), 300.0, tree_color) # Foliage left
			draw_circle(Vector2(1000, -50), 280.0, tree_color) # Foliage right
			draw_circle(Vector2(1300, -50), 280.0, tree_color) # Foliage far right
			
			# Tree trunks
			draw_rect(Rect2(50, 0, 60, 350), tree_color, true)
			draw_rect(Rect2(1050, 0, 70, 350), tree_color, true)
			draw_rect(Rect2(1280, 0, 80, 350), tree_color, true)
			
			# Hanging glowing moss/spores
			for i in range(8):
				var mx = 150 + i * 130 + sin(warning_glow_time + i) * 10
				var my = 40 + cos(warning_glow_time * 0.5 + i) * 15
				draw_line(Vector2(mx, 0), Vector2(mx, my), Color(0.1, 0.25, 0.15), 2.0)
				draw_circle(Vector2(mx, my), 4.0, Color(0.3, 0.7, 0.4, 0.4 + 0.2 * sin(warning_glow_time + i)))

	# 2. Draw Floor & Pit based on theme
	var pit_cell := -1
	for cell in active_obstacles.keys():
		if "JUMP" in active_obstacles[cell] or "PIT" in active_obstacles[cell]:
			pit_cell = cell
			break
			
	var gap_start = START_X + (pit_cell - 0.5) * CELL_WIDTH if pit_cell != -1 else w
	var gap_end = START_X + (pit_cell + 0.5) * CELL_WIDTH if pit_cell != -1 else w
	
	var floor_color = Color(0.14, 0.16, 0.22)
	var floor_line_color = Color(0.3, 0.45, 0.6, 0.6)
	
	match theme:
		"SCHOOL":
			floor_color = Color(0.14, 0.16, 0.22) # Gray tiles
			floor_line_color = Color(0.3, 0.45, 0.6, 0.6)
		"CITY":
			floor_color = Color(0.08, 0.08, 0.1) # Dark asphalt highway
			floor_line_color = Color(0.8, 0.45, 0.1, 0.7) # Glowing orange warning edge
		"FOREST":
			floor_color = Color(0.1, 0.08, 0.06) # Dark muddy soil
			floor_line_color = Color(0.2, 0.5, 0.25, 0.7) # Overgrown grass edge
			
	# Floor segment 1: Start to Pit
	draw_rect(Rect2(0, GROUND_Y + 40, gap_start, 110), floor_color, true)
	draw_line(Vector2(0, GROUND_Y + 40), Vector2(gap_start, GROUND_Y + 40), floor_line_color, 4.0)
	
	# Draw floor details (highway stripes, bricks, or grass leaves)
	if theme == "CITY":
		# Yellow dashes on asphalt
		for x in range(20, int(gap_start), 60):
			draw_line(Vector2(x, GROUND_Y + 75), Vector2(x + 25, GROUND_Y + 75), Color(0.8, 0.7, 0.1, 0.35), 4.0)
	elif theme == "FOREST":
		# Moss details
		for x in range(25, int(gap_start), 80):
			draw_circle(Vector2(x, GROUND_Y + 42), 3.0, Color(0.2, 0.45, 0.25, 0.6))
			draw_line(Vector2(x, GROUND_Y + 42), Vector2(x - 5, GROUND_Y + 32), Color(0.25, 0.55, 0.3, 0.7), 2.0)
			draw_line(Vector2(x, GROUND_Y + 42), Vector2(x + 4, GROUND_Y + 30), Color(0.25, 0.55, 0.3, 0.7), 1.5)
			
	# Pit Gap
	if pit_cell != -1:
		# Draw dark void in pit
		draw_rect(Rect2(gap_start, GROUND_Y + 40, gap_end - gap_start, 110), Color(0.02, 0.01, 0.02), true)
		
		# Bubble glow inside pit
		var pit_pulse = (sin(warning_glow_time) + 1.0) * 0.5
		
		match theme:
			"SCHOOL":
				# Acid puddle glow
				draw_rect(Rect2(gap_start, GROUND_Y + 60, gap_end - gap_start, 90), Color(0.2, 0.8, 0.3, 0.15 * pit_pulse), true)
				# Hazard spikes
				for j in range(3):
					var sx = gap_start + 10 + j * 28
					draw_polygon(PackedVector2Array([
						Vector2(sx, GROUND_Y + 110), Vector2(sx + 10, GROUND_Y + 60), Vector2(sx + 20, GROUND_Y + 110)
					]), [Color(0.25, 0.45, 0.3)])
			"CITY":
				# Deep sewage grid / metal spikes
				draw_rect(Rect2(gap_start, GROUND_Y + 60, gap_end - gap_start, 90), Color(0.8, 0.15, 0.1, 0.15 * pit_pulse), true)
				for j in range(3):
					var sx = gap_start + 10 + j * 28
					draw_polygon(PackedVector2Array([
						Vector2(sx, GROUND_Y + 110), Vector2(sx + 10, GROUND_Y + 50), Vector2(sx + 20, GROUND_Y + 110)
					]), [Color(0.4, 0.4, 0.45)])
			"FOREST":
				# Bramble / thorns pit
				draw_rect(Rect2(gap_start, GROUND_Y + 60, gap_end - gap_start, 90), Color(0.4, 0.25, 0.1, 0.15 * pit_pulse), true)
				for j in range(4):
					var sx = gap_start + 8 + j * 22
					# Thorns crossing
					draw_line(Vector2(sx, GROUND_Y + 110), Vector2(sx + 12, GROUND_Y + 55), Color(0.2, 0.15, 0.1), 3.0)
					draw_line(Vector2(sx + 12, GROUND_Y + 55), Vector2(sx + 8, GROUND_Y + 70), Color(0.25, 0.5, 0.25), 1.5)
					
	# Floor segment 2: After Pit
	if gap_end < w:
		draw_rect(Rect2(gap_end, GROUND_Y + 40, w - gap_end, 110), floor_color, true)
		draw_line(Vector2(gap_end, GROUND_Y + 40), Vector2(w, GROUND_Y + 40), floor_line_color, 4.0)
		if theme == "CITY":
			for x in range(int(gap_end) + 20, int(w), 60):
				draw_line(Vector2(x, GROUND_Y + 75), Vector2(x + 25, GROUND_Y + 75), Color(0.8, 0.7, 0.1, 0.35), 4.0)
		elif theme == "FOREST":
			for x in range(int(gap_end) + 25, int(w), 80):
				draw_circle(Vector2(x, GROUND_Y + 42), 3.0, Color(0.2, 0.45, 0.25, 0.6))
				draw_line(Vector2(x, GROUND_Y + 42), Vector2(x - 5, GROUND_Y + 32), Color(0.25, 0.55, 0.3, 0.7), 2.0)
				draw_line(Vector2(x, GROUND_Y + 42), Vector2(x + 4, GROUND_Y + 30), Color(0.25, 0.55, 0.3, 0.7), 1.5)

	# 3. Draw Checkpoint Dots
	for cell in range(12):
		var cx = START_X + cell * CELL_WIDTH
		if cell != pit_cell: 
			var is_obstacle = active_obstacles.has(cell)
			var dot_color = Color(0.9, 0.45, 0.1, 0.3) if is_obstacle else Color(0.3, 0.6, 0.9, 0.3)
			if theme == "FOREST":
				dot_color = Color(0.9, 0.3, 0.2, 0.3) if is_obstacle else Color(0.2, 0.8, 0.4, 0.3)
			draw_circle(Vector2(cx, GROUND_Y + 42), 6.0, dot_color)
			draw_circle(Vector2(cx, GROUND_Y + 42), 2.0, Color(1, 1, 1, 0.8))

	# 4. Obstacle Graphics
	for cell in active_obstacles.keys():
		var obs_x = START_X + cell * CELL_WIDTH
		var types = active_obstacles[cell]
		
		if "RUBBLE" in types:
			match theme:
				"SCHOOL":
					# School desks and chairs collapsed
					draw_polygon(PackedVector2Array([
						Vector2(obs_x - 30, GROUND_Y + 40), Vector2(obs_x - 20, GROUND_Y - 45),
						Vector2(obs_x + 20, GROUND_Y - 45), Vector2(obs_x + 30, GROUND_Y + 40)
					]), [Color(0.24, 0.18, 0.12)])
					# Desk surface
					draw_rect(Rect2(obs_x - 35, GROUND_Y - 45, 70, 10), Color(0.38, 0.28, 0.18), true)
					# Locker door hanging
					draw_rect(Rect2(obs_x - 15, GROUND_Y - 35, 30, 60), Color(0.35, 0.38, 0.45), true)
					draw_rect(Rect2(obs_x - 15, GROUND_Y - 35, 30, 60), Color(0.5, 0.55, 0.6), false, 2.0)
					
				"CITY":
					# High-voltage concrete barrier or collapsed girder
					draw_polygon(PackedVector2Array([
						Vector2(obs_x - 40, GROUND_Y + 40), Vector2(obs_x - 15, GROUND_Y - 55),
						Vector2(obs_x + 15, GROUND_Y - 55), Vector2(obs_x + 40, GROUND_Y + 40)
					]), [Color(0.25, 0.25, 0.28)])
					# Warning Stripe Ribbon
					var tape_color = Color(0.9, 0.75, 0.1)
					var tape_dark = Color(0.15, 0.15, 0.15)
					draw_rect(Rect2(obs_x - 45, GROUND_Y - 70, 90, 16), tape_color, true)
					for s in range(5):
						var sx = obs_x - 45 + s * 18
						draw_polygon(PackedVector2Array([
							Vector2(sx, GROUND_Y - 70), Vector2(sx + 8, GROUND_Y - 70),
							Vector2(sx + 16, GROUND_Y - 54), Vector2(sx + 8, GROUND_Y - 54)
						]), [tape_dark])
						
				"FOREST":
					# Massive fallen tree log blocking path
					draw_circle(Vector2(obs_x, GROUND_Y + 10), 30.0, Color(0.22, 0.14, 0.08))
					# Wood rings inside
					draw_circle(Vector2(obs_x, GROUND_Y + 10), 22.0, Color(0.38, 0.28, 0.18))
					draw_circle(Vector2(obs_x, GROUND_Y + 10), 12.0, Color(0.48, 0.38, 0.24))
					# Bark outer log rect
					draw_rect(Rect2(obs_x - 40, GROUND_Y - 10, 80, 50), Color(0.18, 0.12, 0.08), true)
					# Moss on top
					draw_rect(Rect2(obs_x - 42, GROUND_Y - 15, 84, 8), Color(0.2, 0.5, 0.25), true)
					
			# Floating LOW indicator
			draw_rect(Rect2(obs_x - 30, GROUND_Y - 110, 60, 20), Color(0.12, 0.1, 0.05), true)
			draw_rect(Rect2(obs_x - 30, GROUND_Y - 110, 60, 20), Color(0.9, 0.75, 0.15, 0.8 + 0.2 * sin(warning_glow_time * 6.0)), false, 1.5)
			var yellow_c = Color(0.9, 0.75, 0.15)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 105), Vector2(obs_x - 18, GROUND_Y - 95), yellow_c, 2.0)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 95), Vector2(obs_x - 12, GROUND_Y - 95), yellow_c, 2.0)
			draw_rect(Rect2(obs_x - 7, GROUND_Y - 105, 12, 10), yellow_c, false, 2.0)
			draw_line(Vector2(obs_x + 9, GROUND_Y - 105), Vector2(obs_x + 11, GROUND_Y - 95), yellow_c, 2.0)
			draw_line(Vector2(obs_x + 11, GROUND_Y - 95), Vector2(obs_x + 15, GROUND_Y - 95), yellow_c, 2.0)
			draw_line(Vector2(obs_x + 15, GROUND_Y - 95), Vector2(obs_x + 17, GROUND_Y - 105), yellow_c, 2.0)
			
		elif "STEAM" in types:
			match theme:
				"SCHOOL":
					# School wall radiator with broken valve venting steam
					draw_rect(Rect2(obs_x - 20, GROUND_Y - 90, 40, 60), Color(0.3, 0.33, 0.36), true)
					for r in range(6):
						draw_rect(Rect2(obs_x - 18 + r * 6, GROUND_Y - 86, 4, 52), Color(0.18, 0.2, 0.22), true)
					draw_rect(Rect2(obs_x - 25, GROUND_Y - 40, 50, 8), Color(0.4, 0.45, 0.5), true)
					
				"CITY":
					# Street hazard gas/steam metal pipeline
					draw_rect(Rect2(obs_x - 12, 0, 24, 150), Color(0.2, 0.22, 0.25), true)
					draw_rect(Rect2(obs_x - 14, 148, 28, 12), Color(0.3, 0.35, 0.4), true) # nozzle
					draw_circle(Vector2(obs_x, 130), 5.0, Color(0.9, 0.15, 0.1))
					
				"FOREST":
					# Giant purple hazard spore geyser plant
					draw_polygon(PackedVector2Array([
						Vector2(obs_x - 25, GROUND_Y + 40), Vector2(obs_x - 10, GROUND_Y - 30),
						Vector2(obs_x + 10, GROUND_Y - 30), Vector2(obs_x + 25, GROUND_Y + 40)
					]), [Color(0.25, 0.1, 0.35)])
					# Spore bulb
					draw_circle(Vector2(obs_x, GROUND_Y - 35), 18.0, Color(0.45, 0.15, 0.55))
					draw_circle(Vector2(obs_x, GROUND_Y - 35), 10.0, Color(0.7, 0.3, 0.8))
					
			# Venting particle animations (whitish-blue for school/city, yellow-green for forest)
			var steam_alpha = (sin(warning_glow_time * 12.0) + 1.0) * 0.5
			var steam_color = Color(0.85, 0.92, 1.0, 0.25 + 0.15 * steam_alpha)
			if theme == "FOREST":
				steam_color = Color(0.7, 0.85, 0.2, 0.3 + 0.15 * steam_alpha)
				
			for k in range(5):
				var sx = obs_x - 10 + k * 5 + sin(warning_glow_time * 20.0 + k) * 3
				if theme == "FOREST":
					draw_line(Vector2(sx, GROUND_Y - 50), Vector2(sx + sin(k)*12, GROUND_Y + 25), steam_color, 4.0)
				else:
					draw_line(Vector2(sx, 160), Vector2(sx + sin(k)*8, GROUND_Y + 15), steam_color, 4.0)
					
			# Floating HOT label
			draw_rect(Rect2(obs_x - 30, GROUND_Y - 50, 60, 20), Color(0.12, 0.05, 0.05), true)
			draw_rect(Rect2(obs_x - 30, GROUND_Y - 50, 60, 20), Color(1.0, 0.4, 0.1, 0.8 + 0.2 * sin(warning_glow_time * 8.0)), false, 1.5)
			var hot_c = Color(1.0, 0.45, 0.15)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 45), Vector2(obs_x - 18, GROUND_Y - 35), hot_c, 2.0)
			draw_line(Vector2(obs_x - 12, GROUND_Y - 45), Vector2(obs_x - 12, GROUND_Y - 35), hot_c, 2.0)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 40), Vector2(obs_x - 12, GROUND_Y - 40), hot_c, 2.0)
			draw_rect(Rect2(obs_x - 6, GROUND_Y - 45, 12, 10), hot_c, false, 2.0)
			draw_line(Vector2(obs_x + 10, GROUND_Y - 45), Vector2(obs_x + 20, GROUND_Y - 45), hot_c, 2.0)
			draw_line(Vector2(obs_x + 15, GROUND_Y - 45), Vector2(obs_x + 15, GROUND_Y - 35), hot_c, 2.0)
			
		elif "CLIMB" in types:
			# Concrete ledge base structure
			var landing_cell = cell + 1
			var lx_start = obs_x
			var lx_end = 1200.0
			if landing_cell < 11:
				lx_end = START_X + (landing_cell + 0.5) * CELL_WIDTH
				
			draw_rect(Rect2(lx_start, GROUND_Y - 40, lx_end - lx_start, 150), Color(0.12, 0.14, 0.18), true)
			draw_line(Vector2(lx_start, GROUND_Y - 40), Vector2(lx_end, GROUND_Y - 40), Color(0.3, 0.6, 0.9, 0.8), 3.0)
			draw_line(Vector2(lx_start, GROUND_Y - 40), Vector2(lx_start, GROUND_Y + 150), Color(0.3, 0.6, 0.9, 0.8), 3.0)
			
			match theme:
				"SCHOOL":
					# School climbing cargo net
					draw_rect(Rect2(obs_x - 30, 40, 60, 12), Color(0.2, 0.22, 0.25), true)
					var rope_color = Color(0.7, 0.55, 0.35)
					for rx in range(-20, 30, 13):
						draw_line(Vector2(obs_x + rx, 48), Vector2(obs_x + rx + sin(rx)*2, GROUND_Y + 40), rope_color, 2.5)
					for ry in range(60, int(GROUND_Y + 40), 30):
						draw_line(Vector2(obs_x - 22, ry), Vector2(obs_x + 22, ry), rope_color, 2.0)
						
				"CITY":
					# Metal scaffolding tower & platforms
					draw_line(Vector2(obs_x - 22, 40), Vector2(obs_x - 22, GROUND_Y + 40), Color(0.45, 0.48, 0.52), 4.0)
					draw_line(Vector2(obs_x + 22, 40), Vector2(obs_x + 22, GROUND_Y + 40), Color(0.45, 0.48, 0.52), 4.0)
					# Cross metal braces
					for ry in range(40, int(GROUND_Y + 40), 40):
						draw_line(Vector2(obs_x - 22, ry), Vector2(obs_x + 22, ry + 30), Color(0.35, 0.38, 0.42), 2.5)
						draw_line(Vector2(obs_x - 22, ry + 30), Vector2(obs_x + 22, ry), Color(0.35, 0.38, 0.42), 2.5)
						
				"FOREST":
					# Hanging forest vines & roots
					var vine_color = Color(0.18, 0.45, 0.22)
					var leaf_color = Color(0.28, 0.6, 0.32)
					for rx in range(-15, 20, 15):
						var points = PackedVector2Array()
						for y_step in range(60, int(GROUND_Y + 40), 20):
							var wave = sin(y_step * 0.05 + rx + warning_glow_time) * 5
							points.append(Vector2(obs_x + rx + wave, y_step))
						for p_idx in range(points.size() - 1):
							draw_line(points[p_idx], points[p_idx+1], vine_color, 2.5)
						for pt in points:
							draw_circle(pt + Vector2(-3, -2), 4.0, leaf_color)
							draw_circle(pt + Vector2(3, 1), 3.0, vine_color)
							
		elif "WAIT" in types:
			match theme:
				"SCHOOL":
					# School corridor themed swinging pendulum blade
					var swing_angle = sin(warning_glow_time * 4.0) * deg_to_rad(65)
					var arm_len = 170.0
					var blade_pos = Vector2(obs_x, 40) + Vector2(sin(swing_angle), cos(swing_angle)) * arm_len
					# Draw ceiling mounting pivot
					draw_rect(Rect2(obs_x - 12, 35, 24, 10), Color(0.2, 0.22, 0.25), true)
					# Pendulum rod
					draw_line(Vector2(obs_x, 40), blade_pos, Color(0.45, 0.48, 0.52), 4.0)
					# Metallic curved half-moon blade
					draw_circle(blade_pos, 16.0, Color(0.65, 0.68, 0.72))
					draw_line(blade_pos, blade_pos + Vector2(cos(swing_angle + PI/2)*20, sin(swing_angle + PI/2)*20), Color(0.85, 0.9, 0.95), 3.0)
					draw_line(blade_pos, blade_pos - Vector2(cos(swing_angle + PI/2)*20, sin(swing_angle + PI/2)*20), Color(0.85, 0.9, 0.95), 3.0)
					
				"CITY":
					# Industrial timed hydraulic press
					var bounce = abs(sin(warning_glow_time * 3.0))
					var press_bottom_y = 100 + bounce * 140
					# Piston shaft
					draw_rect(Rect2(obs_x - 8, 0, 16, press_bottom_y - 30), Color(0.3, 0.32, 0.35), true)
					# Crushing head
					draw_rect(Rect2(obs_x - 30, press_bottom_y - 30, 60, 30), Color(0.18, 0.2, 0.22), true)
					# Yellow/black hazard stripes
					draw_line(Vector2(obs_x - 30, press_bottom_y - 15), Vector2(obs_x + 30, press_bottom_y - 15), Color(0.9, 0.75, 0.15), 4.0)
					
				"FOREST":
					# Overgrown swinging spiked log
					var forest_swing = sin(warning_glow_time * 3.5) * deg_to_rad(55)
					var vine_len = 160.0
					var log_pos = Vector2(obs_x, 30) + Vector2(sin(forest_swing), cos(forest_swing)) * vine_len
					# Rope/vine hanging
					draw_line(Vector2(obs_x, 30), log_pos, Color(0.18, 0.45, 0.22), 3.0)
					# Spiked log cylinder
					draw_circle(log_pos, 20.0, Color(0.38, 0.25, 0.15))
					# 6 spikes sticking out
					for sp in range(6):
						var a = forest_swing + sp * (PI / 3)
						draw_line(log_pos, log_pos + Vector2(cos(a), sin(a)) * 32.0, Color(0.7, 0.72, 0.75), 2.5)
							
			# Floating WAIT Sign
			draw_rect(Rect2(obs_x - 35, GROUND_Y - 95, 70, 20), Color(0.15, 0.1, 0.05), true)
			draw_rect(Rect2(obs_x - 35, GROUND_Y - 95, 70, 20), Color(1.0, 0.5, 0.1, 0.8 + 0.2 * sin(warning_glow_time * 8.0)), false, 1.5)
			var neon_c = Color(1.0, 0.55, 0.15)
			# W
			draw_line(Vector2(obs_x - 22, GROUND_Y - 90), Vector2(obs_x - 18, GROUND_Y - 80), neon_c, 2.0)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 80), Vector2(obs_x - 15, GROUND_Y - 85), neon_c, 2.0)
			draw_line(Vector2(obs_x - 15, GROUND_Y - 85), Vector2(obs_x - 12, GROUND_Y - 80), neon_c, 2.0)
			draw_line(Vector2(obs_x - 12, GROUND_Y - 80), Vector2(obs_x - 8, GROUND_Y - 90), neon_c, 2.0)
			# A
			draw_line(Vector2(obs_x - 4, GROUND_Y - 80), Vector2(obs_x - 1, GROUND_Y - 90), neon_c, 2.0)
			draw_line(Vector2(obs_x - 1, GROUND_Y - 90), Vector2(obs_x + 2, GROUND_Y - 80), neon_c, 2.0)
			draw_line(Vector2(obs_x - 3, GROUND_Y - 85), Vector2(obs_x + 1, GROUND_Y - 85), neon_c, 2.0)
			# I
			draw_line(Vector2(obs_x + 6, GROUND_Y - 90), Vector2(obs_x + 6, GROUND_Y - 80), neon_c, 2.0)
			draw_line(Vector2(obs_x + 4, GROUND_Y - 90), Vector2(obs_x + 8, GROUND_Y - 90), neon_c, 2.0)
			draw_line(Vector2(obs_x + 4, GROUND_Y - 80), Vector2(obs_x + 8, GROUND_Y - 80), neon_c, 2.0)
			# T
			draw_line(Vector2(obs_x + 11, GROUND_Y - 90), Vector2(obs_x + 21, GROUND_Y - 90), neon_c, 2.0)
			draw_line(Vector2(obs_x + 16, GROUND_Y - 90), Vector2(obs_x + 16, GROUND_Y - 80), neon_c, 2.0)
			
		elif "DRONE" in types:
			var drone_y = 65 + sin(warning_glow_time * 4.0) * 8
			match theme:
				"SCHOOL":
					# School red alarm siren drone
					draw_line(Vector2(obs_x, 0), Vector2(obs_x, drone_y), Color(0.12, 0.12, 0.15), 2.5)
					draw_circle(Vector2(obs_x, drone_y), 15.0, Color(0.3, 0.1, 0.1))
					draw_circle(Vector2(obs_x, drone_y), 15.0, Color(0.7, 0.15, 0.15), false, 2.0)
					draw_circle(Vector2(obs_x, drone_y), 5.0, Color(1, 0.15, 0.15))
					
				"CITY":
					# Police security scanner quadcopter drone
					draw_line(Vector2(obs_x, 0), Vector2(obs_x, drone_y), Color(0.2, 0.22, 0.25), 2.0)
					draw_rect(Rect2(obs_x - 22, drone_y - 4, 44, 8), Color(0.15, 0.18, 0.22), true)
					draw_circle(Vector2(obs_x, drone_y), 11.0, Color(0.1, 0.12, 0.15))
					# Twin propellers
					draw_line(Vector2(obs_x - 22, drone_y - 4), Vector2(obs_x - 22 + cos(warning_glow_time*20)*12, drone_y - 4), Color(0.4, 0.45, 0.5), 1.5)
					draw_line(Vector2(obs_x + 22, drone_y - 4), Vector2(obs_x + 22 + sin(warning_glow_time*20)*12, drone_y - 4), Color(0.4, 0.45, 0.5), 1.5)
					draw_circle(Vector2(obs_x, drone_y + 4), 3.5, Color(0.2, 0.5, 1.0)) # blue eye
					
				"FOREST":
					# Ruined military drone overgrown in vines
					draw_line(Vector2(obs_x, 0), Vector2(obs_x, drone_y), Color(0.15, 0.18, 0.12), 2.0)
					draw_circle(Vector2(obs_x, drone_y), 14.0, Color(0.18, 0.22, 0.15))
					draw_circle(Vector2(obs_x, drone_y), 14.0, Color(0.28, 0.35, 0.25), false, 2.0)
					# Ivy leaf details hanging off the drone
					draw_circle(Vector2(obs_x - 10, drone_y + 8), 4.0, Color(0.1, 0.35, 0.15))
					draw_circle(Vector2(obs_x + 10, drone_y + 5), 3.0, Color(0.15, 0.4, 0.2))
					draw_circle(Vector2(obs_x, drone_y), 4.0, Color(1, 0.4, 0.1)) # orange warning eye
					
			# Laser line
			var scan_laser_y = GROUND_Y - 12.0
			var laser_color = Color(1, 0.15, 0.15, 0.75 + 0.25 * sin(warning_glow_time * 15.0))
			if theme == "FOREST":
				laser_color = Color(1, 0.5, 0.1, 0.75 + 0.25 * sin(warning_glow_time * 15.0))
				
			draw_line(Vector2(obs_x - 60, scan_laser_y), Vector2(obs_x + 60, scan_laser_y), laser_color, 3.0)
			draw_line(Vector2(obs_x, drone_y + 4), Vector2(obs_x, scan_laser_y), laser_color * 0.2, 1.0)
			
			# Floating LOW indicator
			draw_rect(Rect2(obs_x - 30, GROUND_Y - 80, 60, 20), Color(0.12, 0.05, 0.05), true)
			draw_rect(Rect2(obs_x - 30, GROUND_Y - 80, 60, 20), laser_color, false, 1.5)
			var red_c = Color(1.0, 0.2, 0.2) if theme != "FOREST" else Color(1.0, 0.5, 0.15)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 75), Vector2(obs_x - 18, GROUND_Y - 65), red_c, 2.0)
			draw_line(Vector2(obs_x - 18, GROUND_Y - 65), Vector2(obs_x - 12, GROUND_Y - 65), red_c, 2.0)
			draw_rect(Rect2(obs_x - 7, GROUND_Y - 75, 12, 10), red_c, false, 2.0)
			draw_line(Vector2(obs_x + 9, GROUND_Y - 75), Vector2(obs_x + 11, GROUND_Y - 65), red_c, 2.0)
			draw_line(Vector2(obs_x + 11, GROUND_Y - 65), Vector2(obs_x + 15, GROUND_Y - 65), red_c, 2.0)
			draw_line(Vector2(obs_x + 15, GROUND_Y - 65), Vector2(obs_x + 17, GROUND_Y - 75), red_c, 2.0)

	# 5. Checkpoints: Start and End Gates
	# Start flag
	draw_line(Vector2(START_X - 30, GROUND_Y + 40), Vector2(START_X - 30, GROUND_Y - 50), Color(0.4, 0.45, 0.5), 4.0)
	draw_rect(Rect2(START_X - 55, GROUND_Y - 45, 50, 20), Color(0.1, 0.2, 0.35, 0.8), true)
	draw_rect(Rect2(START_X - 55, GROUND_Y - 45, 50, 20), Color(0.3, 0.6, 0.9), false, 1.5)
	
	# End Gate / Cave / Off-screen
	var gate_x = START_X + 11 * CELL_WIDTH
	var gate_y_offset = -80.0 if (active_obstacles.has(10) and "CLIMB" in active_obstacles[10]) else 0.0
	var gate_base_y = GROUND_Y + gate_y_offset
	
	match theme:
		"SCHOOL":
			# Draw standard futuristic security metal gate
			var pulse_sin = sin(gate_glow_angle)
			var beam_width = 110.0 + pulse_sin * 12.0
			var beam_pts = PackedVector2Array([
				Vector2(gate_x - 20, gate_base_y - 80), Vector2(gate_x + 20, gate_base_y - 80),
				Vector2(gate_x + beam_width * 0.7, gate_base_y + 110), Vector2(gate_x - beam_width * 0.7, gate_base_y + 110)
			])
			draw_polygon(beam_pts, [Color(0.2, 0.85, 0.45, 0.06 + pulse_sin * 0.02)])
			
			draw_rect(Rect2(gate_x - 25, gate_base_y - 80, 50, 120), Color(0.2, 0.22, 0.25), false, 5.0)
			draw_rect(Rect2(gate_x - 22, gate_base_y - 77, 44, 117), Color(0.3, 0.85, 0.5, 0.35), true)
			draw_rect(Rect2(gate_x - 20, gate_base_y - 95, 40, 14), Color(0.08, 0.35, 0.18, 0.9), true)
			draw_rect(Rect2(gate_x - 20, gate_base_y - 95, 40, 14), Color(0.4, 0.9, 0.55), false, 1.5)
		"CITY":
			# No gate drawn - character runs off the map!
			pass
		"FOREST":
			# Draw a dark rocky cave entrance
			# Inner dark void
			var cave_inner = PackedVector2Array([
				Vector2(gate_x - 35, gate_base_y + 40),
				Vector2(gate_x - 30, gate_base_y - 30),
				Vector2(gate_x - 15, gate_base_y - 60),
				Vector2(gate_x + 15, gate_base_y - 60),
				Vector2(gate_x + 30, gate_base_y - 30),
				Vector2(gate_x + 35, gate_base_y + 40)
			])
			draw_polygon(cave_inner, [Color(0.02, 0.02, 0.03)]) # black void
			
			# Outer mossy rocks
			var rock_left = PackedVector2Array([
				Vector2(gate_x - 48, gate_base_y + 40),
				Vector2(gate_x - 42, gate_base_y - 25),
				Vector2(gate_x - 25, gate_base_y - 70),
				Vector2(gate_x - 10, gate_base_y - 70),
				Vector2(gate_x - 15, gate_base_y - 50),
				Vector2(gate_x - 30, gate_base_y - 20),
				Vector2(gate_x - 35, gate_base_y + 40)
			])
			draw_polygon(rock_left, [Color(0.12, 0.14, 0.12)])
			
			var rock_right = PackedVector2Array([
				Vector2(gate_x + 35, gate_base_y + 40),
				Vector2(gate_x + 30, gate_base_y - 20),
				Vector2(gate_x + 15, gate_base_y - 50),
				Vector2(gate_x + 10, gate_base_y - 70),
				Vector2(gate_x + 25, gate_base_y - 70),
				Vector2(gate_x + 42, gate_base_y - 25),
				Vector2(gate_x + 48, gate_base_y + 40)
			])
			draw_polygon(rock_right, [Color(0.12, 0.14, 0.12)])
			
			var rock_top = PackedVector2Array([
				Vector2(gate_x - 38, gate_base_y - 65),
				Vector2(gate_x - 20, gate_base_y - 78),
				Vector2(gate_x + 20, gate_base_y - 78),
				Vector2(gate_x + 38, gate_base_y - 65),
				Vector2(gate_x + 20, gate_base_y - 55),
				Vector2(gate_x - 20, gate_base_y - 55)
			])
			draw_polygon(rock_top, [Color(0.16, 0.18, 0.15)])
			
			# Hanging moss/vines
			draw_line(Vector2(gate_x - 20, gate_base_y - 60), Vector2(gate_x - 20, gate_base_y - 20), Color(0.2, 0.45, 0.25), 2.5)
			draw_circle(Vector2(gate_x - 20, gate_base_y - 20), 3.0, Color(0.25, 0.55, 0.3))
			draw_line(Vector2(gate_x + 18, gate_base_y - 60), Vector2(gate_x + 18, gate_base_y - 30), Color(0.2, 0.45, 0.25), 2.0)
			draw_circle(Vector2(gate_x + 18, gate_base_y - 30), 2.5, Color(0.25, 0.55, 0.3))

	# 6. Sparks
	for s in spark_particles:
		if s.life > 0:
			var size = s.life * 4.0
			draw_circle(s.pos, size, Color(1.0, 0.6 + randf() * 0.4, 0.2, s.life * 2.0))

	# 7. Floating dust/ash/leaf particles
	for p in dust_particles:
		var p_color = Color(0.9, 0.95, 1.0, p.alpha) # white dust
		if theme == "CITY":
			p_color = Color(0.7, 0.5, 0.4, p.alpha) # orange ash
		elif theme == "FOREST":
			p_color = Color(0.3, 0.65, 0.35, p.alpha) # green spores / leaves
		draw_circle(p.pos, p.size, p_color)
