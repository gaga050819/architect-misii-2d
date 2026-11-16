extends Node2D

@export var transfer_progress: float = 0.0

var pulse_time: float = 0.0
var stars: Array = []

func _ready() -> void:
	stars.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(110):
		var ang = rng.randf_range(0, TAU)
		var dist = rng.randf_range(30.0, 480.0)
		var sz = rng.randf_range(0.8, 2.2)
		var spd = rng.randf_range(1.5, 4.5)
		var b_a = rng.randf_range(0.2, 0.75)
		var col_choice = rng.randi() % 4
		var col = Color(1.0, 1.0, 1.0)
		if col_choice == 1:
			col = Color(0.7, 0.85, 1.0)
		elif col_choice == 2:
			col = Color(1.0, 0.9, 0.7)
		elif col_choice == 3:
			col = Color(0.8, 1.0, 0.9)
		stars.append({
			"pos": Vector2(cos(ang), sin(ang)) * dist,
			"size": sz,
			"speed": spd,
			"base_alpha": b_a,
			"color": col
		})

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var center = Vector2.ZERO
	var font = ThemeDB.fallback_font

	for s in stars:
		var a = s["base_alpha"] + sin(pulse_time * s["speed"]) * 0.2
		a = clamp(a, 0.05, 0.95)
		var col = s["color"] as Color
		col.a = a
		draw_circle(s["pos"], s["size"], col)

	var orbit_earth_r = 100.0
	var target = DataManager.get_target(GameState.target_id)
	var orbit_au = float(target.get("orbit_au", 1.524))
	var orbit_target_r = orbit_earth_r * min(2.8, max(0.4, orbit_au))
	var target_color = Color(0.95, 0.45, 0.25)
	var target_name_str = "Марс"

	if GameState.target_id == "moon":
		orbit_target_r = orbit_earth_r + 18.0
		target_color = Color(0.85, 0.85, 0.9)
		target_name_str = "Місяць"
	elif GameState.target_id == "venus":
		target_color = Color(0.95, 0.8, 0.45)
		target_name_str = "Венера"
	elif GameState.target_id == "europa":
		target_color = Color(0.65, 0.85, 1.0)
		target_name_str = "Європа"
	elif GameState.target_id == "bennu":
		target_color = Color(0.6, 0.6, 0.65)
		target_name_str = "Бенну"
	elif GameState.target_id == "interstellar":
		orbit_au = 158.0
		orbit_target_r = orbit_earth_r * 2.65
		target_color = Color(0.3, 0.85, 1.0)
		target_name_str = "Межа геліосфери (120+ а.о.)"

	draw_arc(center, orbit_earth_r * 0.5, 0, TAU, 48, Color(0.2, 0.4, 0.6, 0.08), 1.0)
	draw_arc(center, orbit_earth_r, 0, TAU, 72, Color(0.2, 0.55, 0.9, 0.28), 1.5)
	draw_arc(center, orbit_target_r, 0, TAU, 72, Color(target_color.r, target_color.g, target_color.b, 0.32), 1.5)

	if font:
		draw_string(font, center + Vector2(10, -orbit_earth_r - 4), "1.00 а.о. (Орбіта Землі)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.35, 0.65, 0.95, 0.6))
		draw_string(font, center + Vector2(10, -orbit_target_r - 4), "%.2f а.о. (Орбіта %s)" % [orbit_au, target_name_str], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(target_color.r, target_color.g, target_color.b, 0.6))

	for ci in range(5):
		var ca = 0.08 - ci * 0.015
		draw_circle(center, 46.0 + ci * 12.0, Color(1.0, 0.72, 0.12, ca))
	var sun_pulse = 22.0 + sin(pulse_time * 2.8) * 2.0
	draw_circle(center, sun_pulse, Color(1.0, 0.92, 0.35))
	draw_circle(center, sun_pulse * 0.75, Color(1.0, 1.0, 0.7))

	var ray_count = 14
	for ri in range(ray_count):
		var ray_ang = (float(ri) / ray_count) * TAU + pulse_time * 0.3
		var ray_len = 16.0 + sin(pulse_time * 3.5 + ri * 0.7) * 6.0
		var r_inner = sun_pulse + 2.0
		var r_outer = r_inner + ray_len
		var rp1 = center + Vector2(cos(ray_ang), sin(ray_ang)) * r_inner
		var rp2 = center + Vector2(cos(ray_ang), sin(ray_ang)) * r_outer
		draw_line(rp1, rp2, Color(1.0, 0.85, 0.25, 0.5 + sin(pulse_time * 4.0 + ri) * 0.2), 1.8)

	var earth_ang = pulse_time * 0.06
	var earth_pos = center + Vector2(cos(earth_ang), sin(earth_ang)) * orbit_earth_r
	draw_circle(earth_pos, 13.0, Color(0.15, 0.5, 1.0, 0.25))
	draw_circle(earth_pos, 9.5, Color(0.12, 0.5, 0.98))
	draw_circle(earth_pos + Vector2(2, -2), 3.5, Color(0.25, 0.8, 0.35, 0.95))
	draw_circle(earth_pos + Vector2(-3, 2), 2.5, Color(0.2, 0.7, 0.3, 0.9))
	draw_arc(earth_pos, 11.0, PI * 1.0, PI * 2.0, 24, Color(0.4, 0.8, 1.0, 0.6), 2.0)
	if font:
		draw_string(font, earth_pos + Vector2(-20, 18), "Земля", HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0.65, 0.85, 1.0, 0.9))

	var target_ang = earth_ang + 1.85
	var target_pos = center + Vector2(cos(target_ang), sin(target_ang)) * orbit_target_r
	draw_circle(target_pos, 11.0, Color(target_color.r, target_color.g, target_color.b, 0.2))
	draw_circle(target_pos, 8.0, target_color)
	draw_circle(target_pos, 8.0, Color(0.0, 0.0, 0.0, 0.25))
	if GameState.target_id == "mars":
		draw_circle(target_pos + Vector2(0, -6), 2.5, Color(0.95, 0.95, 1.0, 0.85))
		draw_circle(target_pos + Vector2(3, 1), 2.0, Color(0.4, 0.15, 0.1, 0.6))
	elif GameState.target_id == "europa":
		draw_line(target_pos - Vector2(4, 2), target_pos + Vector2(4, 1), Color(0.5, 0.25, 0.2, 0.7), 1.0)
	if font:
		draw_string(font, target_pos + Vector2(-24, 18), target_name_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, target_color)

	var arc_full: PackedVector2Array = []
	for i in range(51):
		var t = float(i) / 50.0
		var r = lerp(orbit_earth_r, orbit_target_r, t)
		var ang = lerp(earth_ang, target_ang, t)
		arc_full.append(center + Vector2(cos(ang), sin(ang)) * r)

	var arc_done: PackedVector2Array = []
	var total_done_idx = int(transfer_progress * 50.0)
	for i in range(total_done_idx + 1):
		arc_done.append(arc_full[i])
	var cur_r = lerp(orbit_earth_r, orbit_target_r, transfer_progress)
	var cur_a = lerp(earth_ang, target_ang, transfer_progress)
	var craft_pos = center + Vector2(cos(cur_a), sin(cur_a)) * cur_r
	if arc_done.is_empty() or arc_done[-1].distance_to(craft_pos) > 1.0:
		arc_done.append(craft_pos)

	if arc_full.size() > 1:
		draw_polyline(arc_full, Color(0.2, 0.8, 0.5, 0.2), 1.5)
	if arc_done.size() > 1:
		for gi in range(3):
			var ga = 0.14 - gi * 0.04
			draw_polyline(arc_done, Color(0.18, 0.95, 0.6, ga), 5.0 - gi * 1.5)
		draw_polyline(arc_done, Color(0.2, 0.98, 0.65, 0.95), 2.5)

	var craft_to_earth = earth_pos - craft_pos
	var sig_dir = craft_to_earth.normalized()
	var sig_dist = craft_to_earth.length()
	var packet_t = fmod(pulse_time * 0.8, 1.0)
	var packet_pos = craft_pos + sig_dir * (sig_dist * packet_t)
	draw_line(craft_pos, earth_pos, Color(0.0, 0.9, 1.0, 0.12), 1.0)
	draw_circle(packet_pos, 3.5, Color(0.0, 0.9, 1.0, 0.75))
	draw_arc(packet_pos, 6.0, 0, TAU, 16, Color(0.0, 0.9, 1.0, 0.4), 1.2)

	if GameState.target_id == "interstellar":
		var dish_dir = (earth_pos - craft_pos).normalized()
		var dish_center = craft_pos + dish_dir * 5.0
		draw_circle(dish_center, 8.5, Color(0.96, 0.98, 1.0))
		draw_arc(dish_center, 8.5, 0, TAU, 24, Color(0.65, 0.70, 0.80), 1.2)
		draw_circle(dish_center, 2.5, Color(1.0, 0.82, 0.25))

		draw_circle(craft_pos, 4.5, Color(0.85, 0.70, 0.22))
		draw_circle(craft_pos - dish_dir * 1.5, 2.0, Color(1.0, 0.88, 0.35))

		var rtg_dir = dish_dir.rotated(PI * 0.65)
		draw_line(craft_pos, craft_pos + rtg_dir * 12.0, Color(0.5, 0.55, 0.65), 2.0)
		for ri in range(3):
			var r_pt = craft_pos + rtg_dir * (5.0 + ri * 3.5)
			draw_circle(r_pt, 1.8, Color(1.0, 0.45, 0.15))

		var mag_dir = dish_dir.rotated(-PI * 0.7)
		draw_line(craft_pos, craft_pos + mag_dir * 18.0, Color(0.65, 0.70, 0.80), 1.5)
		draw_rect(Rect2(craft_pos + mag_dir * 18.0 - Vector2(2, 2), Vector2(4, 4)), Color(0.9, 0.92, 0.96))

		if font:
			var craft_label = "VOYAGER-1 [158 а.о. / МІЖЗОРЯНИЙ ПРОСТІР]"
			draw_string(font, craft_pos + Vector2(18, -6), craft_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.9, 1.0))
	else:
		var craft_pulse = 0.7 + sin(pulse_time * 7.0) * 0.3
		draw_circle(craft_pos, 12.0, Color(0.18, 0.95, 0.6, 0.18 * craft_pulse))
		draw_circle(craft_pos, 5.0, Color(0.95, 0.85, 0.3))

		draw_rect(Rect2(craft_pos - Vector2(16, 3), Vector2(10, 6)), Color(0.15, 0.45, 0.85), true)
		draw_rect(Rect2(craft_pos - Vector2(16, 3), Vector2(10, 6)), Color(0.4, 0.7, 1.0), false, 1.0)
		draw_rect(Rect2(craft_pos + Vector2(6, -3), Vector2(10, 6)), Color(0.15, 0.45, 0.85), true)
		draw_rect(Rect2(craft_pos + Vector2(6, -3), Vector2(10, 6)), Color(0.4, 0.7, 1.0), false, 1.0)

		var dish_dir = (earth_pos - craft_pos).normalized()
		var dish_pos = craft_pos + dish_dir * 4.0
		draw_arc(dish_pos, 5.0, dish_dir.angle() - PI * 0.45, dish_dir.angle() + PI * 0.45, 12, Color(1.0, 1.0, 1.0), 1.8)
		draw_line(craft_pos, dish_pos, Color(0.8, 0.8, 0.85), 1.5)

		if font:
			var craft_label = "АПАРАТ [%d%%]" % int(transfer_progress * 100.0)
			draw_string(font, craft_pos + Vector2(18, -6), craft_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.18, 0.95, 0.6, 0.95))
