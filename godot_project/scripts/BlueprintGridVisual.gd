extends Node2D

@export var width: float = 640.0
@export var height: float = 520.0

var scan_time: float = 0.0

func _process(delta: float) -> void:
	scan_time += delta
	queue_redraw()

func _draw() -> void:
	var is_light = ThemeManager.theme_value > 0.5
	var grid_fine = Color(0.12, 0.55, 0.85, 0.07) if not is_light else Color(0.2, 0.45, 0.7, 0.09)
	var grid_major = Color(0.12, 0.55, 0.85, 0.18) if not is_light else Color(0.2, 0.45, 0.7, 0.22)
	var accent = Color(0.0, 0.85, 1.0, 0.45) if not is_light else Color(0.1, 0.55, 0.9, 0.55)
	var fairing_color = Color(0.4, 0.7, 0.95, 0.4) if not is_light else Color(0.2, 0.45, 0.75, 0.45)
	var dim_accent = Color(accent.r, accent.g, accent.b, accent.a * 0.5)
	var glow_col = Color(accent.r, accent.g, accent.b, 0.08)

	var half_w = width * 0.5
	var half_h = height * 0.5
	var center = Vector2.ZERO

	var cell_fine = 20.0
	var cell_major = 100.0

	var cols_fine = int(width / cell_fine) + 2
	var rows_fine = int(height / cell_fine) + 2
	for c in range(-cols_fine / 2, cols_fine / 2 + 1):
		var x = c * cell_fine
		draw_line(Vector2(x, -half_h), Vector2(x, half_h), grid_fine, 0.5)
	for r in range(-rows_fine / 2, rows_fine / 2 + 1):
		var y = r * cell_fine
		draw_line(Vector2(-half_w, y), Vector2(half_w, y), grid_fine, 0.5)

	var cols_major = int(width / cell_major) + 2
	var rows_major = int(height / cell_major) + 2
	for c in range(-cols_major / 2, cols_major / 2 + 1):
		var x = c * cell_major
		draw_line(Vector2(x, -half_h), Vector2(x, half_h), grid_major, 1.0)
	for r in range(-rows_major / 2, rows_major / 2 + 1):
		var y = r * cell_major
		draw_line(Vector2(-half_w, y), Vector2(half_w, y), grid_major, 1.0)

	for gi in range(5):
		var gr = 60.0 + gi * 55.0
		var ga = 0.18 - gi * 0.03
		draw_arc(center, gr, 0, TAU, 64, Color(accent.r, accent.g, accent.b, ga), 1.0)

	var radial_glow_pts = PackedVector2Array()
	var radial_glow_cols = PackedColorArray()
	for i in range(32):
		var ang = i * (TAU / 31.0)
		radial_glow_pts.append(center + Vector2(cos(ang), sin(ang)) * 90.0)
		radial_glow_cols.append(Color(accent.r, accent.g, accent.b, 0.0))
	radial_glow_pts.append(center)
	radial_glow_cols.append(glow_col * 2.5)

	var scan_y = -half_h + fmod(scan_time * 70.0, height)
	var scan_trail = 55.0
	for sl in range(8):
		var sy = scan_y - sl * (scan_trail / 8.0)
		var sa = (1.0 - float(sl) / 8.0) * 0.22
		draw_line(Vector2(-half_w, sy), Vector2(half_w, sy), Color(accent.r, accent.g, accent.b, sa), 2.0 - sl * 0.2)
	draw_line(Vector2(-half_w, scan_y), Vector2(half_w, scan_y), Color(accent.r, accent.g, accent.b, 0.55), 2.0)

	var rot = scan_time * 0.3
	var arm_len = 8.0
	for i in range(4):
		var ang = rot + i * (PI * 0.5)
		var r_inner = 265.0
		var r_outer = r_inner + arm_len + sin(scan_time * 4.0 + i) * 3.0
		var p1 = center + Vector2(cos(ang), sin(ang)) * r_inner
		var p2 = center + Vector2(cos(ang), sin(ang)) * r_outer
		draw_line(p1, p2, accent, 2.5)
		var p3 = center + Vector2(cos(ang + 0.06), sin(ang + 0.06)) * (r_inner + 4.0)
		var p4 = center + Vector2(cos(ang + 0.06), sin(ang + 0.06)) * (r_inner + arm_len * 0.5)
		draw_line(p3, p4, dim_accent, 1.5)

	draw_line(Vector2(-40, 0), Vector2(40, 0), dim_accent, 0.8)
	draw_line(Vector2(0, -40), Vector2(0, 40), dim_accent, 0.8)
	draw_arc(center, 20.0, 0, TAU, 32, dim_accent, 0.8)
	draw_line(Vector2(-8, 0), Vector2(8, 0), accent, 2.0)
	draw_line(Vector2(0, -8), Vector2(0, 8), accent, 2.0)
	draw_arc(center, 5.0, 0, TAU, 16, accent, 2.0)

	var fairing_w = 190.0
	var fairing_base_y = half_h - 40.0
	var fairing_top_y = -half_h + 30.0
	var fairing_shoulder_y = -half_h + 140.0

	var fairing_left = PackedVector2Array([
		Vector2(0, fairing_top_y),
		Vector2(-fairing_w * 0.5, fairing_shoulder_y),
		Vector2(-fairing_w * 0.5, fairing_base_y),
		Vector2(0, fairing_base_y)
	])
	var fairing_right = PackedVector2Array([
		Vector2(0, fairing_top_y),
		Vector2(fairing_w * 0.5, fairing_shoulder_y),
		Vector2(fairing_w * 0.5, fairing_base_y),
		Vector2(0, fairing_base_y)
	])

	draw_polyline(fairing_left, fairing_color, 1.5)
	draw_polyline(fairing_right, fairing_color, 1.5)

	for seg in range(6):
		var t0 = float(seg) / 6.0
		var t1 = float(seg + 1) / 6.0
		if seg % 2 == 0:
			var seg_pts = PackedVector2Array()
			seg_pts.append(lerp(fairing_left[0], fairing_left[2], t0))
			seg_pts.append(lerp(fairing_left[0], fairing_left[2], t1))
			draw_polyline(seg_pts, Color(fairing_color.r, fairing_color.g, fairing_color.b, fairing_color.a * 1.4), 2.5)
			var seg_pts2 = PackedVector2Array()
			seg_pts2.append(lerp(fairing_right[0], fairing_right[2], t0))
			seg_pts2.append(lerp(fairing_right[0], fairing_right[2], t1))
			draw_polyline(seg_pts2, Color(fairing_color.r, fairing_color.g, fairing_color.b, fairing_color.a * 1.4), 2.5)

	draw_line(Vector2(-fairing_w * 0.5 - 15.0, fairing_base_y), Vector2(fairing_w * 0.5 + 15.0, fairing_base_y), fairing_color, 2.0)

	var dim_col = Color(accent.r, accent.g, accent.b, accent.a * 0.7)
	draw_line(Vector2(-fairing_w * 0.5, fairing_base_y + 18.0), Vector2(fairing_w * 0.5, fairing_base_y + 18.0), dim_col, 1.0)
	draw_line(Vector2(-fairing_w * 0.5, fairing_base_y + 12.0), Vector2(-fairing_w * 0.5, fairing_base_y + 24.0), dim_col, 1.5)
	draw_line(Vector2(fairing_w * 0.5, fairing_base_y + 12.0), Vector2(fairing_w * 0.5, fairing_base_y + 24.0), dim_col, 1.5)
	draw_line(Vector2(0, fairing_base_y + 12.0), Vector2(0, fairing_base_y + 24.0), dim_col, 1.0)

	var corner_tick_len = 16.0
	var corners = [
		[Vector2(-half_w + 20.0, -half_h + 20.0), [Vector2(1,0), Vector2(0,1)]],
		[Vector2(half_w - 20.0, -half_h + 20.0), [Vector2(-1,0), Vector2(0,1)]],
		[Vector2(-half_w + 20.0, half_h - 20.0), [Vector2(1,0), Vector2(0,-1)]],
		[Vector2(half_w - 20.0, half_h - 20.0), [Vector2(-1,0), Vector2(0,-1)]],
	]
	for corner_data in corners:
		var cp = corner_data[0]
		var dirs = corner_data[1]
		draw_line(cp, cp + dirs[0] * corner_tick_len, dim_accent, 1.5)
		draw_line(cp, cp + dirs[1] * corner_tick_len, dim_accent, 1.5)
		draw_circle(cp, 2.0, dim_accent)
