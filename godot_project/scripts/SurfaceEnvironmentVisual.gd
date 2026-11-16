extends Node2D

@export var rover_x: float = 200.0
@export var is_orbit: bool = false
var anim_time: float = 0.0

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var target_id = GameState.target_id
	var vp = get_viewport_rect().size
	var w = max(2560.0, vp.x)
	var h = max(1440.0, vp.y)
	var ground_y = 540.0

	if target_id == "interstellar":
		draw_interstellar_space_environment(w, h)
	elif is_orbit:
		draw_orbital_environment(target_id, w, h)
	else:
		draw_sky_and_space(target_id, w, ground_y)
		draw_distant_mountains(target_id, w, ground_y)
		draw_midground_dunes(target_id, w, ground_y)
		draw_foreground_surface(target_id, w, ground_y, h)
		draw_dust_haze(target_id, w, ground_y)
		draw_sample_rocks(target_id, ground_y)

func draw_interstellar_space_environment(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0.01, 0.012, 0.025))

	for c in range(6):
		var cx = fmod(c * 380.0 + anim_time * 5.0, w)
		var cy = 180.0 + sin(c * 1.5 + anim_time * 0.2) * 90.0
		var c_col = Color(0.12, 0.05, 0.25, 0.12) if c % 2 == 0 else Color(0.02, 0.15, 0.28, 0.10)
		draw_circle(Vector2(cx, cy), 180.0, c_col)

	for s in range(120):
		var sx = fmod(s * 79.3, w)
		var sy = fmod(s * 47.9, h)
		var sa = 0.35 + sin(s * 4.2 + anim_time * 2.5) * 0.3
		var col = Color(1.0, 1.0, 1.0, clamp(sa, 0.1, 0.95))
		if s % 3 == 0:
			col = Color(0.7, 0.85, 1.0, clamp(sa, 0.1, 0.95))
		elif s % 5 == 0:
			col = Color(1.0, 0.9, 0.7, clamp(sa, 0.1, 0.95))
		draw_circle(Vector2(sx, sy), 1.2 + fmod(s, 1.5), col)

	var wave_pts: PackedVector2Array = []
	var wave_pts_glow: PackedVector2Array = []
	for x_i in range(int(w / 40.0) + 2):
		var px = x_i * 40.0
		var py = 480.0 + sin(px * 0.005 + anim_time * 0.6) * 35.0 + cos(px * 0.012 - anim_time * 0.4) * 18.0
		wave_pts.append(Vector2(px, py))
		wave_pts_glow.append(Vector2(px, py))

	draw_polyline(wave_pts, Color(0.15, 0.65, 1.0, 0.45), 6.0)
	draw_polyline(wave_pts, Color(0.4, 0.85, 1.0, 0.85), 2.0)

	var ray_t = fmod(anim_time * 3.0, 1.0)
	var ray_start = Vector2(w * 0.3 + anim_time * 80.0, 150.0)
	ray_start.x = fmod(ray_start.x, w)
	var ray_end = ray_start + Vector2(160.0, 90.0)
	draw_line(ray_start, ray_end, Color(0.9, 0.95, 1.0, 0.35 * (1.0 - ray_t)), 1.5)

