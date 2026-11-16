extends Node2D

@onready var parent_view = get_parent().get_parent()

var anim_time: float = 0.0
var steam_puffs: Array = []

func _ready() -> void:
	for i in range(14):
		steam_puffs.append({
			"offset_x": randf_range(-90.0, 90.0),
			"phase": randf() * TAU,
			"speed": randf_range(0.6, 1.4),
			"base_r": randf_range(18.0, 36.0)
		})

func _process(delta: float) -> void:
	anim_time += delta
	queue_redraw()

func _draw() -> void:
	var alt = 0.0
	var is_flying = false
	var arm_angle = 0.0

	if parent_view and "altitude_km" in parent_view:
		alt = parent_view.altitude_km
		is_flying = parent_view.is_launching
		arm_angle = parent_view.umbilical_angle

	var space_blend = clamp(alt / 100.0, 0.0, 1.0)

	var rect = get_viewport_rect()
	var sky_layers = 10
	for li in range(sky_layers):
		var t0 = float(li) / sky_layers
		var t1 = float(li + 1) / sky_layers
		var top_day = Color(0.12, 0.25, 0.45)
		var bot_day = Color(0.42, 0.56, 0.72)
		var top_space = Color(0.01, 0.02, 0.05)
		var bot_space = Color(0.03, 0.06, 0.14)
		var horizon_tint = Color(0.72, 0.42, 0.18)
		var is_near_horizon = t0 > 0.65 and t0 < 0.9
		var day_col_top = top_day.lerp(bot_day, t0)
		var day_col_bot = top_day.lerp(bot_day, t1)
		if is_near_horizon and space_blend < 0.5:
			var ht = clamp((t0 - 0.65) / 0.25, 0.0, 1.0)
			day_col_top = day_col_top.lerp(horizon_tint, ht * (1.0 - space_blend * 2.0))
			day_col_bot = day_col_bot.lerp(horizon_tint, ht * (1.0 - space_blend * 2.0))
		var col_top = day_col_top.lerp(top_space.lerp(bot_space, t0), space_blend)
		var col_bot = day_col_bot.lerp(top_space.lerp(bot_space, t1), space_blend)
		var strip_pts = PackedVector2Array([
			Vector2(0, rect.size.y * t0),
			Vector2(rect.size.x, rect.size.y * t0),
			Vector2(rect.size.x, rect.size.y * t1),
			Vector2(0, rect.size.y * t1)
		])
		var strip_cols = PackedColorArray([col_top, col_top, col_bot, col_bot])
		draw_polygon(strip_pts, strip_cols)

	if space_blend > 0.15:
		var star_alpha = clamp((space_blend - 0.15) * 1.2, 0.0, 1.0)
		if "stars" in parent_view:
			for sp in parent_view.stars:
				var twinkle = 0.5 + sin(anim_time * 3.0 + sp.x * 0.05) * 0.5
				draw_circle(sp, 1.4, Color(1.0, 1.0, 1.0, star_alpha * 0.8 * twinkle))
				if star_alpha > 0.6 and sp.x.posmod(80.0) < 10.0:
					draw_circle(sp, 3.0, Color(1.0, 1.0, 1.0, star_alpha * 0.12))

	if space_blend > 0.35:
		var sb = space_blend
		var earth_curve_y = rect.size.y + 420.0 - (sb * 200.0)
		var earth_r = rect.size.x * 0.95
		var earth_cen = Vector2(rect.size.x * 0.5, earth_curve_y)
		draw_circle(earth_cen, earth_r, Color(0.07, 0.3, 0.60))
		for ci in range(3):
			var cont_ang = PI * (1.2 + ci * 0.25)
			var cont_r = earth_r * (0.08 + ci * 0.04)
			draw_circle(earth_cen + Vector2(cos(cont_ang) * earth_r * 0.5, sin(cont_ang) * earth_r * 0.5),
					   cont_r, Color(0.2, 0.65, 0.3, 0.6))
		for cw in range(4):
			var cwa = PI * (1.1 + cw * 0.22)
			draw_arc(earth_cen + Vector2(cos(cwa) * earth_r * 0.3, sin(cwa) * earth_r * 0.3 - 15.0),
					 earth_r * 0.07, 0, PI, 10, Color(1.0, 1.0, 1.0, 0.25 * (sb - 0.35) * 3.0), 3.5)
		draw_arc(earth_cen, earth_r + 5.0, PI * 1.08, PI * 1.92, 64, Color(0.35, 0.78, 1.0, 0.65), 5.5)
		draw_arc(earth_cen, earth_r + 10.0, PI * 1.12, PI * 1.88, 48, Color(0.2, 0.55, 1.0, 0.25), 3.0)

	if alt < 35.0:
		var ground_alpha = clamp(1.0 - (alt / 20.0), 0.0, 1.0)
		var ground_y = rect.size.y - 75.0 + (alt * 10.0)

		for gi in range(4):
			var gc = Color(0.10 + gi * 0.02, 0.12 + gi * 0.02, 0.16 + gi * 0.01, ground_alpha)
			draw_rect(Rect2(0, ground_y + gi * 18.0, rect.size.x, 20.0), gc)

		draw_line(Vector2(0, ground_y), Vector2(rect.size.x, ground_y),
				 Color(0.4, 0.45, 0.52, ground_alpha * 0.5), 2.0)

		var pad_x = rect.size.x * 0.5
		var table_h = 14.0
		var table_top_y = ground_y - table_h

		draw_rect(Rect2(pad_x - 32.0, table_top_y, 64.0, 26.0), Color(0.08, 0.09, 0.11, ground_alpha))
		draw_rect(Rect2(pad_x - 70.0, table_top_y, 38.0, table_h), Color(0.25, 0.28, 0.33, ground_alpha))
		draw_rect(Rect2(pad_x + 32.0, table_top_y, 38.0, table_h), Color(0.25, 0.28, 0.33, ground_alpha))
		draw_line(Vector2(pad_x - 70.0, table_top_y), Vector2(pad_x + 70.0, table_top_y), Color(0.50, 0.55, 0.62, ground_alpha), 2.5)

		for hi in range(5):
			var hx = pad_x - 68.0 + hi * 12.0
			draw_line(Vector2(hx, table_top_y + 2.0), Vector2(hx + 6.0, table_top_y + table_h - 2.0), Color(0.85, 0.75, 0.15, ground_alpha * 0.8), 2.0)
			var hx2 = pad_x + 34.0 + hi * 12.0
			draw_line(Vector2(hx2, table_top_y + 2.0), Vector2(hx2 + 6.0, table_top_y + table_h - 2.0), Color(0.85, 0.75, 0.15, ground_alpha * 0.8), 2.0)

		var r_id = GameState.rocket_id
		var clamp_offset = 20.0
		if r_id == "falcon_heavy":
			clamp_offset = 42.0
		elif r_id == "vulcan":
			clamp_offset = 26.0

		var clamp_l = PackedVector2Array([
			Vector2(pad_x - clamp_offset - 8.0, table_top_y),
			Vector2(pad_x - clamp_offset + 2.0, table_top_y - 18.0),
			Vector2(pad_x - clamp_offset + 5.0, table_top_y - 18.0),
			Vector2(pad_x - clamp_offset - 3.0, table_top_y)
		])
		draw_polygon(clamp_l, [Color(0.38, 0.42, 0.48, ground_alpha)])
		var clamp_r = PackedVector2Array([
			Vector2(pad_x + clamp_offset + 8.0, table_top_y),
			Vector2(pad_x + clamp_offset - 2.0, table_top_y - 18.0),
			Vector2(pad_x + clamp_offset - 5.0, table_top_y - 18.0),
			Vector2(pad_x + clamp_offset + 3.0, table_top_y)
		])
		draw_polygon(clamp_r, [Color(0.38, 0.42, 0.48, ground_alpha)])

		var gantry_x = pad_x - 92.0
		var gantry_w = 34.0
		var gantry_h = 280.0
		var gantry_y = ground_y - gantry_h

		draw_rect(Rect2(gantry_x, gantry_y, gantry_w, gantry_h), Color(0.24, 0.28, 0.34, ground_alpha))
		draw_rect(Rect2(gantry_x + 1.0, gantry_y, 4.0, gantry_h), Color(0.42, 0.48, 0.56, ground_alpha * 0.4))
		for step in range(11):
			var sy = gantry_y + step * 25.0
			draw_line(Vector2(gantry_x, sy), Vector2(gantry_x + gantry_w, sy + 22.0), Color(0.38, 0.43, 0.50, ground_alpha), 1.5)
			draw_line(Vector2(gantry_x, sy + 22.0), Vector2(gantry_x + gantry_w, sy), Color(0.38, 0.43, 0.50, ground_alpha * 0.7), 1.0)

		for fl in range(4):
			var fl_y = gantry_y + 15.0 + fl * 75.0
			draw_circle(Vector2(gantry_x + gantry_w - 4.0, fl_y), 4.0, Color(1.0, 0.95, 0.5, ground_alpha * 0.9))
			draw_circle(Vector2(gantry_x + gantry_w - 4.0, fl_y), 8.0, Color(1.0, 0.9, 0.3, ground_alpha * 0.3))

		var arm_y = gantry_y + 65.0
		var arm_start = Vector2(gantry_x + gantry_w, arm_y)
		var arm_reach_x = pad_x - 14.0
		var arm_len = arm_reach_x - (gantry_x + gantry_w)
		var arm_rad = deg_to_rad(-arm_angle)
		var arm_end = arm_start + Vector2(cos(arm_rad) * arm_len, sin(arm_rad) * arm_len)
		draw_line(arm_start, arm_end, Color(0.48, 0.54, 0.62, ground_alpha), 5.0)
		draw_line(arm_start, arm_end, Color(0.68, 0.75, 0.84, ground_alpha * 0.6), 2.0)
		var hyd_mid = arm_start.lerp(arm_end, 0.5)
		draw_line(hyd_mid, hyd_mid + Vector2(0, 12.0), Color(0.38, 0.43, 0.50, ground_alpha), 3.0)

		if is_flying and alt < 10.0:
			var steam_intensity = clamp(1.0 - alt / 10.0, 0.0, 1.0)
			for puff in steam_puffs:
				var puff_rise = puff["phase"] + anim_time * puff["speed"]
				var rise_y = -fmod(puff_rise * 30.0, 90.0)
				var puff_alpha = clamp(1.0 - abs(rise_y) / 90.0, 0.0, 1.0) * steam_intensity * 0.5
				var puff_r = puff["base_r"] + abs(rise_y) * 0.6
				var px = pad_x + puff["offset_x"]
				var py = ground_y - 20.0 + rise_y
				for li in range(3):
					draw_circle(Vector2(px, py), puff_r * (1.0 + li * 0.3),
							   Color(0.92, 0.94, 0.97, puff_alpha * (0.4 - li * 0.12)))
