extends Node2D

@export var pad_center_x: float = 640.0
@export var pad_width: float = 220.0
@export var ground_y: float = 580.0
@export var craft_pos: Vector2 = Vector2(640, 100)

var radar_time: float = 0.0
var dust_puffs: Array = []

func _process(delta: float) -> void:
	radar_time += delta
	for puff in dust_puffs:
		puff["life"] -= delta
		puff["pos"] += puff["vel"] * delta
		puff["rad"] = move_toward(puff["rad"], puff["max_rad"], delta * 18.0)
	dust_puffs = dust_puffs.filter(func(p): return p["life"] > 0.0)
	queue_redraw()

func spawn_dust(pos: Vector2) -> void:
	for i in range(4):
		var ang = randf_range(PI, TAU)
		dust_puffs.append({
			"pos": pos,
			"vel": Vector2(cos(ang) * randf_range(15, 55), sin(ang) * randf_range(5, 25)),
			"rad": randf_range(6.0, 12.0),
			"max_rad": randf_range(28.0, 52.0),
			"life": randf_range(0.5, 1.2)
		})

func _draw() -> void:
	var target_id = GameState.target_id

	var terrain_col = Color(0.44, 0.24, 0.16)
	var sky_top = Color(0.20, 0.10, 0.08)
	var sky_bot = Color(0.50, 0.30, 0.16)
	var rock_col = Color(0.30, 0.17, 0.12)
	var rock_light = Color(0.60, 0.40, 0.26)
	var dust_col = Color(0.75, 0.52, 0.35)

	if target_id == "moon":
		terrain_col = Color(0.32, 0.33, 0.37)
		sky_top = Color(0.01, 0.01, 0.03)
		sky_bot = Color(0.02, 0.02, 0.05)
		rock_col = Color(0.22, 0.23, 0.26)
		rock_light = Color(0.50, 0.52, 0.56)
		dust_col = Color(0.65, 0.66, 0.70)
	elif target_id == "venus":
		terrain_col = Color(0.50, 0.38, 0.16)
		sky_top = Color(0.28, 0.18, 0.06)
		sky_bot = Color(0.60, 0.42, 0.14)
		rock_col = Color(0.34, 0.26, 0.11)
		rock_light = Color(0.70, 0.55, 0.26)
		dust_col = Color(0.82, 0.65, 0.30)
	elif target_id == "europa":
		terrain_col = Color(0.62, 0.76, 0.90)
		sky_top = Color(0.03, 0.06, 0.14)
		sky_bot = Color(0.06, 0.12, 0.22)
		rock_col = Color(0.42, 0.58, 0.72)
		rock_light = Color(0.80, 0.90, 0.98)
		dust_col = Color(0.75, 0.88, 0.98)

	var w = 1280.0
	var h = 720.0

	for l in range(10):
		var t = float(l) / 9.0
		var col = sky_top.lerp(sky_bot, t)
		var ly = l * (ground_y / 10.0)
		draw_rect(Rect2(0, ly, w, ground_y / 10.0 + 2.0), col)

	draw_stars_or_atmosphere(target_id, w, ground_y)
	draw_distant_ridgeline(rock_col, rock_light, w, ground_y)

	var pad_left = pad_center_x - pad_width * 0.5
	var pad_right = pad_center_x + pad_width * 0.5

	var terrain_poly = PackedVector2Array([
		Vector2(0, ground_y - 42.0),
		Vector2(100, ground_y - 28.0),
		Vector2(240, ground_y - 55.0),
		Vector2(400, ground_y - 32.0),
		Vector2(pad_left - 40.0, ground_y - 16.0),
		Vector2(pad_left, ground_y),
		Vector2(pad_right, ground_y),
		Vector2(pad_right + 40.0, ground_y - 18.0),
		Vector2(820, ground_y - 48.0),
		Vector2(1000, ground_y - 24.0),
		Vector2(1140, ground_y - 44.0),
		Vector2(w, ground_y - 36.0),
		Vector2(w, h),
		Vector2(0, h)
	])
	draw_colored_polygon(terrain_poly, terrain_col)

	var strata_col = terrain_col.lerp(rock_light, 0.3)
	for s in range(3):
		var sy = ground_y + 20.0 + s * 32.0
		draw_line(Vector2(0, sy), Vector2(w, sy + sin(s * 1.8) * 8.0), rock_col, 3.5)
		draw_line(Vector2(0, sy - 1.5), Vector2(w, sy - 1.5 + sin(s * 1.8) * 8.0), strata_col, 1.2)

	draw_polyline(terrain_poly, rock_col, 2.5)

	draw_scattered_rocks(rock_col, rock_light, terrain_col, ground_y, pad_left, pad_right)

	var pad_mid_col = Color(0.22, 0.88, 0.58, 0.55)
	draw_rect(Rect2(pad_left, ground_y, pad_width, 7.0), pad_mid_col)
	draw_line(Vector2(pad_left, ground_y), Vector2(pad_right, ground_y), Color(0.22, 0.95, 0.60), 3.5)
	draw_line(Vector2(pad_center_x, ground_y - 1.0), Vector2(pad_center_x, ground_y + 7.0), Color(0.22, 0.95, 0.60, 0.65), 1.5)

	var beacon_pulse = 0.5 + sin(radar_time * 5.5) * 0.5
	var beacon_col = Color(0.18, 0.95, 0.60, beacon_pulse)
	draw_beacon_light(Vector2(pad_left, ground_y - 10.0), beacon_col)
	draw_beacon_light(Vector2(pad_right, ground_y - 10.0), beacon_col)
	draw_beacon_light(Vector2(pad_center_x - pad_width * 0.25, ground_y - 4.0), Color(0.18, 0.95, 0.60, beacon_pulse * 0.6))
	draw_beacon_light(Vector2(pad_center_x + pad_width * 0.25, ground_y - 4.0), Color(0.18, 0.95, 0.60, beacon_pulse * 0.6))

	if craft_pos.y < ground_y:
		var beam_alpha = clamp(1.0 - (craft_pos.y / ground_y), 0.15, 0.80)
		var beam_w = lerp(1.0, 4.0, beam_alpha * 0.8)
		draw_line(craft_pos, Vector2(craft_pos.x, ground_y), Color(0.0, 0.92, 1.0, beam_alpha * 0.50), beam_w)
		var ring_r = 10.0 + sin(radar_time * 9.0) * 3.5
		draw_arc(Vector2(craft_pos.x, ground_y), ring_r, 0, TAU, 28, Color(0.0, 0.92, 1.0, beam_alpha), 2.5)

	for puff in dust_puffs:
		if puff["life"] > 0.0:
			draw_circle(puff["pos"], puff["rad"], Color(dust_col.r, dust_col.g, dust_col.b, puff["life"] * 0.4))

