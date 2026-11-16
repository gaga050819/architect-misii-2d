extends Node2D

@export var patch_radius: float = 74.0

func _draw() -> void:
	var center = Vector2.ZERO
	var build = GameState.get_current_build()
	var m_class = build.get("class", {})
	var target = build.get("target", {})
	var instruments = build.get("instruments", [])
	var platform = build.get("platform", {})
	var plat_type = str(platform.get("type", "rover"))
	if GameState.platform_id == "sampler":
		plat_type = "sampler"

	var class_id = str(m_class.get("id", "discovery"))
	var ring_color = Color(0.18, 0.32, 0.54)
	var rim_dark = Color(0.10, 0.18, 0.32)
	var text_color = Color(0.96, 0.95, 0.90)

	if class_id == "flagship":
		ring_color = Color(0.86, 0.68, 0.18)
		rim_dark = Color(0.52, 0.38, 0.08)
		text_color = Color(0.12, 0.09, 0.04)
	elif class_id == "new_frontiers":
		ring_color = Color(0.12, 0.58, 0.48)
		rim_dark = Color(0.06, 0.35, 0.28)
		text_color = Color(0.96, 0.98, 0.95)

	var r_outer = patch_radius + 8.0
	var r_inner = patch_radius - 18.0

	draw_circle(center, r_outer + 2.0, Color(0, 0, 0, 0.35))
	draw_circle(center, r_outer, rim_dark)
	draw_circle(center, r_outer - 1.5, ring_color)

	draw_circle(center, r_inner + 1.5, Color(0.95, 0.94, 0.88, 0.85))
	draw_circle(center, r_inner, Color(0.05, 0.08, 0.16))

	for b in range(4):
		var frac = float(b) / 3.0
		var r_bg = r_inner * (1.0 - frac * 0.28)
		var c_bg = Color(0.05, 0.08, 0.16).lerp(Color(0.14, 0.22, 0.42), frac)
		draw_circle(center, r_bg, c_bg)

	draw_arc(center, r_outer - 2.5, 0, TAU, 64, Color(0.96, 0.94, 0.88, 0.75), 1.5)
	draw_arc(center, r_inner, 0, TAU, 56, Color(0.96, 0.94, 0.88, 0.75), 1.5)

	var target_id = GameState.target_id
	var pr = 25.0
	var planet_center = center + Vector2(16.0, 16.0)

	var earth_center = center + Vector2(-28.0, 12.0)
	var earth_r = 7.0
	draw_circle(earth_center, earth_r, Color(0.22, 0.52, 0.88))
	draw_circle(earth_center + Vector2(-1.5, -1.0), 3.0, Color(0.38, 0.75, 0.45, 0.85))
	draw_circle(earth_center + Vector2(2.0, 1.5), 2.2, Color(0.38, 0.75, 0.45, 0.85))
	draw_arc(earth_center, earth_r + 0.8, 0, TAU, 18, Color(0.55, 0.82, 1.0, 0.55), 1.0)

	draw_transfer_trajectory(earth_center + Vector2(2, -6), planet_center + Vector2(-6, -pr + 4))

	draw_target_body(planet_center, pr, target_id)

	draw_spacecraft_silhouette(planet_center, pr, plat_type, center)

	draw_constellation_stars(center, r_inner, instruments.size())

	var t_name = DataManager.get_localized(target.get("name"), target_id).to_upper()
	var top_text = t_name + " · 2026"
	var bot_text = "АРХІТЕКТОР МІСІЇ"

	draw_curved_text(top_text, patch_radius - 5.0, -PI * 0.5, true, 11, text_color)
	draw_curved_text(bot_text, patch_radius - 6.0, PI * 0.5, false, 9, text_color)

func draw_transfer_trajectory(p_from: Vector2, p_to: Vector2) -> void:
	var ctrl = Vector2((p_from.x + p_to.x) * 0.5 - 12.0, -18.0)
	var steps = 18
	for i in range(steps):
		if i % 2 == 0:
			var t0 = float(i) / float(steps)
			var t1 = float(i + 1) / float(steps)
			var pt0 = p_from.bezier_interpolate(ctrl, ctrl, p_to, t0)
			var pt1 = p_from.bezier_interpolate(ctrl, ctrl, p_to, t1)
			draw_line(pt0, pt1, Color(0.96, 0.94, 0.88, 0.85), 1.4)