func draw_orbital_environment(t_id: String, w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color(0.015, 0.02, 0.04))

	for s in range(65):
		var sx = fmod(s * 73.1, w)
		var sy = fmod(s * 39.7, 360.0)
		var sa = 0.4 + sin(s * 3.0 + anim_time * 2.0) * 0.35
		draw_circle(Vector2(sx, sy), 1.3, Color(1, 1, 1, sa))

	var planet_cen = Vector2(w * 0.5, 1120.0)
	var planet_r = 740.0

	var planet_col = Color(0.58, 0.28, 0.16)
	var limb_col = Color(0.35, 0.72, 1.0, 0.6)
	if t_id == "moon":
		planet_col = Color(0.32, 0.33, 0.36)
		limb_col = Color(0.7, 0.8, 0.9, 0.3)
	elif t_id == "venus":
		planet_col = Color(0.65, 0.52, 0.22)
		limb_col = Color(0.95, 0.82, 0.4, 0.5)
	elif t_id == "europa":
		planet_col = Color(0.55, 0.68, 0.82)
		limb_col = Color(0.75, 0.9, 1.0, 0.65)
	elif t_id == "asteroid" or t_id == "bennu":
		planet_col = Color(0.24, 0.24, 0.26)
		limb_col = Color(0.5, 0.5, 0.55, 0.3)

	draw_circle(planet_cen, planet_r, planet_col)

	for b in range(5):
		var by = 420.0 + b * 28.0
		var b_dark = planet_col * Color(0.82, 0.82, 0.82, 0.4)
		draw_line(Vector2(60, by), Vector2(w - 60, by + sin(b) * 12.0), b_dark, 14.0)

	draw_arc(planet_cen, planet_r + 2.0, PI * 1.14, PI * 1.86, 64, limb_col, 5.0)
	draw_arc(planet_cen, planet_r + 8.0, PI * 1.16, PI * 1.84, 48, limb_col * Color(1, 1, 1, 0.35), 3.0)

	var targets = [
		{"pos": Vector2(380, 465), "name": "Вулкан Олімп"},
		{"pos": Vector2(680, 485), "name": "Каньйон Марінера"},
		{"pos": Vector2(1000, 460), "name": "Полярна шапка"}
	]

	for trg in targets:
		var tp = trg["pos"]
		var pulse = 0.7 + sin(anim_time * 4.0 + tp.x) * 0.3
		draw_circle(tp, 16.0, Color(0.18, 0.92, 0.55, 0.15 * pulse))
		draw_arc(tp, 20.0, 0, TAU, 24, Color(0.18, 0.92, 0.55, 0.75 * pulse), 1.8)
		draw_line(tp - Vector2(26, 0), tp + Vector2(26, 0), Color(0.18, 0.92, 0.55, 0.6), 1.0)
		draw_line(tp - Vector2(0, 26), tp + Vector2(0, 26), Color(0.18, 0.92, 0.55, 0.6), 1.0)

func draw_sky_and_space(t_id: String, w: float, ground_y: float) -> void:
	match t_id:
		"moon":
			draw_rect(Rect2(0, 0, w, ground_y), Color(0.01, 0.01, 0.03))
			for s in range(50):
				var sx = fmod(s * 73.1, w)
				var sy = fmod(s * 41.7, ground_y - 80.0)
				var sa = 0.4 + sin(s * 3.0 + anim_time * 2.0) * 0.3
				draw_circle(Vector2(sx, sy), 1.2, Color(1, 1, 1, sa))

			var earth_c = Vector2(980, 160)
			draw_circle(earth_c, 52.0, Color(0.12, 0.45, 0.85))
			draw_circle(earth_c + Vector2(-12, -8), 24.0, Color(0.22, 0.65, 0.35, 0.85))
			draw_circle(earth_c + Vector2(16, 12), 18.0, Color(0.22, 0.65, 0.35, 0.75))
			draw_arc(earth_c, 54.0, 0, TAU, 32, Color(0.4, 0.75, 1.0, 0.6), 2.5)
			draw_arc(earth_c, 58.0, 0, TAU, 32, Color(0.4, 0.75, 1.0, 0.25), 4.0)

		"europa":
			draw_rect(Rect2(0, 0, w, ground_y), Color(0.02, 0.03, 0.07))
			for s in range(40):
				var sx = fmod(s * 83.3, w)
				var sy = fmod(s * 37.1, ground_y - 60.0)
				draw_circle(Vector2(sx, sy), 1.0, Color(0.9, 0.95, 1.0, 0.7))

			var jup_c = Vector2(320, 180)
			var jup_r = 75.0
			draw_circle(jup_c, jup_r, Color(0.85, 0.65, 0.45))
			for b in range(6):
				var by = jup_c.y - jup_r + 20.0 + b * 20.0
				var band_w = sqrt(max(0.0, jup_r * jup_r - pow(by - jup_c.y, 2.0)))
				var band_col = Color(0.65, 0.45, 0.30) if b % 2 == 0 else Color(0.92, 0.80, 0.65)
				draw_line(Vector2(jup_c.x - band_w, by), Vector2(jup_c.x + band_w, by), band_col, 8.0)
			draw_circle(jup_c + Vector2(25, 15), 11.0, Color(0.78, 0.32, 0.20))
			draw_arc(jup_c, jup_r + 2.0, 0, TAU, 48, Color(0.9, 0.75, 0.55, 0.5), 2.0)

		"venus":
			var top_c = Color(0.42, 0.32, 0.12)
			var bot_c = Color(0.72, 0.54, 0.18)
			for l in range(8):
				var ly = l * (ground_y / 8.0)
				var col = top_c.lerp(bot_c, float(l) / 7.0)
				draw_rect(Rect2(0, ly, w, ground_y / 8.0 + 2.0), col)

		"mars":
			var top_c = Color(0.26, 0.14, 0.10)
			var bot_c = Color(0.55, 0.32, 0.18)
			for l in range(8):
				var ly = l * (ground_y / 8.0)
				var col = top_c.lerp(bot_c, float(l) / 7.0)
				draw_rect(Rect2(0, ly, w, ground_y / 8.0 + 2.0), col)

			draw_circle(Vector2(780, 110), 9.0, Color(0.65, 0.58, 0.52))
			draw_circle(Vector2(780, 110), 10.5, Color(0.85, 0.65, 0.45, 0.35))

		_:
			draw_rect(Rect2(0, 0, w, ground_y), Color(0.02, 0.02, 0.04))
			for s in range(60):
				var sx = fmod(s * 67.3, w)
				var sy = fmod(s * 51.2, ground_y - 40.0)
				draw_circle(Vector2(sx, sy), 1.2, Color(1, 1, 1, 0.75))

