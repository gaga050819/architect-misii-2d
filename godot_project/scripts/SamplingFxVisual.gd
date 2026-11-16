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

func start_laser(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "laser"
	anim_time = 0.0
	anim_duration = 3.2
	origin_pos = p_from
	target_pos = p_to
	particles.clear()
	for i in range(28):
		var ang = randf_range(-PI * 0.85, -PI * 0.15)
		var spd = randf_range(60.0, 280.0)
		particles.append({
			"pos": target_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"life": randf_range(0.25, 0.9),
			"max_life": 0.9,
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
	for i in range(32):
		var ang = randf_range(-PI * 0.98, -PI * 0.02)
		var spd = randf_range(30.0, 180.0)
		particles.append({
			"pos": target_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"life": randf_range(0.5, 1.4),
			"col": Color(randf_range(0.6, 0.85), randf_range(0.5, 0.70), randf_range(0.35, 0.55))
		})
	for i in range(8):
		drill_debris.append({
			"x": target_pos.x + randf_range(-18.0, 18.0),
			"y": target_pos.y,
			"r": randf_range(2.0, 5.0),
			"col": Color(randf_range(0.5, 0.75), randf_range(0.4, 0.60), 0.3)
		})
	queue_redraw()

func start_scoop(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "scoop"
	anim_time = 0.0
	anim_duration = 3.6
	origin_pos = p_from
	target_pos = p_to
	scoop_soil.clear()
	for i in range(14):
		scoop_soil.append({
			"x": target_pos.x + randf_range(-12.0, 12.0),
			"y": target_pos.y + randf_range(-4.0, 4.0),
			"r": randf_range(1.5, 4.0),
			"col": Color(randf_range(0.5, 0.75), randf_range(0.35, 0.55), randf_range(0.2, 0.35))
		})
	queue_redraw()

func start_orbital_scan(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "scan"
	anim_time = 0.0
	anim_duration = 3.2
	origin_pos = p_from
	target_pos = p_to
	queue_redraw()

func start_microscopic(p_pos: Vector2) -> void:
	anim_type = "micro"
	anim_time = 0.0
	anim_duration = 3.5
	origin_pos = p_pos
	target_pos = p_pos
	micro_grid.clear()
	for gy in range(5):
		for gx in range(5):
			micro_grid.append({
				"x": gx, "y": gy,
				"val": randf(),
				"phase": randf_range(0.0, TAU)
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
		"antenna":
			draw_antenna_sequence()

func draw_laser_sequence() -> void:
	var t = anim_time
	var dur = anim_duration
	var progress = clamp(t / dur, 0.0, 1.0)

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
	elif t < 2.8:
		reach = 1.0 + sin(t * 55.0) * 0.04
	else:
		reach = clamp(1.0 - ((t - 2.8) / 1.0), 0.0, 1.0)

	var tip = lerp(origin_pos, target_pos, reach)
	var joint1 = origin_pos + (target_pos - origin_pos) * 0.35 * reach
	var joint2 = origin_pos + (target_pos - origin_pos) * 0.70 * reach

	var arm_col = Color(0.62, 0.68, 0.76)
	draw_line(origin_pos, joint1, arm_col, 7.0)
	draw_circle(origin_pos, 5.5, Color(0.22, 0.26, 0.34))
	draw_circle(origin_pos, 3.5, Color(0.4, 0.5, 0.65))

	draw_line(joint1, joint2, arm_col * Color(0.9, 0.9, 0.9), 6.0)
	draw_circle(joint1, 5.0, Color(0.22, 0.26, 0.34))
	draw_circle(joint1, 3.0, Color(0.4, 0.5, 0.65))

	draw_line(joint2, tip, arm_col * Color(0.80, 0.80, 0.80), 5.0)
	draw_circle(joint2, 4.5, Color(0.22, 0.26, 0.34))

	var bit_dir = (target_pos - origin_pos).normalized()
	var bit_end = tip + bit_dir * 20.0
	var bit_spin = fmod(t * 18.0, TAU) if t > 0.5 and t < 2.8 else 0.0
	for s in range(5):
		var sa = bit_spin + s / 5.0 * TAU
		var bp = tip + Vector2(cos(sa), sin(sa)) * 3.5
		draw_line(bp, tip + bit_dir * (8.0 + s * 2.0), Color(0.88, 0.90, 0.95), 2.0)
	draw_line(tip, bit_end, Color(0.78, 0.82, 0.90), 3.5)

	if t > 0.9 and t < 2.8:
		for p in particles:
			if p["life"] > 0.0:
				var alpha = clamp(p["life"], 0.0, 1.0)
				draw_circle(p["pos"], lerp(1.0, 2.5, p["life"]), p["col"] * Color(1, 1, 1, alpha))
		for d in drill_debris:
			draw_circle(Vector2(d["x"], d["y"]), d["r"], d["col"])
		draw_circle(target_pos, 8.0, Color(0.80, 0.60, 0.40, 0.65))
		draw_arc(target_pos, 10.0, 0, TAU, 10, Color(0.75, 0.55, 0.35, 0.45), 2.0)

	if t > 2.0:
		var core_alpha = clamp((t - 2.0) / 0.8, 0.0, 1.0)
		var core_w = 6.0
		var core_h = 20.0
		draw_rect(Rect2(target_pos.x - core_w * 0.5, target_pos.y - core_h, core_w, core_h),
			Color(0.5, 0.35, 0.22, 0.85 * core_alpha), true)
		draw_rect(Rect2(target_pos.x - core_w * 0.5, target_pos.y - core_h, core_w, core_h),
			Color(0.75, 0.6, 0.45, 0.7 * core_alpha), false, 1.5)

func draw_scoop_sequence() -> void:
	var t = anim_time
	var reach = 0.0
	var scooping = false
	if t < 1.1:
		reach = smoothstep(0.0, 1.0, t / 1.1)
	elif t < 2.2:
		reach = 1.0
		scooping = true
	else:
		reach = clamp(1.0 - ((t - 2.2) / 1.4), 0.0, 1.0)

	var joint1 = origin_pos + Vector2(28, -20) * reach
	var joint2 = joint1 + Vector2(20, 10) * reach
	var scoop_end = lerp(origin_pos, target_pos, reach)

	draw_line(origin_pos, joint1, Color(0.68, 0.74, 0.82), 7.0)
	draw_circle(origin_pos, 5.5, Color(0.22, 0.26, 0.34))
	draw_circle(origin_pos, 3.5, Color(0.42, 0.52, 0.65))
	draw_circle(joint1, 5.0, Color(0.22, 0.26, 0.34))

	draw_line(joint1, joint2, Color(0.60, 0.66, 0.74), 6.0)
	draw_circle(joint2, 4.5, Color(0.22, 0.26, 0.34))

	draw_line(joint2, scoop_end, Color(0.55, 0.60, 0.68), 5.0)

	var scoop_angle = lerp(0.0, -PI * 0.5, reach)
	var sd = Vector2(cos(scoop_angle), sin(scoop_angle))
	var sn = Vector2(-sd.y, sd.x)
	var sw = 10.0
	var sd_len = 16.0
	var scoop_pts = PackedVector2Array([
		scoop_end - sn * sw * 0.5,
		scoop_end + sn * sw * 0.5,
		scoop_end + sn * sw * 0.5 + sd * sd_len,
		scoop_end - sn * sw * 0.5 + sd * sd_len
	])
	draw_colored_polygon(scoop_pts, Color(0.92, 0.72, 0.18, 0.95))
	draw_polyline(PackedVector2Array([scoop_pts[0], scoop_pts[1], scoop_pts[2], scoop_pts[3], scoop_pts[0]]),
		Color(0.5, 0.4, 0.15, 0.85), 1.5)

	if scooping:
		for d in scoop_soil:
			draw_circle(Vector2(d["x"], d["y"]), d["r"], d["col"])
		var dig_circle_r = 8.0 + sin(t * 25.0) * 3.0
		draw_arc(target_pos, dig_circle_r, 0, TAU, 10, Color(0.65, 0.48, 0.30, 0.55), 2.0)
		var soil_scoop_alpha = clamp((t - 1.1) / 0.6, 0.0, 1.0)
		draw_circle(scoop_end + sd * sd_len * 0.5, 5.0, Color(0.5, 0.35, 0.20, 0.8 * soil_scoop_alpha))

	if t > 2.5:
		var drop_t = clamp((t - 2.5) / 0.8, 0.0, 1.0)
		for i in range(5):
			var drop_x = origin_pos.x + randf_range(-8.0, 8.0) + i * 3.0
			var drop_y = origin_pos.y - 20.0 + drop_t * 30.0
			draw_circle(Vector2(drop_x, drop_y), 2.5, Color(0.5, 0.35, 0.20, 1.0 - drop_t))

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
	draw_polyline(PackedVector2Array([cone[0], cone[1], cone[2], cone[3], cone[0]]),
		Color(0.18, 0.92, 0.55, 0.50 * pulse), 1.5)

	var scan_y = lerp(origin_pos.y, target_pos.y, fmod(t * 2.5, 1.0))
	var sweep_w = lerp(14.0, 60.0, (scan_y - origin_pos.y) / max(1.0, (target_pos.y - origin_pos.y)))
	draw_line(Vector2(origin_pos.x - sweep_w, scan_y), Vector2(origin_pos.x + sweep_w, scan_y),
		Color(0.4, 1.0, 0.7, 0.9), 2.5)
	draw_line(Vector2(origin_pos.x - sweep_w, scan_y - 1.0), Vector2(origin_pos.x + sweep_w, scan_y - 1.0),
		Color(0.8, 1.0, 0.9, 0.3), 1.0)

	for grid_row in range(4):
		var gy = lerp(origin_pos.y, target_pos.y, (grid_row + 1) / 5.0)
		var gw = lerp(10.0, 55.0, (grid_row + 1) / 5.0)
		if gy < scan_y - 2.0:
			draw_line(Vector2(origin_pos.x - gw, gy), Vector2(origin_pos.x + gw, gy),
				Color(0.18, 0.92, 0.55, 0.3), 0.8)
			for col_i in range(3):
				var gx = origin_pos.x + (col_i - 1) * gw * 0.6
				draw_circle(Vector2(gx, gy), 2.0, Color(0.18, 0.92, 0.55, 0.5))

	var cr = 26.0 * pulse
	draw_circle(target_pos, cr + 6.0, Color(0.18, 0.92, 0.55, 0.20 * pulse))
	draw_circle(target_pos, cr, Color(0.18, 0.92, 0.55, 0.12 * pulse))
	draw_arc(target_pos, 32.0, 0, TAU, 28, Color(0.18, 0.92, 0.55, 0.85), 2.0)
	draw_arc(target_pos, 20.0, 0, TAU, 20, Color(0.18, 0.92, 0.55, 0.55), 1.5)

	var cross_ang = t * 1.2
	var ca = cos(cross_ang)
	var sa = sin(cross_ang)
	draw_line(target_pos + Vector2(-ca, -sa) * 38.0, target_pos + Vector2(ca, sa) * 38.0,
		Color(0.18, 0.92, 0.55, 0.75), 1.5)
	draw_line(target_pos + Vector2(-sa, ca) * 38.0, target_pos + Vector2(sa, -ca) * 38.0,
		Color(0.18, 0.92, 0.55, 0.75), 1.5)

	var n_hits = int(scan_progress * 5.0)
	for hi in range(n_hits):
		var hx = target_pos.x + cos(hi * 1.3 + 0.5) * 25.0
		var hy = target_pos.y + sin(hi * 1.1 + 0.3) * 15.0
		draw_circle(Vector2(hx, hy), 3.5, Color(0.4, 1.0, 0.7, 0.8))
		draw_arc(Vector2(hx, hy), 6.0, 0, TAU, 8, Color(0.4, 1.0, 0.7, 0.4), 1.0)

func draw_micro_sequence() -> void:
	var t = anim_time
	var pulse = 0.7 + sin(t * 20.0) * 0.3
	var cell_size = 18.0
	var grid_w = 5
	var grid_h = 5
	var total_w = grid_w * cell_size
	var total_h = grid_h * cell_size
	var gx0 = origin_pos.x - total_w * 0.5
	var gy0 = origin_pos.y - total_h * 0.5 - 20.0

	draw_rect(Rect2(gx0 - 3, gy0 - 3, total_w + 6, total_h + 6),
		Color(0.08, 0.14, 0.22, 0.85), true)
	draw_rect(Rect2(gx0 - 3, gy0 - 3, total_w + 6, total_h + 6),
		Color(0.3, 0.75, 1.0, 0.7), false, 1.5)

	for cell in micro_grid:
		var cx = gx0 + cell["x"] * cell_size
		var cy = gy0 + cell["y"] * cell_size
		var brightness = 0.3 + cell["val"] * 0.7 + sin(t * 8.0 + cell["phase"]) * 0.15
		brightness = clamp(brightness, 0.0, 1.0)
		var hue = fmod(cell["val"] * 0.4 + t * 0.05, 1.0)
		var cell_col = Color.from_hsv(hue, 0.6, brightness, 0.9)
		draw_rect(Rect2(cx + 1, cy + 1, cell_size - 2, cell_size - 2), cell_col, true)
		draw_rect(Rect2(cx + 1, cy + 1, cell_size - 2, cell_size - 2),
			Color(1.0, 1.0, 1.0, 0.12), false, 0.8)

	for gi in range(grid_w + 1):
		draw_line(Vector2(gx0 + gi * cell_size, gy0), Vector2(gx0 + gi * cell_size, gy0 + total_h),
			Color(0.3, 0.75, 1.0, 0.35), 0.8)
	for gi in range(grid_h + 1):
		draw_line(Vector2(gx0, gy0 + gi * cell_size), Vector2(gx0 + total_w, gy0 + gi * cell_size),
			Color(0.3, 0.75, 1.0, 0.35), 0.8)

	var scan_prog = fmod(t * 1.8, 1.0)
	var sx = gx0 + scan_prog * total_w
	draw_line(Vector2(sx, gy0), Vector2(sx, gy0 + total_h),
		Color(0.8, 0.95, 1.0, 0.75 * pulse), 2.0)

	var focus_x = gx0 + int(t * 2.0) % grid_w * cell_size + cell_size * 0.5
	var focus_y = gy0 + int(t * 1.3) % grid_h * cell_size + cell_size * 0.5
	draw_arc(Vector2(focus_x, focus_y), cell_size * 0.6, 0, TAU, 12,
		Color(1.0, 0.95, 0.5, 0.9 * pulse), 2.0)

	var info_y = gy0 + total_h + 10.0
	draw_line(Vector2(gx0, info_y), Vector2(gx0 + total_w * clamp(t / anim_duration, 0.0, 1.0), info_y),
		Color(0.18, 0.92, 0.55, 0.85), 3.0)
	draw_line(Vector2(gx0, info_y), Vector2(gx0 + total_w, info_y),
		Color(1.0, 1.0, 1.0, 0.18), 1.5)

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
		draw_arc(feed_pt, rad, -PI * 0.78, -PI * 0.22, 24,
			Color(0.2, 0.85, 1.0, alpha * 0.90), thickness)

	var side_waves_count = 3
	for sw in range(side_waves_count):
		var sw_t = fmod(t * 1.2 + sw * 0.5, 1.6)
		var sw_rad = sw_t * 90.0 + 12.0
		var sw_alpha = clamp(1.0 - (sw_t / 1.6), 0.0, 1.0)
		draw_arc(feed_pt, sw_rad, -PI * 0.65, -PI * 0.35, 14,
			Color(0.4, 0.95, 1.0, sw_alpha * 0.5), 1.5)

	if t > 1.2:
		var down_t = fmod(t * 1.4, 1.1)
		if down_t < 1.0:
			var down_y = lerp(60.0, origin_pos.y - 30.0, smoothstep(0.0, 1.0, down_t / 1.0))
			var down_alpha = 1.0 - down_t * 0.3
			draw_circle(Vector2(origin_pos.x, down_y), 5.5, Color(0.18, 0.92, 0.55, 0.95 * down_alpha))
			draw_circle(Vector2(origin_pos.x, down_y), 2.5, Color.WHITE)
			draw_line(Vector2(origin_pos.x, down_y - 18.0), Vector2(origin_pos.x, down_y),
				Color(0.18, 0.92, 0.55, 0.65 * down_alpha), 2.0)
