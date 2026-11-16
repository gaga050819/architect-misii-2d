extends Node2D

var anim_type: String = "none"
var anim_time: float = 0.0
var anim_duration: float = 3.0

var origin_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var particles: Array = []
var radio_waves: Array = []
var drill_debris: Array = []
var scoop_soil: Array = []
var micro_grid: Array = []
var gpr_pulses: Array = []

func start_laser(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "laser"
	anim_time = 0.0
	anim_duration = 3.2
	origin_pos = p_from
	target_pos = p_to
	particles.clear()
	for i in range(32):
		var ang = randf_range(-PI * 0.90, -PI * 0.10)
		var spd = randf_range(50.0, 260.0)
		particles.append({
			"pos": target_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"life": randf_range(0.3, 0.95),
			"max_life": 0.95,
			"col": Color(randf_range(0.9, 1.0), randf_range(0.5, 0.95), randf_range(0.1, 0.3))
		})
	queue_redraw()

func start_drill(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "drill"
	anim_time = 0.0
	anim_duration = 3.8
	origin_pos = p_from
	target_pos = p_to
	particles.clear()
	drill_debris.clear()
	for i in range(40):
		var ang = randf_range(-PI * 0.98, -PI * 0.02)
		var spd = randf_range(35.0, 190.0)
		particles.append({
			"pos": target_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"life": randf_range(0.5, 1.4),
			"col": Color(randf_range(0.65, 0.90), randf_range(0.52, 0.72), randf_range(0.35, 0.55))
		})
	for i in range(12):
		drill_debris.append({
			"x": target_pos.x + randf_range(-22.0, 22.0),
			"y": target_pos.y + randf_range(-3.0, 3.0),
			"r": randf_range(2.0, 5.5),
			"col": Color(randf_range(0.48, 0.75), randf_range(0.38, 0.58), 0.28)
		})
	queue_redraw()

func start_scoop(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "scoop"
	anim_time = 0.0
	anim_duration = 3.6
	origin_pos = p_from
	target_pos = p_to
	scoop_soil.clear()
	for i in range(18):
		scoop_soil.append({
			"x": target_pos.x + randf_range(-14.0, 14.0),
			"y": target_pos.y + randf_range(-4.0, 4.0),
			"r": randf_range(1.8, 4.5),
			"col": Color(randf_range(0.55, 0.78), randf_range(0.38, 0.58), randf_range(0.22, 0.36))
		})
	queue_redraw()

func start_orbital_scan(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "scan"
	anim_time = 0.0
	anim_duration = 3.2
	origin_pos = p_from
	target_pos = p_to
	queue_redraw()

func start_microscopic(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "micro"
	anim_time = 0.0
	anim_duration = 3.6
	origin_pos = p_from
	target_pos = p_to
	micro_grid.clear()
	for gy in range(5):
		for gx in range(5):
			micro_grid.append({
				"x": gx, "y": gy,
				"val": randf(),
				"phase": randf_range(0.0, TAU)
			})
	queue_redraw()

func start_gpr(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "gpr"
	anim_time = 0.0
	anim_duration = 3.4
	origin_pos = p_from
	target_pos = p_to
	gpr_pulses.clear()
	for i in range(4):
		gpr_pulses.append({
			"offset": i * 0.45,
			"max_depth": 65.0
		})
	queue_redraw()

func start_antenna(p_pos: Vector2) -> void:
	anim_type = "antenna"
	anim_time = 0.0
	anim_duration = 3.0
	origin_pos = p_pos
	radio_waves.clear()
	for i in range(5):
		radio_waves.append({
			"rad": 15.0 + i * 20.0,
			"max_rad": 155.0,
			"speed": 72.0,
			"offset": i * 0.38
		})
	queue_redraw()

func _process(delta: float) -> void:
	if anim_type == "none":
		return

	anim_time += delta
	if anim_type == "laser" or anim_type == "drill":
		for p in particles:
			p["life"] -= delta
			p["pos"] += p["vel"] * delta
			p["vel"].y += 200.0 * delta
			p["vel"].x *= 0.97

	if anim_time > anim_duration:
		anim_type = "none"

	queue_redraw()

func _draw() -> void:
	if anim_type == "none":
		return

	match anim_type:
		"laser":
			draw_laser_sequence()
		"drill":
			draw_drill_sequence()
		"scoop":
			draw_scoop_sequence()
		"scan":
			draw_scan_sequence()
		"micro":
			draw_micro_sequence()
		"gpr":
			draw_gpr_sequence()
		"antenna":
			draw_antenna_sequence()

func draw_laser_sequence() -> void:
	var t = anim_time
	var dur = anim_duration
	var glow_pulse = 0.65 + sin(t * 52.0) * 0.35
	var beam_alpha = 1.0
	if t > dur - 0.5:
		beam_alpha = clamp((dur - t) / 0.5, 0.0, 1.0)

	draw_line(origin_pos, target_pos, Color(0.1, 0.5, 1.0, 0.18 * glow_pulse * beam_alpha), 14.0)
	draw_line(origin_pos, target_pos, Color(0.3, 0.75, 1.0, 0.65 * glow_pulse * beam_alpha), 5.5)
	draw_line(origin_pos, target_pos, Color(0.75, 0.95, 1.0, 0.92 * beam_alpha), 2.0)
	draw_line(origin_pos, target_pos, Color(1.0, 1.0, 1.0, 0.98 * beam_alpha), 0.8)

	var burn_r = 16.0 * glow_pulse
	draw_circle(target_pos, burn_r + 4.0, Color(0.2, 0.7, 1.0, 0.25 * glow_pulse))
	draw_circle(target_pos, burn_r, Color(1.0, 0.75, 0.2, 0.75))
	draw_circle(target_pos, 6.0, Color(1.0, 0.95, 0.6, 0.95))
	draw_circle(target_pos, 2.5, Color.WHITE)

	for p in particles:
		if p["life"] > 0.0:
			var alpha = clamp(p["life"], 0.0, 1.0)
			var r = lerp(1.0, 3.0, p["life"])
			draw_circle(p["pos"], r, p["col"] * Color(1, 1, 1, alpha))

	for ring in range(4):
		var r_t = fmod(t * 3.5 + ring * 0.28, 1.0)
		var rad = r_t * 42.0
		var a = (1.0 - r_t) * beam_alpha
		draw_arc(target_pos, rad, 0, TAU, 20, Color(0.4, 0.88, 1.0, a * 0.75), 2.0)

	var heat_shimmer_pts = PackedVector2Array()
	for i in range(8):
		var ang = i / 8.0 * TAU
		var dist = 20.0 + sin(t * 30.0 + ang * 3) * 6.0
		heat_shimmer_pts.append(target_pos + Vector2(cos(ang), sin(ang)) * dist)
	heat_shimmer_pts.append(heat_shimmer_pts[0])
	draw_polyline(heat_shimmer_pts, Color(1.0, 0.6, 0.2, 0.25 * glow_pulse), 1.5)

func draw_drill_sequence() -> void:
	var t = anim_time
	var reach = 0.0
	if t < 0.9:
		reach = smoothstep(0.0, 1.0, t / 0.9)
	elif t < 2.9:
		reach = 1.0
	else:
		reach = clamp(1.0 - ((t - 2.9) / 0.9), 0.0, 1.0)

	var ground_contact = target_pos
	var arm_end = origin_pos.lerp(ground_contact + Vector2(0.0, -14.0), reach)
	var mid = origin_pos.lerp(arm_end, 0.48)
	var elbow = mid + Vector2(0.0, -24.0 * reach)

	var dark_metal = Color(0.18, 0.22, 0.28)
	var arm_metal = Color(0.68, 0.72, 0.78)

	draw_line(origin_pos, elbow, arm_metal, 6.0)
	draw_line(origin_pos + Vector2(1, -1), elbow + Vector2(1, -1), Color(0.88, 0.92, 0.96), 1.6)
	draw_circle(origin_pos, 6.0, dark_metal)
	draw_circle(origin_pos, 4.0, arm_metal)

	draw_circle(elbow, 5.5, dark_metal)
	draw_circle(elbow, 3.5, Color(0.35, 0.42, 0.52))

	draw_line(elbow, arm_end, arm_metal, 5.0)
	draw_line(elbow + Vector2(1, -1), arm_end + Vector2(1, -1), Color(0.88, 0.92, 0.96), 1.4)
	draw_circle(arm_end, 5.0, dark_metal)

	var turret_rect = Rect2(arm_end.x - 6.0, arm_end.y, 12.0, 10.0)
	draw_rect(turret_rect, dark_metal)
	draw_rect(turret_rect, Color(0.35, 0.40, 0.48), false, 1.2)

	var drill_depth = 0.0
	if t >= 0.9 and t < 2.9:
		drill_depth = sin((t - 0.9) * 45.0) * 1.5 + min(8.0, (t - 0.9) * 4.0)

	var bit_top = Vector2(arm_end.x, arm_end.y + 10.0)
	var bit_tip = Vector2(arm_end.x, ground_contact.y + drill_depth)
	draw_line(bit_top, bit_tip, Color(0.85, 0.88, 0.94), 3.2)

	for b in range(5):
		var by = lerp(bit_top.y, bit_tip.y, float(b) / 4.0)
		var b_flute = sin(t * 60.0 + b * 1.8) * 2.8
		draw_line(Vector2(arm_end.x - b_flute, by), Vector2(arm_end.x + b_flute, by + 1.5), Color(0.4, 0.44, 0.52), 1.4)

	if t >= 0.9 and t < 2.9:
		draw_circle(Vector2(arm_end.x, ground_contact.y), 9.0, Color(0.12, 0.10, 0.08, 0.85))
		draw_arc(Vector2(arm_end.x, ground_contact.y), 11.0, 0, TAU, 14, Color(0.65, 0.50, 0.35, 0.65), 2.0)
		for d in drill_debris:
			draw_circle(Vector2(d["x"], d["y"]), d["r"], d["col"])
		for p in particles:
			if p["life"] > 0.0:
				var alpha = clamp(p["life"], 0.0, 1.0)
				draw_circle(p["pos"], lerp(1.2, 3.2, p["life"]), p["col"] * Color(1, 1, 1, alpha))

	if t > 2.0:
		var core_alpha = clamp((t - 2.0) / 0.8, 0.0, 1.0)
		var tube_x = arm_end.x + 8.0
		var tube_y = arm_end.y - 12.0
		draw_rect(Rect2(tube_x, tube_y, 5.0, 18.0), Color(0.92, 0.78, 0.25, core_alpha))
		draw_rect(Rect2(tube_x, tube_y, 5.0, 18.0), Color(0.3, 0.25, 0.1, core_alpha), false, 1.0)
		draw_rect(Rect2(tube_x + 1.0, tube_y + 3.0, 3.0, 12.0), Color(0.55, 0.38, 0.22, core_alpha))

func draw_scoop_sequence() -> void:
	var t = anim_time
	var reach = 0.0
	var scooping = false
	if t < 1.0:
		reach = smoothstep(0.0, 1.0, t / 1.0)
	elif t < 2.3:
		reach = 1.0
		scooping = true
	else:
		reach = clamp(1.0 - ((t - 2.3) / 1.3), 0.0, 1.0)

	var ground_contact = target_pos
	var scoop_end = origin_pos.lerp(ground_contact + Vector2(0.0, -8.0), reach)
	var mid = origin_pos.lerp(scoop_end, 0.5)
	var elbow = mid + Vector2(0.0, -26.0 * reach)

	var arm_metal = Color(0.65, 0.70, 0.78)
	var dark_metal = Color(0.20, 0.24, 0.30)

	draw_line(origin_pos, elbow, arm_metal, 6.5)
	draw_line(origin_pos + Vector2(1, -1), elbow + Vector2(1, -1), Color(0.85, 0.90, 0.95), 1.5)
	draw_circle(origin_pos, 6.0, dark_metal)

	draw_circle(elbow, 5.5, dark_metal)
	draw_circle(elbow, 3.5, Color(0.35, 0.42, 0.52))

	draw_line(elbow, scoop_end, arm_metal, 5.0)
	draw_circle(scoop_end, 4.5, dark_metal)

	var bucket_angle = lerp(-PI * 0.15, -PI * 0.65, reach)
	if t >= 1.0 and t < 2.3:
		bucket_angle = -PI * 0.65 + sin((t - 1.0) * 12.0) * 0.12
	elif t >= 2.3:
		bucket_angle = lerp(-PI * 0.65, -PI * 0.95, (t - 2.3) / 1.3)

	var bd = Vector2(cos(bucket_angle), sin(bucket_angle))
	var bn = Vector2(-bd.y, bd.x)
	var bw = 12.0
	var blen = 16.0
	var scoop_pts = PackedVector2Array([
		scoop_end - bn * bw * 0.5,
		scoop_end + bn * bw * 0.5,
		scoop_end + bn * bw * 0.5 + bd * blen,
		scoop_end - bn * bw * 0.5 + bd * blen
	])
	draw_polygon(scoop_pts, [Color(0.88, 0.70, 0.22)])
	draw_polyline(PackedVector2Array([scoop_pts[0], scoop_pts[1], scoop_pts[2], scoop_pts[3], scoop_pts[0]]), Color(0.35, 0.28, 0.15), 1.5)

	if scooping:
		draw_arc(target_pos, 12.0 + sin(t * 22.0) * 2.0, 0, TAU, 14, Color(0.65, 0.45, 0.28, 0.6), 2.0)
		for d in scoop_soil:
			draw_circle(Vector2(d["x"], d["y"]), d["r"], d["col"])
		var soil_in_bucket = scoop_end + bd * blen * 0.5
		draw_circle(soil_in_bucket, 5.5, Color(0.55, 0.38, 0.22, 0.9))

	if t > 2.5:
		var drop_t = clamp((t - 2.5) / 1.0, 0.0, 1.0)
		var hopper_pos = origin_pos + Vector2(10.0, -8.0)
		draw_rect(Rect2(hopper_pos.x - 6.0, hopper_pos.y, 12.0, 8.0), Color(0.25, 0.28, 0.35))
		for i in range(6):
			var drop_x = hopper_pos.x + randf_range(-4.0, 4.0)
			var drop_y = hopper_pos.y - 12.0 + drop_t * 20.0
			draw_circle(Vector2(drop_x, drop_y), 2.0, Color(0.55, 0.38, 0.22, 1.0 - drop_t * 0.7))

func draw_micro_sequence() -> void:
	var t = anim_time
	var reach = smoothstep(0.0, 1.0, clamp(t / 0.8, 0.0, 1.0))
	if t > anim_duration - 0.7:
		reach = clamp((anim_duration - t) / 0.7, 0.0, 1.0)

	var arm_end = origin_pos.lerp(target_pos + Vector2(0.0, -18.0), reach)
	var mid = origin_pos.lerp(arm_end, 0.5)
	var elbow = mid + Vector2(0.0, -22.0 * reach)

	draw_line(origin_pos, elbow, Color(0.65, 0.70, 0.78), 6.0)
	draw_circle(origin_pos, 5.5, Color(0.20, 0.24, 0.30))
	draw_circle(elbow, 5.0, Color(0.20, 0.24, 0.30))
	draw_line(elbow, arm_end, Color(0.65, 0.70, 0.78), 4.5)
	draw_circle(arm_end, 4.5, Color(0.20, 0.24, 0.30))

	var cam_head_rect = Rect2(arm_end.x - 7.0, arm_end.y, 14.0, 12.0)
	draw_rect(cam_head_rect, Color(0.22, 0.26, 0.32))
	draw_rect(cam_head_rect, Color(0.4, 0.46, 0.55), false, 1.2)
	draw_circle(Vector2(arm_end.x, arm_end.y + 12.0), 3.5, Color(0.1, 0.15, 0.22))
	draw_circle(Vector2(arm_end.x, arm_end.y + 12.0), 2.0, Color(0.3, 0.75, 1.0))

	var led_pulse = 0.85 + sin(t * 30.0) * 0.15
	for led_x in [-5.0, 5.0]:
		draw_circle(Vector2(arm_end.x + led_x, arm_end.y + 11.0), 1.8, Color(1.0, 1.0, 1.0, led_pulse))

	var light_cone = PackedVector2Array([
		Vector2(arm_end.x - 5.0, arm_end.y + 12.0),
		Vector2(arm_end.x + 5.0, arm_end.y + 12.0),
		Vector2(target_pos.x + 18.0, target_pos.y),
		Vector2(target_pos.x - 18.0, target_pos.y)
	])
	draw_polygon(light_cone, [Color(1.0, 1.0, 0.9, 0.18 * led_pulse)])

	var cell_size = 18.0
	var grid_w = 5
	var grid_h = 5
	var total_w = grid_w * cell_size
	var total_h = grid_h * cell_size
	var gx0 = target_pos.x - total_w * 0.5
	var gy0 = target_pos.y - total_h - 45.0

	draw_rect(Rect2(gx0 - 3, gy0 - 3, total_w + 6, total_h + 6), Color(0.08, 0.14, 0.22, 0.88), true)
	draw_rect(Rect2(gx0 - 3, gy0 - 3, total_w + 6, total_h + 6), Color(0.3, 0.75, 1.0, 0.7), false, 1.5)

	for cell in micro_grid:
		var cx = gx0 + cell["x"] * cell_size
		var cy = gy0 + cell["y"] * cell_size
		var brightness = clamp(0.3 + cell["val"] * 0.7 + sin(t * 8.0 + cell["phase"]) * 0.15, 0.0, 1.0)
		var hue = fmod(cell["val"] * 0.4 + t * 0.05, 1.0)
		var cell_col = Color.from_hsv(hue, 0.6, brightness, 0.9)
		draw_rect(Rect2(cx + 1, cy + 1, cell_size - 2, cell_size - 2), cell_col, true)

	for gi in range(grid_w + 1):
		draw_line(Vector2(gx0 + gi * cell_size, gy0), Vector2(gx0 + gi * cell_size, gy0 + total_h), Color(0.3, 0.75, 1.0, 0.35), 0.8)
	for gi in range(grid_h + 1):
		draw_line(Vector2(gx0, gy0 + gi * cell_size), Vector2(gx0 + total_w, gy0 + gi * cell_size), Color(0.3, 0.75, 1.0, 0.35), 0.8)

	var scan_prog = fmod(t * 1.8, 1.0)
	var sx = gx0 + scan_prog * total_w
	draw_line(Vector2(sx, gy0), Vector2(sx, gy0 + total_h), Color(0.8, 0.95, 1.0, 0.75), 2.0)

func draw_gpr_sequence() -> void:
	var t = anim_time

	var ant_pos = origin_pos + Vector2(0.0, 10.0)
	draw_line(ant_pos - Vector2(16.0, 0.0), ant_pos + Vector2(16.0, 0.0), Color(0.92, 0.85, 0.30), 2.5)
	draw_circle(ant_pos, 3.5, Color(0.2, 0.25, 0.32))

	for p in gpr_pulses:
		var pt = fmod(t + p["offset"], 1.2)
		var depth = pt * 60.0
		var alpha = clamp(1.0 - (depth / 60.0), 0.0, 1.0)
		draw_arc(ant_pos, depth + 8.0, PI * 0.22, PI * 0.78, 18, Color(0.18, 0.92, 0.55, alpha * 0.85), 2.2)

	var layers_y = [18.0, 34.0, 48.0]
	for ly in layers_y:
		var strata_y = target_pos.y + ly
		var layer_w = 40.0 + ly * 0.5
		var pulse_glow = 0.5 + sin(t * 12.0 + ly) * 0.4
		draw_line(Vector2(target_pos.x - layer_w, strata_y), Vector2(target_pos.x + layer_w, strata_y), Color(0.35, 0.75, 1.0, pulse_glow * 0.7), 1.5)
		draw_circle(Vector2(target_pos.x + sin(t * 8.0) * (layer_w * 0.6), strata_y), 3.0, Color(1.0, 0.9, 0.4, pulse_glow))

func draw_scan_sequence() -> void:
	var t = anim_time
	var pulse = 0.65 + sin(t * 28.0) * 0.35
	var scan_progress = clamp(t / anim_duration, 0.0, 1.0)

	var cone = PackedVector2Array([
		origin_pos + Vector2(-12, 0),
		origin_pos + Vector2(12, 0),
		target_pos + Vector2(60, 0),
		target_pos + Vector2(-60, 0)
	])
	draw_colored_polygon(cone, Color(0.18, 0.92, 0.55, 0.14 * pulse))
	draw_polyline(PackedVector2Array([cone[0], cone[1], cone[2], cone[3], cone[0]]), Color(0.18, 0.92, 0.55, 0.50 * pulse), 1.5)

	var scan_y = lerp(origin_pos.y, target_pos.y, fmod(t * 2.5, 1.0))
	var sweep_w = lerp(14.0, 60.0, (scan_y - origin_pos.y) / max(1.0, (target_pos.y - origin_pos.y)))
	draw_line(Vector2(origin_pos.x - sweep_w, scan_y), Vector2(origin_pos.x + sweep_w, scan_y), Color(0.4, 1.0, 0.7, 0.9), 2.5)

	var cr = 26.0 * pulse
	draw_circle(target_pos, cr + 6.0, Color(0.18, 0.92, 0.55, 0.20 * pulse))
	draw_circle(target_pos, cr, Color(0.18, 0.92, 0.55, 0.12 * pulse))
	draw_arc(target_pos, 32.0, 0, TAU, 28, Color(0.18, 0.92, 0.55, 0.85), 2.0)

	var cross_ang = t * 1.2
	var ca = cos(cross_ang)
	var sa = sin(cross_ang)
	draw_line(target_pos + Vector2(-ca, -sa) * 38.0, target_pos + Vector2(ca, sa) * 38.0, Color(0.18, 0.92, 0.55, 0.75), 1.5)
	draw_line(target_pos + Vector2(-sa, ca) * 38.0, target_pos + Vector2(sa, -ca) * 38.0, Color(0.18, 0.92, 0.55, 0.75), 1.5)

func draw_antenna_sequence() -> void:
	var t = anim_time
	var dish_center = origin_pos + Vector2(0, -8)

	var dish_pts = PackedVector2Array()
	var dish_r = 22.0
	for i in range(14):
		var ang = PI + i / 13.0 * PI
		dish_pts.append(dish_center + Vector2(cos(ang) * dish_r, sin(ang) * dish_r * 0.55))
	draw_polyline(dish_pts, Color(0.9, 0.95, 1.0, 0.95), 3.0)
	draw_line(dish_pts[0], dish_pts[dish_pts.size() - 1], Color(0.9, 0.95, 1.0, 0.95), 3.0)

	var feed_pt = dish_center + Vector2(0, -4)
	draw_line(dish_center, feed_pt, Color(0.6, 0.65, 0.75), 2.0)
	draw_circle(feed_pt, 3.5, Color(0.25, 0.85, 1.0))
	draw_circle(feed_pt, 1.8, Color.WHITE)

	draw_line(dish_center, origin_pos + Vector2(0, 8), Color(0.55, 0.60, 0.70), 3.0)

	for w in radio_waves:
		var wave_t = fmod(t + w["offset"], 1.6)
		var rad = wave_t * 160.0 + 18.0
		var alpha = clamp(1.0 - (wave_t / 1.6), 0.0, 1.0)
		var thickness = lerp(2.8, 1.0, wave_t / 1.6)
		draw_arc(feed_pt, rad, -PI * 0.78, -PI * 0.22, 24, Color(0.2, 0.85, 1.0, alpha * 0.90), thickness)

	var side_waves_count = 3
	for sw in range(side_waves_count):
		var sw_t = fmod(t * 1.2 + sw * 0.5, 1.6)
		var sw_rad = sw_t * 90.0 + 12.0
		var sw_alpha = clamp(1.0 - (sw_t / 1.6), 0.0, 1.0)
		draw_arc(feed_pt, sw_rad, -PI * 0.65, -PI * 0.35, 14, Color(0.4, 0.95, 1.0, sw_alpha * 0.5), 1.5)

	if t > 1.2:
		var down_t = fmod(t * 1.4, 1.1)
		if down_t < 1.0:
			var down_y = lerp(60.0, origin_pos.y - 30.0, smoothstep(0.0, 1.0, down_t / 1.0))
			var down_alpha = 1.0 - down_t * 0.3
			draw_circle(Vector2(origin_pos.x, down_y), 5.5, Color(0.18, 0.92, 0.55, 0.95 * down_alpha))
			draw_circle(Vector2(origin_pos.x, down_y), 2.5, Color.WHITE)
			draw_line(Vector2(origin_pos.x, down_y - 18.0), Vector2(origin_pos.x, down_y), Color(0.18, 0.92, 0.55, 0.65 * down_alpha), 2.0)