func draw_target_body(pos: Vector2, r: float, t_id: String) -> void:
	var base_col = Color(0.82, 0.38, 0.22)
	var limb_col = Color(0.95, 0.58, 0.40, 0.6)

	if t_id == "moon":
		base_col = Color(0.68, 0.70, 0.74)
		limb_col = Color(0.85, 0.88, 0.92, 0.45)
	elif t_id == "venus":
		base_col = Color(0.82, 0.68, 0.34)
		limb_col = Color(0.96, 0.85, 0.45, 0.55)
	elif t_id == "europa":
		base_col = Color(0.65, 0.78, 0.90)
		limb_col = Color(0.82, 0.92, 1.0, 0.65)
	elif t_id == "bennu" or t_id == "asteroid":
		base_col = Color(0.44, 0.43, 0.42)
		limb_col = Color(0.62, 0.60, 0.58, 0.4)

	draw_circle(pos, r, base_col)

	if t_id == "mars":
		draw_circle(pos + Vector2(4, -4), r * 0.65, base_col * Color(0.82, 0.75, 0.70))
		draw_line(pos + Vector2(-r * 0.6, 2.0), pos + Vector2(r * 0.5, -3.0), Color(0.48, 0.18, 0.12, 0.45), 2.5)
		draw_circle(pos + Vector2(0, -r + 2.5), 4.5, Color(0.96, 0.98, 1.0, 0.85))
	elif t_id == "moon":
		draw_circle(pos + Vector2(-5, -4), 4.0, Color(0.50, 0.52, 0.56))
		draw_circle(pos + Vector2(6, 3), 5.5, Color(0.52, 0.54, 0.58))
		draw_circle(pos + Vector2(1, -7), 3.0, Color(0.46, 0.48, 0.52))
	elif t_id == "venus":
		for i in range(3):
			var wy = pos.y - r * 0.4 + i * 7.0
			draw_line(Vector2(pos.x - r * 0.7, wy), Vector2(pos.x + r * 0.7, wy - 2.0), Color(0.95, 0.82, 0.42, 0.4), 2.0)
	elif t_id == "europa":
		draw_line(pos + Vector2(-r * 0.7, -r * 0.3), pos + Vector2(r * 0.6, r * 0.4), Color(0.48, 0.32, 0.25, 0.5), 1.2)
		draw_line(pos + Vector2(-r * 0.4, r * 0.6), pos + Vector2(r * 0.7, -r * 0.2), Color(0.48, 0.32, 0.25, 0.4), 1.2)

	draw_arc(pos, r + 0.5, PI * 1.05, PI * 1.95, 24, limb_col, 1.5)
	draw_circle(pos, r, Color(0, 0, 0, 0.12))

