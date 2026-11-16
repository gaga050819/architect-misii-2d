extends Node2D

var anim_type: String = "none"
var anim_time: float = 0.0
var anim_duration: float = 3.0

var origin_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var particles: Array = []
var radio_waves: Array = []

func start_laser(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "laser"
	anim_time = 0.0
	anim_duration = 2.6
	origin_pos = p_from
	target_pos = p_to
	particles.clear()
	for i in range(20):
		var ang = randf_range(-PI * 0.8, -PI * 0.2)
		var spd = randf_range(80.0, 240.0)
		particles.append({
			"pos": target_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"life": randf_range(0.3, 0.8),
			"col": Color(1.0, randf_range(0.5, 0.9), 0.2)
		})
	queue_redraw()

func start_drill(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "drill"
	anim_time = 0.0
	anim_duration = 3.2
	origin_pos = p_from
	target_pos = p_to
	particles.clear()
	for i in range(25):
		var ang = randf_range(-PI * 0.95, -PI * 0.05)
		var spd = randf_range(40.0, 160.0)
		particles.append({
			"pos": target_pos,
			"vel": Vector2(cos(ang) * spd, sin(ang) * spd),
			"life": randf_range(0.4, 1.0),
			"col": Color(0.75, 0.65, 0.55)
		})
	queue_redraw()

func start_scoop(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "scoop"
	anim_time = 0.0
	anim_duration = 3.4
	origin_pos = p_from
	target_pos = p_to
	particles.clear()
	queue_redraw()

func start_orbital_scan(p_from: Vector2, p_to: Vector2) -> void:
	anim_type = "scan"
	anim_time = 0.0
	anim_duration = 2.8
	origin_pos = p_from
	target_pos = p_to
	queue_redraw()

func start_antenna(p_pos: Vector2) -> void:
	anim_type = "antenna"
	anim_time = 0.0
	anim_duration = 3.0
	origin_pos = p_pos
	radio_waves.clear()
	for i in range(4):
		radio_waves.append({
			"rad": 15.0 + i * 22.0,
			"max_rad": 140.0,
			"speed": 65.0,
			"offset": i * 0.4
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
			p["vel"].y += 180.0 * delta

	if anim_time > anim_duration:
		anim_type = "none"

	queue_redraw()

func _draw() -> void:
	if anim_type == "none":
		return

	if anim_type == "laser":
		draw_laser_sequence()
	elif anim_type == "drill":
		draw_drill_sequence()
	elif anim_type == "scoop":
		draw_scoop_sequence()
	elif anim_type == "scan":
		draw_scan_sequence()
	elif anim_type == "antenna":
		draw_antenna_sequence()

func draw_laser_sequence() -> void:
	var t = anim_time
	var pulse = 0.7 + sin(t * 45.0) * 0.3

	draw_line(origin_pos, target_pos, Color(0.2, 0.7, 1.0, 0.25 * pulse), 9.0)
	draw_line(origin_pos, target_pos, Color(0.4, 0.9, 1.0, 0.8 * pulse), 4.0)
	draw_line(origin_pos, target_pos, Color(1.0, 1.0, 1.0, 0.95), 1.5)

	draw_circle(target_pos, 14.0 * pulse, Color(0.2, 0.8, 1.0, 0.4))
	draw_circle(target_pos, 7.0 * pulse, Color(1.0, 0.9, 0.4, 0.9))
	draw_circle(target_pos, 3.5, Color.WHITE)

	for p in particles:
		if p["life"] > 0.0:
			var alpha = clamp(p["life"], 0.0, 1.0)
			draw_circle(p["pos"], 2.5, p["col"] * Color(1, 1, 1, alpha))

	for ring in range(3):
		var r_t = fmod(t * 3.0 + ring * 0.33, 1.0)
		var rad = r_t * 35.0
		var a = 1.0 - r_t
		draw_arc(target_pos, rad, 0, TAU, 16, Color(0.3, 0.85, 1.0, a * 0.7), 1.5)

func draw_drill_sequence() -> void:
	var t = anim_time
	var reach = 0.0
	if t < 0.8:
		reach = t / 0.8
	elif t < 2.5:
		reach = 1.0 + sin(t * 50.0) * 0.05
	else:
		reach = clamp(1.0 - ((t - 2.5) / 0.7), 0.0, 1.0)

	var tip = lerp(origin_pos, target_pos, reach)
	var joint = origin_pos + Vector2(18, -12) * reach

	draw_line(origin_pos, joint, Color(0.65, 0.70, 0.78), 6.0)
	draw_circle(origin_pos, 4.5, Color(0.25, 0.28, 0.34))
	draw_circle(joint, 4.0, Color(0.25, 0.28, 0.34))
	draw_line(joint, tip, Color(0.55, 0.60, 0.68), 5.0)

	var drill_bit_len = 16.0
	var bit_end = tip + (target_pos - origin_pos).normalized() * drill_bit_len
	draw_line(tip, bit_end, Color(0.85, 0.88, 0.92), 3.0)
	for d in range(4):
		var cut_y = lerp(tip, bit_end, float(d) / 4.0)
		draw_circle(cut_y, 2.5, Color(0.3, 0.35, 0.42))

	if t > 0.8 and t < 2.5:
		for p in particles:
			if p["life"] > 0.0:
				var alpha = clamp(p["life"], 0.0, 1.0)
				draw_circle(p["pos"], 2.0, p["col"] * Color(1, 1, 1, alpha))
		draw_circle(target_pos, 6.0, Color(0.85, 0.65, 0.45, 0.7))

func draw_scoop_sequence() -> void:
	var t = anim_time
	var reach = 0.0
	if t < 1.0:
		reach = t / 1.0
	elif t < 2.0:
		reach = 1.0
	else:
		reach = clamp(1.0 - ((t - 2.0) / 1.4), 0.0, 1.0)

	var joint1 = origin_pos + Vector2(25, -25) * reach
	var scoop_end = lerp(origin_pos, target_pos, reach)

	draw_line(origin_pos, joint1, Color(0.7, 0.75, 0.82), 6.0)
	draw_circle(origin_pos, 5.0, Color(0.25, 0.28, 0.35))
	draw_circle(joint1, 4.5, Color(0.25, 0.28, 0.35))
	draw_line(joint1, scoop_end, Color(0.6, 0.65, 0.72), 5.0)

	var scoop_poly = PackedVector2Array([
		scoop_end + Vector2(-6, -4),
		scoop_end + Vector2(10, -4),
		scoop_end + Vector2(12, 8),
		scoop_end + Vector2(-4, 10)
	])
	draw_colored_polygon(scoop_poly, Color(0.95, 0.65, 0.15))

	if t > 1.2 and t < 2.8:
		draw_circle(scoop_end + Vector2(3, 2), 4.5, Color(0.45, 0.32, 0.22))

func draw_scan_sequence() -> void:
	var t = anim_time
	var pulse = 0.7 + sin(t * 30.0) * 0.3

	var cone = PackedVector2Array([
		origin_pos + Vector2(-10, 0),
		origin_pos + Vector2(10, 0),
		target_pos + Vector2(55, 0),
		target_pos + Vector2(-55, 0)
	])
	draw_colored_polygon(cone, Color(0.18, 0.92, 0.55, 0.20 * pulse))
	draw_polyline(cone, Color(0.18, 0.92, 0.55, 0.55 * pulse), 1.5)

	var scan_sweep_y = lerp(origin_pos.y, target_pos.y, fmod(t * 2.2, 1.0))
	var sweep_w = lerp(12.0, 55.0, (scan_sweep_y - origin_pos.y) / max(1.0, (target_pos.y - origin_pos.y)))
	draw_line(Vector2(origin_pos.x - sweep_w, scan_sweep_y), Vector2(origin_pos.x + sweep_w, scan_sweep_y), Color(0.4, 1.0, 0.7, 0.85), 2.0)

	draw_circle(target_pos, 22.0 * pulse, Color(0.18, 0.92, 0.55, 0.3))
	draw_arc(target_pos, 28.0, 0, TAU, 24, Color(0.18, 0.92, 0.55, 0.8), 2.0)
	draw_line(target_pos - Vector2(36, 0), target_pos + Vector2(36, 0), Color(0.18, 0.92, 0.55, 0.7), 1.2)
	draw_line(target_pos - Vector2(0, 36), target_pos + Vector2(0, 36), Color(0.18, 0.92, 0.55, 0.7), 1.2)

func draw_antenna_sequence() -> void:
	var t = anim_time

	draw_arc(origin_pos + Vector2(0, -6), 18.0, PI * 0.9, PI * 2.1, 16, Color(0.9, 0.95, 1.0), 3.0)
	draw_line(origin_pos + Vector2(0, -6), origin_pos + Vector2(0, -22), Color(0.6, 0.65, 0.75), 2.5)
	draw_circle(origin_pos + Vector2(0, -22), 3.5, Color(0.25, 0.85, 1.0))

	for w in radio_waves:
		var wave_t = fmod(t + w["offset"], 1.5)
		var rad = wave_t * 140.0 + 20.0
		var alpha = clamp(1.0 - (wave_t / 1.5), 0.0, 1.0)
		draw_arc(origin_pos + Vector2(0, -22), rad, -PI * 0.8, -PI * 0.2, 24, Color(0.2, 0.85, 1.0, alpha * 0.85), 2.5)

	if t > 1.4:
		var down_t = fmod(t * 1.5, 1.0)
		var down_y = lerp(50.0, origin_pos.y - 25.0, down_t)
		draw_circle(Vector2(origin_pos.x, down_y), 4.0, Color(0.18, 0.92, 0.55, 0.9))
		draw_line(Vector2(origin_pos.x, down_y - 15), Vector2(origin_pos.x, down_y), Color(0.18, 0.92, 0.55, 0.7), 2.0)