func draw_distant_mountains(t_id: String, w: float, ground_y: float) -> void:
	var mtn_col = Color(0.32, 0.18, 0.12)
	if t_id == "moon":
		mtn_col = Color(0.18, 0.18, 0.22)
	elif t_id == "venus":
		mtn_col = Color(0.42, 0.30, 0.12)
	elif t_id == "europa":
		mtn_col = Color(0.25, 0.38, 0.52)
	elif t_id == "asteroid" or t_id == "bennu":
		mtn_col = Color(0.14, 0.14, 0.16)

	var pts = PackedVector2Array([
		Vector2(0, ground_y - 60),
		Vector2(180, ground_y - 120),
		Vector2(360, ground_y - 80),
		Vector2(580, ground_y - 140),
		Vector2(820, ground_y - 95),
		Vector2(1040, ground_y - 130),
		Vector2(w, ground_y - 70),
		Vector2(w, ground_y),
		Vector2(0, ground_y)
	])
	draw_colored_polygon(pts, mtn_col)

func draw_midground_dunes(t_id: String, w: float, ground_y: float) -> void:
	var dune_col = Color(0.44, 0.24, 0.15)
	var edge_col = Color(0.58, 0.34, 0.20)
	if t_id == "moon":
		dune_col = Color(0.24, 0.25, 0.28)
		edge_col = Color(0.38, 0.40, 0.45)
	elif t_id == "venus":
		dune_col = Color(0.50, 0.36, 0.15)
		edge_col = Color(0.65, 0.48, 0.22)
	elif t_id == "europa":
		dune_col = Color(0.40, 0.55, 0.68)
		edge_col = Color(0.60, 0.75, 0.88)
	elif t_id == "asteroid" or t_id == "bennu":
		dune_col = Color(0.20, 0.20, 0.22)
		edge_col = Color(0.30, 0.30, 0.34)

	var pts = PackedVector2Array([
		Vector2(0, ground_y - 30),
		Vector2(240, ground_y - 55),
		Vector2(520, ground_y - 25),
		Vector2(780, ground_y - 60),
		Vector2(1050, ground_y - 35),
		Vector2(w, ground_y - 45),
		Vector2(w, ground_y),
		Vector2(0, ground_y)
	])
	draw_colored_polygon(pts, dune_col)
	draw_polyline(pts, edge_col, 2.0)