func draw_stars_or_atmosphere(t_id: String, w: float, ground_y: float) -> void:
	if t_id == "moon":
		for s in range(45):
			var sx = fmod(s * 71.3, w)
			var sy = fmod(s * 39.7, ground_y - 60.0)
			draw_circle(Vector2(sx, sy), 1.3, Color(1, 1, 1, 0.8))
		var earth_c = Vector2(1050, 140)
		draw_circle(earth_c, 44.0, Color(0.12, 0.44, 0.84))
		draw_circle(earth_c + Vector2(-10, -6), 20.0, Color(0.22, 0.65, 0.35, 0.90))
		draw_arc(earth_c, 46.0, 0, TAU, 32, Color(0.4, 0.78, 1.0, 0.65), 2.5)
	elif t_id == "venus":
		for c in range(5):
			var cy = 60.0 + c * 55.0
			draw_line(Vector2(0, cy), Vector2(w, cy + sin(c) * 20.0), Color(0.75, 0.65, 0.35, 0.18), 22.0)
	elif t_id == "europa":
		var jup_c = Vector2(220, 180)
		draw_circle(jup_c, 65.0, Color(0.80, 0.62, 0.42))
		for b in range(5):
			var by = jup_c.y - 55.0 + b * 22.0
			var bw = sqrt(max(0.0, 65.0 * 65.0 - pow(by - jup_c.y, 2.0)))
			draw_line(Vector2(jup_c.x - bw, by), Vector2(jup_c.x + bw, by), Color(0.60, 0.42, 0.28), 10.0)
		draw_arc(jup_c, 67.0, 0, TAU, 48, Color(0.88, 0.75, 0.55, 0.45), 2.0)

func draw_distant_ridgeline(rock_col: Color, rock_light: Color, w: float, ground_y: float) -> void:
	var pts = PackedVector2Array([
		Vector2(0, ground_y - 60),
		Vector2(130, ground_y - 95),
		Vector2(310, ground_y - 72),
		Vector2(520, ground_y - 115),
		Vector2(740, ground_y - 85),
		Vector2(960, ground_y - 108),
		Vector2(w, ground_y - 70),
		Vector2(w, ground_y),
		Vector2(0, ground_y)
	])
	draw_colored_polygon(pts, rock_col * Color(0.85, 0.85, 0.85))
	draw_polyline(pts, rock_light * Color(1, 1, 1, 0.5), 1.5)

func draw_scattered_rocks(rock_col: Color, rock_light: Color, terrain_col: Color, ground_y: float, pad_left: float, pad_right: float) -> void:
	var rock_positions = [
		Vector2(160, ground_y - 8), Vector2(345, ground_y - 12),
		Vector2(520, ground_y - 6), Vector2(620, ground_y - 9),
		Vector2(880, ground_y - 10), Vector2(1020, ground_y - 7),
		Vector2(1150, ground_y - 11)
	]
	for rp in rock_positions:
		if rp.x > pad_left - 55 and rp.x < pad_right + 55:
			continue
		var rx = rp.x
		var ry = rp.y
		var size = randf_range(8, 22) if false else 12.0 + (rx * 0.01)
		draw_rock_poly(Vector2(rx, ry), size, rock_col, rock_light)

func draw_rock_poly(pos: Vector2, size: float, base_col: Color, hi_col: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(-size, 2),
		pos + Vector2(-size * 0.5, -size * 0.8),
		pos + Vector2(size * 0.3, -size * 0.9),
		pos + Vector2(size, -size * 0.3),
		pos + Vector2(size * 0.9, 2)
	])
	draw_colored_polygon(pts, base_col)
	draw_line(pos + Vector2(-size * 0.5, -size * 0.8), pos + Vector2(size * 0.3, -size * 0.9), hi_col, 1.5)
	draw_polyline(pts, base_col * Color(0.6, 0.6, 0.6), 1.0)

func draw_beacon_light(pos: Vector2, col: Color) -> void:
	draw_circle(pos, 8.0, Color(col.r, col.g, col.b, col.a * 0.3))
	draw_circle(pos, 5.5, Color(col.r, col.g, col.b, col.a * 0.7))
	draw_circle(pos, 3.0, col)