func draw_spacecraft_silhouette(planet_pos: Vector2, planet_r: float, plat_type: String, _center: Vector2) -> void:
	var white_craft = Color(0.96, 0.96, 0.94)

	if plat_type == "orbiter":
		var rx = planet_r + 14.0
		var ry = planet_r * 0.42
		var orbit_poly = PackedVector2Array()
		for i in range(36):
			var a = float(i) / 35.0 * TAU
			var px = cos(a) * rx
			var py = sin(a) * ry
			var rot_p = Vector2(px * 0.95 - py * 0.31, px * 0.31 + py * 0.95)
			orbit_poly.append(planet_pos + rot_p)
		for j in range(35):
			if j % 2 == 0:
				draw_line(orbit_poly[j], orbit_poly[j + 1], Color(1, 1, 1, 0.75), 1.2)

		var sat_pos = planet_pos + Vector2(-rx * 0.92, -ry * 0.8)
		draw_circle(sat_pos, 3.0, white_craft)
		draw_line(sat_pos + Vector2(-6, 0), sat_pos + Vector2(6, 0), white_craft, 2.0)
		draw_line(sat_pos + Vector2(0, -3), sat_pos + Vector2(0, -6), white_craft, 1.0)

	elif plat_type == "rover":
		var rover_pos = planet_pos + Vector2(0, -planet_r - 2.5)
		draw_rect(Rect2(rover_pos + Vector2(-7, -4), Vector2(14, 5)), white_craft)
		draw_circle(rover_pos + Vector2(-5, 3), 2.2, white_craft)
		draw_circle(rover_pos + Vector2(0, 3), 2.2, white_craft)
		draw_circle(rover_pos + Vector2(5, 3), 2.2, white_craft)
		draw_line(rover_pos + Vector2(3, -4), rover_pos + Vector2(4, -9), white_craft, 1.5)
		draw_rect(Rect2(rover_pos + Vector2(2, -11), Vector2(4, 2.5)), white_craft)

	elif plat_type == "lander":
		var lander_pos = planet_pos + Vector2(0, -planet_r - 2.0)
		var poly = PackedVector2Array([
			lander_pos + Vector2(-4, -6),
			lander_pos + Vector2(4, -6),
			lander_pos + Vector2(6, 0),
			lander_pos + Vector2(-6, 0)
		])
		draw_colored_polygon(poly, white_craft)
		draw_line(lander_pos + Vector2(-5, 0), lander_pos + Vector2(-9, 4), white_craft, 1.5)
		draw_line(lander_pos + Vector2(5, 0), lander_pos + Vector2(9, 4), white_craft, 1.5)
		draw_line(lander_pos + Vector2(0, -6), lander_pos + Vector2(0, -11), white_craft, 1.2)

	else:
		var s_pos = planet_pos + Vector2(-12, -planet_r - 6)
		draw_circle(s_pos, 3.5, white_craft)
		draw_line(s_pos + Vector2(-6, 0), s_pos + Vector2(6, 0), white_craft, 1.5)
		draw_line(s_pos, s_pos + Vector2(6, 7), white_craft, 1.2)

func draw_constellation_stars(center: Vector2, inner_r: float, count: int) -> void:
	var star_positions = [
		Vector2(-24, -26), Vector2(-12, -36), Vector2(4, -40),
		Vector2(18, -35), Vector2(-36, -14), Vector2(-4, -20)
	]
	var n = clamp(count + 1, 1, 6)
	for i in range(n):
		var sp = center + star_positions[i]
		if sp.length() < inner_r - 4.0:
			draw_four_point_star(sp, 3.8, Color(0.96, 0.95, 0.90))

func draw_four_point_star(pos: Vector2, size: float, color: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -size),
		pos + Vector2(size * 0.28, -size * 0.28),
		pos + Vector2(size, 0),
		pos + Vector2(size * 0.28, size * 0.28),
		pos + Vector2(0, size),
		pos + Vector2(-size * 0.28, size * 0.28),
		pos + Vector2(-size, 0),
		pos + Vector2(-size * 0.28, -size * 0.28)
	])
	draw_colored_polygon(pts, color)

func draw_curved_text(text_str: String, radius: float, center_angle: float, is_top: bool, font_size: int, color: Color) -> void:
	var font = ThemeDB.fallback_font
	if not font or text_str == "":
		return

	var char_widths: Array = []
	var total_w = 0.0
	for i in range(text_str.length()):
		var ch = text_str.substr(i, 1)
		var cw = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		char_widths.append(cw)
		total_w += cw + 1.2

	var total_ang = total_w / radius
	var cur_w = 0.0

	for i in range(text_str.length()):
		var ch = text_str.substr(i, 1)
		var cw = char_widths[i]
		var mid_w = cur_w + (cw * 0.5)
		cur_w += cw + 1.2
		var frac = mid_w / max(1.0, total_w)

		var ang = 0.0
		var rot = 0.0
		if is_top:
			ang = center_angle - (total_ang * 0.5) + (frac * total_ang)
			rot = ang + (PI * 0.5)
		else:
			ang = center_angle + (total_ang * 0.5) - (frac * total_ang)
			rot = ang - (PI * 0.5)

		var pos = Vector2(cos(ang) * radius, sin(ang) * radius)
		draw_set_transform(pos, rot, Vector2.ONE)
		var y_off = font.get_ascent(font_size) * 0.32
		draw_string(font, Vector2(-cw * 0.5, y_off), ch, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