func draw_foreground_surface(t_id: String, w: float, ground_y: float, h: float) -> void:
	var base_col = Color(0.52, 0.28, 0.16)
	var shadow_col = Color(0.38, 0.20, 0.12)
	var hl_col = Color(0.65, 0.38, 0.22)

	if t_id == "moon":
		base_col = Color(0.32, 0.33, 0.36)
		shadow_col = Color(0.22, 0.23, 0.25)
		hl_col = Color(0.45, 0.46, 0.50)
	elif t_id == "venus":
		base_col = Color(0.56, 0.40, 0.16)
		shadow_col = Color(0.40, 0.28, 0.10)
		hl_col = Color(0.70, 0.52, 0.24)
	elif t_id == "europa":
		base_col = Color(0.55, 0.68, 0.80)
		shadow_col = Color(0.35, 0.46, 0.58)
		hl_col = Color(0.75, 0.88, 0.98)
	elif t_id == "asteroid" or t_id == "bennu":
		base_col = Color(0.26, 0.26, 0.28)
		shadow_col = Color(0.18, 0.18, 0.20)
		hl_col = Color(0.38, 0.38, 0.42)

	draw_rect(Rect2(0, ground_y, w, h - ground_y), base_col)

	for str_idx in range(6):
		var sy = ground_y + 12.0 + str_idx * 26.0
		draw_line(Vector2(0, sy), Vector2(w, sy + sin(str_idx) * 6.0), shadow_col, 3.5)
		draw_line(Vector2(0, sy - 1.0), Vector2(w, sy - 1.0 + sin(str_idx) * 6.0), hl_col, 1.2)

	var track_y1 = ground_y + 4.0
	var track_y2 = ground_y + 8.0
	draw_line(Vector2(80, track_y1), Vector2(rover_x, track_y1), Color(0.15, 0.10, 0.08, 0.45), 2.5)
	draw_line(Vector2(80, track_y2), Vector2(rover_x, track_y2), Color(0.15, 0.10, 0.08, 0.45), 2.5)

func draw_dust_haze(t_id: String, w: float, ground_y: float) -> void:
	var haze_col = Color(0.72, 0.42, 0.22, 0.10)
	if t_id == "moon":
		haze_col = Color(0.5, 0.5, 0.55, 0.06)
	elif t_id == "venus":
		haze_col = Color(0.80, 0.60, 0.20, 0.14)
	elif t_id == "europa":
		haze_col = Color(0.55, 0.75, 0.95, 0.08)
	elif t_id == "asteroid" or t_id == "bennu":
		haze_col = Color(0.4, 0.4, 0.42, 0.06)

	var layers = [
		{"y_off": -18.0, "h": 28.0, "alpha": 1.0},
		{"y_off": -38.0, "h": 32.0, "alpha": 0.6},
		{"y_off": -62.0, "h": 40.0, "alpha": 0.3},
		{"y_off": -95.0, "h": 50.0, "alpha": 0.14},
	]
	for layer in layers:
		var ly = ground_y + layer["y_off"]
		var lh = layer["h"]
		var la = layer["alpha"]
		var pts = PackedVector2Array([
			Vector2(0, ly),
			Vector2(w * 0.28, ly - 5.0),
			Vector2(w * 0.55, ly + 4.0),
			Vector2(w * 0.78, ly - 3.0),
			Vector2(w, ly + 2.0),
			Vector2(w, ly + lh),
			Vector2(0, ly + lh)
		])
		var c = haze_col
		c.a = haze_col.a * la
		draw_colored_polygon(pts, c)

func draw_sample_rocks(t_id: String, ground_y: float) -> void:
	draw_basalt_rock(Vector2(425, ground_y - 4))
	draw_varied_rock(Vector2(310, ground_y - 3), Color(0.22, 0.18, 0.15), Color(0.38, 0.32, 0.26), 1)
	draw_varied_rock(Vector2(560, ground_y - 2), Color(0.30, 0.20, 0.14), Color(0.52, 0.38, 0.26), 2)
	draw_crater_bedrock(Vector2(755, ground_y - 6))
	draw_varied_rock(Vector2(900, ground_y - 3), Color(0.20, 0.20, 0.22), Color(0.36, 0.36, 0.40), 3)
	draw_clay_sediment(Vector2(1055, ground_y - 5))
	draw_varied_rock(Vector2(190, ground_y - 2), Color(0.28, 0.22, 0.18), Color(0.44, 0.36, 0.28), 4)

