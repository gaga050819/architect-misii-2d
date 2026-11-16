extends Node2D

@export var transfer_progress: float = 0.0

var pulse_time: float = 0.0

func _process(delta: float) -> void:
	pulse_time += delta
	queue_redraw()

func _draw() -> void:
	var center = Vector2.ZERO

	for ci in range(4):
		var ca = 0.06 - ci * 0.015
		draw_circle(center, 42.0 + ci * 10.0, Color(1.0, 0.75, 0.15, ca))
	var sun_pulse = 20.0 + sin(pulse_time * 2.8) * 2.5
	draw_circle(center, sun_pulse, Color(1.0, 0.92, 0.3))
	draw_circle(center, sun_pulse * 0.7, Color(1.0, 1.0, 0.65))

	var ray_count = 12
	for ri in range(ray_count):
		var ray_ang = (float(ri) / ray_count) * TAU + pulse_time * 0.4
		var ray_len = 14.0 + sin(pulse_time * 3.0 + ri * 0.8) * 5.0
		var r_inner = sun_pulse + 3.0
		var r_outer = r_inner + ray_len
		var rp1 = center + Vector2(cos(ray_ang), sin(ray_ang)) * r_inner
		var rp2 = center + Vector2(cos(ray_ang), sin(ray_ang)) * r_outer
		draw_line(rp1, rp2, Color(1.0, 0.85, 0.3, 0.6 + sin(pulse_time * 5.0 + ri) * 0.2), 1.5)

	var orbit_earth_r = 90.0
	draw_arc(center, orbit_earth_r, 0, TAU, 64, Color(0.2, 0.5, 0.8, 0.3), 1.5)

	var target = DataManager.get_target(GameState.target_id)
	var orbit_au = float(target.get("orbit_au", 1.524))
	var orbit_target_r = orbit_earth_r * min(3.0, max(0.5, orbit_au))
	var target_color = Color(0.9, 0.4, 0.3)
	if GameState.target_id == "moon":
		orbit_target_r = orbit_earth_r + 14.0
		target_color = Color(0.8, 0.8, 0.85)
	elif GameState.target_id == "venus":
		target_color = Color(0.9, 0.75, 0.4)
	elif GameState.target_id == "europa":
		target_color = Color(0.6, 0.8, 0.95)
	elif GameState.target_id == "bennu":
		target_color = Color(0.5, 0.5, 0.5)

	draw_arc(center, orbit_target_r, 0, TAU, 64, Color(target_color.r, target_color.g, target_color.b, 0.35), 1.5)

	for di in range(3):
		draw_arc(center, lerp(orbit_earth_r, orbit_target_r, 0.5) * lerp(0.9, 1.1, float(di) / 2.0),
				 0.3, 0.5 + float(di) * 0.1, 8, Color(0.3, 0.9, 0.6, 0.08), 1.0)

	var earth_ang = pulse_time * 0.08
	var earth_pos = center + Vector2(cos(earth_ang), sin(earth_ang)) * orbit_earth_r
	draw_circle(earth_pos, 8.5, Color(0.1, 0.45, 1.0))
	draw_circle(earth_pos + Vector2(2, -1), 2.5, Color(0.25, 0.75, 0.3, 0.9))
	draw_arc(earth_pos, 10.5, PI * 1.1, PI * 1.9, 24, Color(0.4, 0.75, 1.0, 0.5), 2.0)
	for ci_e in range(2):
		var cw = Vector2(randf_range(-3.0, 3.0), randf_range(-2.0, 0.0))
		draw_arc(earth_pos + cw, 2.5, 0, PI, 10, Color(1.0, 1.0, 1.0, 0.25), 2.0)

	var target_ang = earth_ang + 1.8
	var target_pos = center + Vector2(cos(target_ang), sin(target_ang)) * orbit_target_r
	draw_circle(target_pos, 7.0, target_color)
	draw_circle(target_pos, 7.0, Color(0.0, 0.0, 0.0, 0.2))
	if GameState.target_id == "mars" or GameState.target_id == "moon":
		for ci_c in range(3):
			var cang = ci_c * 2.1
			var crad = 1.5 + ci_c * 0.5
			draw_circle(target_pos + Vector2(cos(cang) * 3.0, sin(cang) * 2.5), crad, Color(0.0, 0.0, 0.0, 0.25))
	elif GameState.target_id == "moon":
		draw_circle(target_pos + Vector2(0, -5), 2.5, Color(0.92, 0.95, 1.0, 0.7))

	var arc_points: PackedVector2Array = []
	for i in range(49):
		var t = float(i) / 48.0
		var r = lerp(orbit_earth_r, orbit_target_r, t)
		var ang = lerp(earth_ang, target_ang, t)
		arc_points.append(center + Vector2(cos(ang), sin(ang)) * r)

	for gi in range(3):
		var ga = 0.12 - gi * 0.04
		draw_polyline(arc_points, Color(0.2, 0.9, 0.5, ga), 4.0 - gi * 1.5)
	draw_polyline(arc_points, Color(0.2, 0.95, 0.6, 0.7), 2.0)

	var current_r = lerp(orbit_earth_r, orbit_target_r, transfer_progress)
	var current_ang = lerp(earth_ang, target_ang, transfer_progress)
	var craft_pos = center + Vector2(cos(current_ang), sin(current_ang)) * current_r

	var craft_pulse = 0.7 + sin(pulse_time * 8.0) * 0.3
	draw_circle(craft_pos, 10.0, Color(0.2, 0.9, 0.6, 0.15 * craft_pulse))
	draw_circle(craft_pos, 5.5, Color(1.0, 1.0, 1.0))
	draw_line(craft_pos - Vector2(9, 0), craft_pos + Vector2(9, 0), Color(0.2, 0.6, 1.0), 2.5)
	draw_line(craft_pos - Vector2(0, 7), craft_pos + Vector2(0, 7), Color(0.6, 0.85, 1.0), 1.5)
	draw_circle(craft_pos, 2.5, Color(1.0, 0.95, 0.5))

	var trail_len = min(transfer_progress, 0.08)
	if trail_len > 0.005:
		var trail_pts: PackedVector2Array = []
		for ti in range(8):
			var tp = transfer_progress - float(ti) / 8.0 * trail_len
			tp = max(0.0, tp)
			var tr = lerp(orbit_earth_r, orbit_target_r, tp)
			var ta = lerp(earth_ang, target_ang, tp)
			trail_pts.append(center + Vector2(cos(ta), sin(ta)) * tr)
		draw_polyline(trail_pts, Color(1.0, 1.0, 1.0, 0.4), 1.5)