func draw_varied_rock(pos: Vector2, base_col: Color, hi_col: Color, seed_offset: int) -> void:
	var n = 6
	var pts = PackedVector2Array()
	var shadow_pts = PackedVector2Array()
	for i in range(n):
		var base_ang = (float(i) / float(n)) * TAU - PI * 0.5
		var jitter_ang = base_ang + (fmod(float(seed_offset * 7 + i * 13), 7.0) - 3.5) * 0.18
		var r_base = 18.0 + fmod(float(seed_offset * 11 + i * 17), 10.0)
		pts.append(pos + Vector2(cos(jitter_ang) * r_base, sin(jitter_ang) * r_base * 0.55))
		shadow_pts.append(pos + Vector2(5.0 + cos(jitter_ang) * r_base * 0.9, 6.0 + sin(jitter_ang) * r_base * 0.42))
	draw_colored_polygon(shadow_pts, Color(0.08, 0.06, 0.05, 0.45))
	draw_colored_polygon(pts, base_col)
	draw_polyline(pts, hi_col, 1.4)
	var top_pts = PackedVector2Array()
	for i in range(n / 2):
		top_pts.append(pts[i])
	draw_polyline(top_pts, hi_col * Color(1.3, 1.3, 1.3, 0.7), 1.0)

func draw_basalt_rock(pos: Vector2) -> void:
	var dark_basalt = Color(0.16, 0.17, 0.22)
	var med_basalt = Color(0.28, 0.30, 0.38)
	var hi_basalt = Color(0.55, 0.60, 0.72)

	draw_oval(pos + Vector2(4, 6), 34.0, 8.0, Color(0.1, 0.08, 0.06, 0.5))

	var face1 = PackedVector2Array([
		pos + Vector2(-28, 4),
		pos + Vector2(-12, -26),
		pos + Vector2(8, -18),
		pos + Vector2(-6, 4)
	])
	draw_colored_polygon(face1, med_basalt)
	draw_polyline(face1, hi_basalt, 1.5)

	var face2 = PackedVector2Array([
		pos + Vector2(-12, -26),
		pos + Vector2(16, -28),
		pos + Vector2(30, -6),
		pos + Vector2(8, -18)
	])
	draw_colored_polygon(face2, hi_basalt * Color(1, 1, 1, 0.9))

	var face3 = PackedVector2Array([
		pos + Vector2(8, -18),
		pos + Vector2(30, -6),
		pos + Vector2(26, 4),
		pos + Vector2(-6, 4)
	])
	draw_colored_polygon(face3, dark_basalt)
	draw_polyline(face3, Color(0.4, 0.45, 0.55), 1.2)

	draw_circle(pos + Vector2(-4, -12), 2.0, Color(0.2, 0.9, 1.0, 0.8))
	draw_circle(pos + Vector2(12, -14), 1.5, Color(1.0, 0.9, 0.4, 0.8))

func draw_crater_bedrock(pos: Vector2) -> void:
	var base_rock = Color(0.45, 0.32, 0.24)
	var dark_rock = Color(0.26, 0.18, 0.14)
	var hl_strata = Color(0.68, 0.52, 0.40)

	draw_oval(pos + Vector2(6, 6), 40.0, 10.0, Color(0.1, 0.08, 0.06, 0.5))

	var poly = PackedVector2Array([
		pos + Vector2(-36, 4),
		pos + Vector2(-28, -20),
		pos + Vector2(-6, -34),
		pos + Vector2(22, -30),
		pos + Vector2(38, -12),
		pos + Vector2(34, 4)
	])
	draw_colored_polygon(poly, base_rock)
	draw_polyline(poly, dark_rock, 2.5)

	draw_line(pos + Vector2(-24, -14), pos + Vector2(32, -8), hl_strata, 2.5)
	draw_line(pos + Vector2(-18, -22), pos + Vector2(24, -18), dark_rock, 2.0)
	draw_line(pos + Vector2(-28, -4), pos + Vector2(34, 0), hl_strata, 2.0)

	draw_oval(pos + Vector2(-8, -18), 5.0, 3.0, dark_rock)
	draw_oval(pos + Vector2(14, -12), 4.0, 2.5, dark_rock)

func draw_clay_sediment(pos: Vector2) -> void:
	var clay_base = Color(0.55, 0.28, 0.18)
	var clay_dark = Color(0.35, 0.16, 0.10)
	var clay_light = Color(0.75, 0.45, 0.28)

	draw_oval(pos + Vector2(4, 5), 44.0, 9.0, Color(0.1, 0.08, 0.06, 0.45))

	var poly = PackedVector2Array([
		pos + Vector2(-40, 4),
		pos + Vector2(-32, -14),
		pos + Vector2(-10, -24),
		pos + Vector2(18, -22),
		pos + Vector2(42, -8),
		pos + Vector2(38, 4)
	])
	draw_colored_polygon(poly, clay_base)
	draw_polyline(poly, clay_dark, 2.0)

	for r in range(4):
		var ry = -18.0 + r * 6.5
		var rw = 32.0 - r * 3.0
		draw_line(pos + Vector2(-rw, ry), pos + Vector2(rw, ry + 2.0), clay_light, 1.8)
		draw_line(pos + Vector2(-rw, ry + 2.0), pos + Vector2(rw, ry + 4.0), clay_dark, 1.2)

func draw_dsn_antenna(base_pos: Vector2, ground_y: float) -> void:
	var dish_r = 54.0
	var mast_h = 95.0
	var az_offset_deg = sin(anim_time * 0.3) * 15.0
	var az_rad = deg_to_rad(az_offset_deg)

	var col_metal = Color(0.72, 0.74, 0.78)
	var col_metal_dark = Color(0.42, 0.44, 0.48)
	var col_metal_hi = Color(0.88, 0.90, 0.95)
	var col_dish = Color(0.78, 0.80, 0.84)
	var col_strut = Color(0.50, 0.52, 0.56)
	var col_cable = Color(0.30, 0.30, 0.32, 0.7)
	var col_active = Color(0.28, 0.85, 0.55, 0.9)

	var base_center = base_pos

	draw_rect(Rect2(base_center.x - 22.0, base_center.y - 8.0, 44.0, 10.0), col_metal_dark)
	draw_rect(Rect2(base_center.x - 14.0, base_center.y - 18.0, 28.0, 12.0), col_metal)
	draw_arc(Vector2(base_center.x, base_center.y - 18.0), 14.0, PI, TAU, 16, col_metal_hi, 2.0)

	var az_pivot = Vector2(base_center.x, base_center.y - 22.0)

	var strut_left = az_pivot + Vector2(-38.0, mast_h * 0.7).rotated(az_rad)
	var strut_right = az_pivot + Vector2(38.0, mast_h * 0.7).rotated(az_rad)
	var strut_back = az_pivot + Vector2(0.0, mast_h * 0.8).rotated(az_rad)
	var elev_pivot = az_pivot + Vector2(0.0, -mast_h * 0.72).rotated(az_rad)

	draw_line(az_pivot, strut_left, col_strut, 3.0)
	draw_line(az_pivot, strut_right, col_strut, 3.0)
	draw_line(az_pivot, strut_back, col_strut, 2.5)
	draw_line(elev_pivot, strut_left, col_strut, 2.0)
	draw_line(elev_pivot, strut_right, col_strut, 2.0)
	draw_line(az_pivot, elev_pivot, col_metal, 5.0)

	draw_circle(elev_pivot, 6.0, col_metal_dark)
	draw_circle(elev_pivot, 4.0, col_metal)

	var dish_dir = Vector2(0.0, -1.0).rotated(az_rad)
	var dish_right = Vector2(1.0, 0.0).rotated(az_rad)

	var rim_left = elev_pivot - dish_right * dish_r
	var rim_right = elev_pivot + dish_right * dish_r
	var dish_tip = elev_pivot + dish_dir * dish_r * 0.38

	var parabola_pts = PackedVector2Array()
	var seg = 28
	for i in range(seg + 1):
		var t = float(i) / float(seg)
		var local_x = (t - 0.5) * 2.0 * dish_r
		var local_y = (local_x * local_x) / (dish_r * 2.1)
		parabola_pts.append(elev_pivot + dish_right * local_x + dish_dir * (-local_y))

	var dish_fill_pts = PackedVector2Array()
	for p in parabola_pts:
		dish_fill_pts.append(p)
	dish_fill_pts.append(elev_pivot + dish_dir * (-dish_r * 0.6))
	draw_colored_polygon(dish_fill_pts, col_dish * Color(1, 1, 1, 0.92))
	draw_polyline(parabola_pts, col_metal_hi, 2.5)

	var rings = [0.90, 0.65, 0.35]
	for ring_frac in rings:
		var r_half = dish_r * ring_frac
		var ring_pts = PackedVector2Array()
		for i in range(seg + 1):
			var t = float(i) / float(seg)
			var local_x = (t - 0.5) * 2.0 * r_half
			var local_y = (local_x * local_x) / (dish_r * 2.1)
			ring_pts.append(elev_pivot + dish_right * local_x + dish_dir * (-local_y))
		draw_polyline(ring_pts, col_metal_dark * Color(1, 1, 1, 0.55), 1.0)

	var feedhorn_base = elev_pivot + dish_dir * (dish_r * 0.30)
	var feedhorn_tip = feedhorn_base + dish_dir * 12.0
	var feedhorn_poly = PackedVector2Array([
		feedhorn_base - dish_right * 7.0,
		feedhorn_base + dish_right * 7.0,
		feedhorn_tip + dish_right * 2.5,
		feedhorn_tip - dish_right * 2.5
	])
	draw_colored_polygon(feedhorn_poly, col_metal_dark)
	draw_polyline(feedhorn_poly, col_metal_hi, 1.2)

	var lna_center = feedhorn_base + dish_dir * (-8.0)
	draw_rect(Rect2(lna_center.x - 6.0, lna_center.y - 4.0, 12.0, 8.0), col_metal_dark)
	draw_rect(Rect2(lna_center.x - 4.0, lna_center.y - 2.0, 4.0, 4.0), col_metal * Color(1, 1, 1, 0.5))
	draw_line(lna_center + dish_right * 6.0, lna_center + dish_right * 10.0, col_metal, 1.5)

	var support_mid = elev_pivot + dish_dir * (dish_r * 0.15)
	draw_line(feedhorn_tip, support_mid, col_strut, 1.5)
	draw_line(feedhorn_tip, support_mid + dish_right * dish_r * 0.55, col_strut, 1.0)
	draw_line(feedhorn_tip, support_mid - dish_right * dish_r * 0.55, col_strut, 1.0)

	var ctrl_bld_x = base_center.x + 110.0
	var ctrl_bld_y = ground_y - 2.0
	draw_line(rim_right, Vector2(ctrl_bld_x, ctrl_bld_y), col_cable, 1.2)
	draw_line(elev_pivot, Vector2(ctrl_bld_x - 20.0, ctrl_bld_y), col_cable, 1.0)

	var is_active = true
	if is_active:
		var beam_origin = feedhorn_tip
		var beam_step = 18.0
		var beam_count = 9
		for bi in range(beam_count):
			var frac = float(bi) / float(beam_count - 1)
			var beam_alpha = (1.0 - frac) * 0.85
			var dot_phase = fmod(anim_time * 1.8 - float(bi) * 0.4, 2.0)
			var dot_visible = dot_phase < 1.0
			if dot_visible:
				var dot_pos = beam_origin + dish_dir * (float(bi) * beam_step + fmod(anim_time * 28.0, beam_step))
				var dot_r = 2.5 * (1.0 - frac * 0.6)
				draw_circle(dot_pos, dot_r, Color(col_active.r, col_active.g, col_active.b, beam_alpha))

		var glow_col = Color(col_active.r, col_active.g, col_active.b, 0.12 + sin(anim_time * 3.0) * 0.06)
		draw_circle(feedhorn_tip, 10.0, glow_col)
		draw_circle(feedhorn_tip, 6.0, Color(col_active.r, col_active.g, col_active.b, 0.3))

func draw_oval(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts = PackedVector2Array()
	for i in range(24):
		var ang = i * (TAU / 24.0)
		pts.append(center + Vector2(cos(ang) * rx, sin(ang) * ry))
	draw_colored_polygon(pts, color)
